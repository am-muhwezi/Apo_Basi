from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from .utils import (
    send_trip_started_notification,
    send_trip_completed_notification,
    send_child_pickup_notification,
    send_child_dropoff_notification,
    send_child_absent_notification,
    send_child_missed_trip_notification,
    notify_parents_of_children,
)


@receiver(pre_save, sender='trips.Trip')
def trip_pre_save(sender, instance, **kwargs):
    """Capture previous trip status so we can detect transitions in post_save."""
    if instance.pk:
        try:
            previous = sender.objects.get(pk=instance.pk)
            instance._previous_status = previous.status
        except sender.DoesNotExist:
            instance._previous_status = None
    else:
        instance._previous_status = None


@receiver(post_save, sender='trips.Trip')
def trip_status_changed(sender, instance, created, **kwargs):
    """Send notifications when trips start or complete.

    - Trip started: status changes into 'in-progress'.
    - Trip completed: status changes into 'completed'.
    """
    trip = instance
    previous_status = getattr(trip, '_previous_status', None)
    current_status = trip.status

    # Collect children related to this trip or assigned to the trip's bus.
    from children.models import Child
    from assignments.models import Assignment
    from django.contrib.contenttypes.models import ContentType

    try:
        bus_content_type = ContentType.objects.get_for_model(trip.bus)
        child_content_type = ContentType.objects.get(app_label='children', model='child')

        # Children explicitly added to the trip
        trip_children_qs = trip.children.filter(parent__isnull=False)

        # Children assigned via Assignment records to this bus
        child_assignments = Assignment.objects.filter(
            assigned_to_content_type=bus_content_type,
            assigned_to_object_id=trip.bus.id,
            assignee_content_type=child_content_type,
            status='active'
        )
        assignment_child_ids = [assignment.assignee_object_id for assignment in child_assignments]

        # Children with legacy FK assigned_bus
        fk_children_qs = Child.objects.filter(assigned_bus=trip.bus, parent__isnull=False).values_list('id', flat=True)

        # Union of IDs from trip children, assignment children, and FK children
        ids = set(trip_children_qs.values_list('id', flat=True))
        ids.update(assignment_child_ids)
        ids.update(list(fk_children_qs))

        children = Child.objects.filter(id__in=list(ids), parent__isnull=False)

        # Trip started by driver (pickup or dropoff): notify all parents on this bus.
        # Busminder-started trips are operational; only driver-started trips
        # represent the parent-visible "bus is on the move" event.
        if current_status == 'in-progress' and previous_status != 'in-progress':
            if not trip.bus_minder:
                print(f"🚀 {trip.trip_type.title()} trip started - sending notifications to {len(children)} parents")
                for child in children:
                    if child.parent and hasattr(child.parent, 'user'):
                        send_trip_started_notification(child.parent.user_id, trip, trip.bus, child=child)
                        print(f"  ✅ Sent to parent of {child.first_name} (parent ID: {child.parent.user_id})")

        # Pickup trip completed (driver only): only children who were actually picked up
        # have reached school — skip absent/pending children.
        elif current_status == 'completed' and previous_status != 'completed':
            if trip.trip_type == 'pickup' and not trip.bus_minder:
                from attendance.models import Attendance
                trip_date = (trip.end_time or trip.start_time).date()
                picked_up_ids = set(
                    Attendance.objects.filter(
                        bus=trip.bus,
                        trip_type='pickup',
                        date=trip_date,
                        status='picked_up'
                    ).values_list('child_id', flat=True)
                )
                absent_ids = set(
                    Attendance.objects.filter(
                        bus=trip.bus,
                        trip_type='pickup',
                        date=trip_date,
                        status='absent'
                    ).values_list('child_id', flat=True)
                )
                print(f"🏁 Pickup trip completed - notifying {len(picked_up_ids)} picked-up, {len(absent_ids)} absent")
                for child in children:
                    if not child.parent or not hasattr(child.parent, 'user'):
                        continue
                    if child.id in picked_up_ids:
                        send_trip_completed_notification(child.parent.user_id, trip, trip.bus, child=child)
                        print(f"  ✅ Reached school: {child.first_name} (parent {child.parent.user_id})")
                    elif child.id in absent_ids:
                        send_child_missed_trip_notification(child.parent.user_id, child, trip.bus, trip)
                        print(f"  ⚠️ Absent reminder: {child.first_name} (parent {child.parent.user_id})")

    except Exception as e:
        print(f"Error in trip_status_changed signal: {e}")


