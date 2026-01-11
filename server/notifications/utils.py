import uuid
from datetime import datetime
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync


def save_notification_to_db(parent_id, notification_type, title, message, full_message=None, child=None, bus=None, trip=None, additional_data=None):
    """
    Save notification to database for persistence.
    """
    from .models import Notification
    from parents.models import Parent
    
    try:
        parent = Parent.objects.get(user_id=parent_id)
        notification = Notification.objects.create(
            parent=parent,
            notification_type=notification_type,
            title=title,
            message=message,
            full_message=full_message or message,
            child=child,
            bus=bus,
            trip=trip,
            additional_data=additional_data or {}
        )
        return notification
    except Parent.DoesNotExist:
        print(f"⚠️ Parent with ID {parent_id} not found, notification not saved")
        return None
    except Exception as e:
        print(f"❌ Error saving notification: {e}")
        return None


def send_notification_to_parent(parent_id, notification_type, data):
    """
    Send a notification to a specific parent via WebSocket.

    Args:
        parent_id: The parent's database ID
        notification_type: Type of notification (trip_notification, attendance_notification, etc.)
        data: Dictionary containing notification data
    """
    channel_layer = get_channel_layer()
    group_name = f"parent_notifications_{parent_id}"

    # Add unique ID and timestamp if not present
    if 'id' not in data:
        data['id'] = str(uuid.uuid4())
    if 'timestamp' not in data:
        data['timestamp'] = datetime.now().isoformat()

    async_to_sync(channel_layer.group_send)(
        group_name,
        {
            'type': notification_type,
            **data
        }
    )


def send_trip_started_notification(parent_id, trip, bus):
    """Send trip started notification to parent."""
    # Save to database
    save_notification_to_db(
        parent_id=parent_id,
        notification_type='trip_started',
        title=f'Bus {bus.bus_number} Started Trip',
        message=f'The {trip.trip_type} trip has started',
        full_message=f'Bus {bus.bus_number} has started the {trip.trip_type} trip. You can track its location in real-time.',
        bus=bus,
        trip=trip,
        additional_data={'trip_type': trip.trip_type}
    )
    
    # Send real-time notification
    send_notification_to_parent(
        parent_id=parent_id,
        notification_type='trip_notification',
        data={
            'notification_type': 'trip_started',
            'title': f'Bus {bus.bus_number} Started Trip',
            'message': f'The {trip.trip_type} trip has started',
            'full_message': f'Bus {bus.bus_number} has started the {trip.trip_type} trip. You can track its location in real-time.',
            'trip_id': trip.id,
            'bus_id': bus.id,
            'bus_number': bus.bus_number,
            'trip_type': trip.trip_type,
        }
    )


def send_trip_completed_notification(parent_id, trip, bus):
    """Send trip completed notification to parent."""
    # Save to database
    save_notification_to_db(
        parent_id=parent_id,
        notification_type='trip_completed',
        title=f'Bus {bus.bus_number} Trip Completed',
        message=f'The {trip.trip_type} trip has been completed',
        full_message=f'Bus {bus.bus_number} has successfully completed the {trip.trip_type} trip.',
        bus=bus,
        trip=trip,
        additional_data={'trip_type': trip.trip_type}
    )
    
    # Send real-time notification
    send_notification_to_parent(
        parent_id=parent_id,
        notification_type='trip_notification',
        data={
            'notification_type': 'trip_ended',
            'title': f'Bus {bus.bus_number} Trip Completed',
            'message': f'The {trip.trip_type} trip has been completed',
            'full_message': f'Bus {bus.bus_number} has successfully completed the {trip.trip_type} trip.',
            'trip_id': trip.id,
            'bus_id': bus.id,
            'bus_number': bus.bus_number,
            'trip_type': trip.trip_type,
        }
    )


def send_child_pickup_notification(parent_id, child, bus, attendance):
    """Send child pickup notification to parent."""
    # Save to database
    save_notification_to_db(
        parent_id=parent_id,
        notification_type='child_picked_up',
        title=f'{child.first_name} Picked Up',
        message=f'{child.first_name} has been picked up by Bus {bus.bus_number}',
        full_message=f'{child.first_name} {child.last_name} was picked up at {attendance.timestamp.strftime("%I:%M %p")}.',
        child=child,
        bus=bus,
        additional_data={
            'status': 'picked_up',
            'location': {
                'latitude': float(attendance.latitude) if hasattr(attendance, 'latitude') and attendance.latitude else None,
                'longitude': float(attendance.longitude) if hasattr(attendance, 'longitude') and attendance.longitude else None,
            }
        }
    )
    
    # Send real-time notification
    send_notification_to_parent(
        parent_id=parent_id,
        notification_type='attendance_notification',
        data={
            'notification_type': 'pickup_confirmed',
            'title': f'{child.first_name} Picked Up',
            'message': f'{child.first_name} has been picked up by Bus {bus.bus_number}',
            'full_message': f'{child.first_name} {child.last_name} was picked up at {attendance.timestamp.strftime("%I:%M %p")}.',
            'child_id': child.id,
            'child_name': f'{child.first_name} {child.last_name}',
            'bus_id': bus.id,
            'bus_number': bus.bus_number,
            'status': 'picked_up',
            'location': {
                'latitude': float(attendance.latitude) if hasattr(attendance, 'latitude') and attendance.latitude else None,
                'longitude': float(attendance.longitude) if hasattr(attendance, 'longitude') and attendance.longitude else None,
            },
        }
    )


