from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from .utils import (
    send_trip_started_notification,
    send_trip_completed_notification,
    send_child_pickup_notification,
    send_child_dropoff_notification,
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

    # Get all children assigned to this trip's bus
    from children.models import Child
    from assignments.models import Assignment
    from django.contrib.contenttypes.models import ContentType

    try:
        bus_content_type = ContentType.objects.get_for_model(trip.bus)
        child_content_type = ContentType.objects.get(app_label='children', model='child')

        # Get children assigned to this bus
        child_assignments = Assignment.objects.filter(
            assigned_to_content_type=bus_content_type,
            assigned_to_object_id=trip.bus.id,
            assignee_content_type=child_content_type,
            status='active'
        )

        child_ids = [assignment.assignee_object_id for assignment in child_assignments]
        children = Child.objects.filter(id__in=child_ids, parent__isnull=False)

        # Trip started: transition into 'in-progress'
        if current_status == 'in-progress' and previous_status != 'in-progress':
            print(f"🚀 Trip started - sending notifications to {len(children)} parents")
            for child in children:
                if child.parent and hasattr(child.parent, 'user'):
                    send_trip_started_notification(child.parent.user_id, trip, trip.bus, child=child)
                    print(f"  ✅ Sent to parent of {child.first_name} (parent ID: {child.parent.user_id})")

        # Trip completed: transition into 'completed'
        elif current_status == 'completed' and previous_status != 'completed':
            print(f"🏁 Trip completed - sending notifications to {len(children)} parents")
            for child in children:
                if child.parent and hasattr(child.parent, 'user'):
                    send_trip_completed_notification(child.parent.user_id, trip, trip.bus, child=child)
                    print(f"  ✅ Sent to parent of {child.first_name} (parent ID: {child.parent.user_id})")

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

        if new_status not in ['picked_up', 'dropped_off']:
            return

        if not created and previous_status == new_status:
            # No actual status change, nothing to notify or update.
            return

        parent_id = child.parent.user_id  # Parent uses user as primary key

        # Update the child's high-level location/tracking status so that
        # the Parents app dashboard can show clear states like
        # "On bus", "At school", and "At home".
        #
        # Mapping rules:
        # - pickup trip + picked_up   -> on-bus (on the way to school)
        # - pickup trip + dropped_off -> at-school
        # - dropoff trip + picked_up  -> on-bus (on the way home)
        # - dropoff trip + dropped_off -> home
        try:
            trip_type = attendance.trip_type

            if new_status == 'picked_up':
                # Child has boarded the bus (either to school or back home)
                child.location_status = 'on-bus'
            else:  # dropped_off
                if trip_type == 'pickup':
                    # Morning trip completed for this child -> now at school
                    child.location_status = 'at-school'
                else:
                    # Dropoff trip completed for this child -> now at home
                    child.location_status = 'home'

            child.save(update_fields=['location_status'])
        except Exception as e:
            print(f"Error updating child.location_status from attendance_marked: {e}")

        if new_status == 'picked_up':
            send_child_pickup_notification(parent_id, child, bus, attendance)
            print(f"✅ Sent pickup notification for {child.first_name} to parent {parent_id}")
        else:  # dropped_off
            send_child_dropoff_notification(parent_id, child, bus, attendance)
            print(f"✅ Sent dropoff notification for {child.first_name} to parent {parent_id}")

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
