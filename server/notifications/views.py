from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from django.shortcuts import get_object_or_404
from parents.models import Parent
from users.permissions import IsParent
from .models import Notification
from .serializers import NotificationSerializer, MarkAsReadSerializer


class ParentNotificationsView(APIView):
    """
    GET /api/notifications/ - Get all notifications for the logged-in parent

    Query params:
    - is_read: Filter by read status (true/false)
    - type: Filter by notification type
    - limit: Limit number of results (default: 50)
    """
    permission_classes = [IsAuthenticated, IsParent]

    def get(self, request):
        # Get parent object
        try:
            parent = Parent.objects.get(user=request.user)
        except Parent.DoesNotExist:
            return Response(
                {"error": "Parent profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get query parameters
        is_read = request.query_params.get('is_read')
        notification_type = request.query_params.get('type')
        limit = int(request.query_params.get('limit', 50))

        # Build query
        notifications = Notification.objects.filter(parent=parent)

        if is_read is not None:
            is_read_bool = is_read.lower() == 'true'
            notifications = notifications.filter(is_read=is_read_bool)

        if notification_type:
            notifications = notifications.filter(type=notification_type)

        # Limit results
        notifications = notifications[:limit]

        # Serialize
        serializer = NotificationSerializer(notifications, many=True)

        # Get unread count
        unread_count = Notification.objects.filter(parent=parent, is_read=False).count()

        return Response({
            'notifications': serializer.data,
            'unread_count': unread_count,
            'total_count': len(serializer.data)
        })


class MarkNotificationsAsReadView(APIView):
    """
    POST /api/notifications/mark-as-read/

    Body:
    {
        "notification_ids": [1, 2, 3]  // Optional: specific IDs, or omit to mark all as read
    }
    """
    permission_classes = [IsAuthenticated, IsParent]

    def post(self, request):
        # Get parent object
        try:
            parent = Parent.objects.get(user=request.user)
        except Parent.DoesNotExist:
            return Response(
                {"error": "Parent profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = MarkAsReadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        notification_ids = serializer.validated_data.get('notification_ids', [])

        if notification_ids:
            # Mark specific notifications as read
            updated = Notification.objects.filter(
                parent=parent,
                id__in=notification_ids,
                is_read=False
            ).update(is_read=True)
        else:
            # Mark all unread notifications as read
            updated = Notification.objects.filter(
                parent=parent,
                is_read=False
            ).update(is_read=True)

        return Response({
            'message': f'{updated} notification(s) marked as read',
            'updated_count': updated
        })


class NotificationDetailView(APIView):
    """
    GET /api/notifications/{id}/ - Get specific notification
    DELETE /api/notifications/{id}/ - Delete specific notification
    """
    permission_classes = [IsAuthenticated, IsParent]

    def get(self, request, notification_id):
        # Get parent object
        try:
            parent = Parent.objects.get(user=request.user)
        except Parent.DoesNotExist:
            return Response(
                {"error": "Parent profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get notification
        notification = get_object_or_404(Notification, id=notification_id, parent=parent)

        # Mark as read when viewed
        if not notification.is_read:
            notification.mark_as_read()

        serializer = NotificationSerializer(notification)
        return Response(serializer.data)

    def delete(self, request, notification_id):
        # Get parent object
        try:
            parent = Parent.objects.get(user=request.user)
        except Parent.DoesNotExist:
            return Response(
                {"error": "Parent profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get and delete notification
        notification = get_object_or_404(Notification, id=notification_id, parent=parent)
        notification.delete()

        return Response(
            {"message": "Notification deleted successfully"},
            status=status.HTTP_204_NO_CONTENT
        )


# Helper function to create notifications (used by other apps)
def create_notification(parent, notification_type, title, message, related_object=None):
    """
    Helper function to create a notification for a parent.

    Args:
        parent: Parent object
        notification_type: str (one of Notification.NOTIFICATION_TYPES)
        title: str
        message: str
        related_object: optional Django model instance to link

    Returns:
        Notification object
    """
    from django.contrib.contenttypes.models import ContentType

    notification_data = {
        'parent': parent,
        'type': notification_type,
        'title': title,
        'message': message,
    }

    if related_object:
        notification_data['content_type'] = ContentType.objects.get_for_model(related_object)
        notification_data['object_id'] = related_object.id

    return Notification.objects.create(**notification_data)