def send_child_dropoff_notification(parent_id, child, bus, attendance):
    """Send child dropoff notification to parent."""
    # Save to database
    save_notification_to_db(
        parent_id=parent_id,
        notification_type='child_dropped_off',
        title=f'{child.first_name} Dropped Off',
        message=f'{child.first_name} has been dropped off by Bus {bus.bus_number}',
        full_message=f'{child.first_name} {child.last_name} was dropped off at {attendance.timestamp.strftime("%I:%M %p")}.',
        child=child,
        bus=bus,
        additional_data={
            'status': 'dropped_off',
            'location': {
                'latitude': float(attendance.latitude) if hasattr(attendance, 'latitude') and attendance.latitude else None,
                'longitude': float(attendance.longitude) if hasattr(attendance, 'longitude') and attendance.longitude else None,
            }
        }
    )
    
    # Send real-time notification
    send_notification_to_parent(
        parent_id=parent_id,
        notification_type='attendance_notification',
        data={
            'notification_type': 'dropoff_complete',
            'title': f'{child.first_name} Dropped Off',
            'message': f'{child.first_name} has been dropped off by Bus {bus.bus_number}',
            'full_message': f'{child.first_name} {child.last_name} was dropped off at {attendance.timestamp.strftime("%I:%M %p")}.',
            'child_id': child.id,
            'child_name': f'{child.first_name} {child.last_name}',
            'bus_id': bus.id,
            'bus_number': bus.bus_number,
            'status': 'dropped_off',
            'location': {
                'latitude': float(attendance.latitude) if hasattr(attendance, 'latitude') and attendance.latitude else None,
                'longitude': float(attendance.longitude) if hasattr(attendance, 'longitude') and attendance.longitude else None,
            },
        }
    )


def send_route_change_notification(parent_id, bus, change_details):
    """Send route change notification to parent."""
    send_notification_to_parent(
        parent_id=parent_id,
        notification_type='route_change_notification',
        data={
            'notification_type': 'route_change',
            'title': 'Route Change Alert',
            'message': f'Bus {bus.bus_number} route has been updated',
            'full_message': f'The route for Bus {bus.bus_number} has been modified. {change_details}',
            'bus_id': bus.id,
            'bus_number': bus.bus_number,
            'change_details': change_details,
        }
    )


def send_emergency_notification(parent_id, bus, message, severity='high'):
    """Send emergency notification to parent."""
    send_notification_to_parent(
        parent_id=parent_id,
        notification_type='emergency_notification',
        data={
            'notification_type': 'emergency',
            'title': 'Emergency Alert',
            'message': message,
            'full_message': f'Emergency alert for Bus {bus.bus_number}: {message}',
            'bus_id': bus.id,
            'bus_number': bus.bus_number,
            'severity': severity,
            'action_required': True if severity in ['high', 'critical'] else False,
        }
    )


def send_delay_notification(parent_id, bus, delay_minutes, reason, estimated_arrival=None):
    """Send delay notification to parent."""
    send_notification_to_parent(
        parent_id=parent_id,
        notification_type='delay_notification',
        data={
            'notification_type': 'major_delay',
            'title': f'Bus {bus.bus_number} Delayed',
            'message': f'{delay_minutes} minute delay on Bus {bus.bus_number}',
            'full_message': f'Bus {bus.bus_number} is experiencing a {delay_minutes} minute delay. Reason: {reason}',
            'bus_id': bus.id,
            'bus_number': bus.bus_number,
            'delay_minutes': delay_minutes,
            'reason': reason,
            'estimated_arrival': estimated_arrival,
        }
    )


def send_proximity_notification(parent_id, bus, distance_km, estimated_arrival_minutes):
    """Send bus proximity notification to parent."""
    send_notification_to_parent(
        parent_id=parent_id,
        notification_type='proximity_notification',
        data={
            'notification_type': 'bus_approaching',
            'title': f'Bus {bus.bus_number} Approaching',
            'message': f'Bus is {distance_km:.1f} km away, arriving in ~{estimated_arrival_minutes} minutes',
            'full_message': f'Bus {bus.bus_number} is approximately {distance_km:.1f} km away from your location and should arrive in about {estimated_arrival_minutes} minutes.',
            'bus_id': bus.id,
            'bus_number': bus.bus_number,
            'distance_km': distance_km,
            'estimated_arrival_minutes': estimated_arrival_minutes,
        }
    )


def notify_parents_of_children(children_queryset, notification_func, *args, **kwargs):
    """
    Helper function to notify parents of multiple children.

    Args:
        children_queryset: QuerySet of Child objects
        notification_func: The notification function to call
        *args, **kwargs: Arguments to pass to the notification function
    """
    for child in children_queryset:
        if child.parent:
            notification_func(child.parent.id, *args, **kwargs)
