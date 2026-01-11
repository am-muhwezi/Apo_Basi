from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from .utils import (
    send_trip_started_notification,
    send_trip_completed_notification,
    send_child_pickup_notification,
    send_child_dropoff_notification,
    notify_parents_of_children,
)


@receiver(post_save, sender='trips.Trip')
def trip_status_changed(sender, instance, created, **kwargs):
    """
    Signal handler for trip status changes.
    Sends notifications when trips start or complete.
    """
    trip = instance

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

        # Send notifications based on trip status
        if trip.status == 'in_progress':
            # Trip started (either newly created or status changed to in_progress)
            # Send notification only when trip is first starting
            if created:
                # Trip just created with 'in_progress' status (driver started trip)
                print(f"🚀 Trip started by driver - sending notifications to {len(children)} parents")
                for child in children:
                    if child.parent and hasattr(child.parent, 'user'):
                        send_trip_started_notification(child.parent.user_id, trip, trip.bus)
                        print(f"  ✅ Sent to parent of {child.first_name} (parent ID: {child.parent.user_id})")
            # If not created, it means status was updated - we can ignore this
            # because trips are created with 'in_progress' status directly

        elif trip.status == 'completed':
            # Trip completed
            print(f"🏁 Trip completed - sending notifications to {len(children)} parents")
            for child in children:
                if child.parent and hasattr(child.parent, 'user'):
                    send_trip_completed_notification(child.parent.user_id, trip, trip.bus)
                    print(f"  ✅ Sent to parent of {child.first_name} (parent ID: {child.parent.user_id})")

    except Exception as e:
        print(f"Error in trip_status_changed signal: {e}")


@receiver(post_save, sender='attendance.Attendance')
def attendance_marked(sender, instance, created, **kwargs):
    """
    Signal handler for attendance marking.
    Sends notifications when children are picked up or dropped off.
    """
    if not created:
        return  # Only process new attendance records

    attendance = instance

    try:
        child = attendance.child
        bus = attendance.bus  # Attendance has a direct bus reference

        if not child.parent or not bus:
            return

        parent_id = child.parent.user_id  # Parent uses user as primary key

        # Send appropriate notification based on status
        if attendance.status == 'picked_up':
            send_child_pickup_notification(parent_id, child, bus, attendance)
            print(f"✅ Sent pickup notification for {child.first_name} to parent {parent_id}")

        elif attendance.status == 'dropped_off':
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