@receiver(pre_save, sender='attendance.Attendance')
def attendance_pre_save(sender, instance, **kwargs):
    """Capture the previous status so we can detect status changes in post_save.

    This lets us fire notifications not only when a new attendance record is
    created, but also when an existing record moves from pending/absent to
    picked_up or dropped_off.
    """
    if instance.pk:
        try:
            previous = sender.objects.get(pk=instance.pk)
            instance._previous_status = previous.status
        except sender.DoesNotExist:
            instance._previous_status = None
    else:
        instance._previous_status = None


@receiver(post_save, sender='attendance.Attendance')
def attendance_marked(sender, instance, created, **kwargs):
    """Send notifications when children are picked up or dropped off.

    Triggers when a new attendance record is created with a final status,
    or when an existing record's status changes into picked_up/dropped_off.
    """
    attendance = instance

    try:
        child = attendance.child
        bus = attendance.bus  # Attendance has a direct bus reference

        if not child.parent or not bus:
            return

        # Determine if we should notify:
        # - New record with picked_up/dropped_off
        # - Existing record whose status has changed into picked_up/dropped_off
        previous_status = getattr(attendance, '_previous_status', None)
        new_status = attendance.status

        if new_status not in ['picked_up', 'dropped_off', 'absent']:
            return

        # Deduplicate: skip if status hasn't actually changed and child state is already correct.
        if not created and previous_status == new_status:
            if new_status == 'picked_up' and child.location_status == 'on-bus':
                return
            if new_status == 'dropped_off' and child.location_status == 'home':
                return
            if new_status == 'absent':
                return  # Already notified for this absence

        parent_id = child.parent.user_id  # Parent uses user as primary key

        # Update the child's high-level location/tracking status.
        # Mapping rules:
        # - pickup trip + picked_up   -> on-bus (on the way to school)
        # - pickup trip + dropped_off -> at-school
        # - dropoff trip + picked_up  -> on-bus (on the way home)
        # - dropoff trip + dropped_off -> home
        # - absent (either trip)      -> home (child was not transported)
        try:
            trip_type = attendance.trip_type

            if new_status == 'picked_up':
                child.location_status = 'on-bus'
            elif new_status == 'dropped_off':
                child.location_status = 'at-school' if trip_type == 'pickup' else 'home'
            else:  # absent — child stayed home
                child.location_status = 'home'

            child.save(update_fields=['location_status'])
        except Exception as e:
            print(f"Error updating child.location_status from attendance_marked: {e}")

        if new_status == 'picked_up':
            send_child_pickup_notification(parent_id, child, bus, attendance)
            print(f"✅ Sent pickup notification for {child.first_name} to parent {parent_id}")
        elif new_status == 'dropped_off':
            send_child_dropoff_notification(parent_id, child, bus, attendance)
            print(f"✅ Sent dropoff notification for {child.first_name} to parent {parent_id}")
        else:  # absent
            send_child_absent_notification(parent_id, child, bus)
            print(f"⚠️ Sent absent notification for {child.first_name} to parent {parent_id}")

    except Exception as e:
        print(f"Error in attendance_marked signal: {e}")


@receiver(post_save, sender='assignments.Assignment')
def assignment_changed(sender, instance, created, **kwargs):
    """
    Signal handler for assignment changes.
    Can be used to notify parents when their child's bus or route changes.
    """
    from .utils import send_route_change_notification
    from django.contrib.contenttypes.models import ContentType

    assignment = instance

    try:
        # Check if this is a child-to-bus assignment
        child_content_type = ContentType.objects.get(app_label='children', model='child')
        bus_content_type = ContentType.objects.get(app_label='buses', model='bus')

        if (assignment.assignee_content_type == child_content_type and
            assignment.assigned_to_content_type == bus_content_type and
            not created and assignment.status == 'active'):

            from children.models import Child
            from buses.models import Bus

            child = Child.objects.get(id=assignment.assignee_object_id)
            bus = Bus.objects.get(id=assignment.assigned_to_object_id)

            if child.parent:
                change_details = f"{child.first_name} has been assigned to a new bus."
                send_route_change_notification(
                    child.parent.user_id,
                    bus,
                    change_details
                )
                print(f"✅ Sent route change notification to parent {child.parent.user_id}")

    except Exception as e:
        print(f"Error in assignment_changed signal: {e}")
