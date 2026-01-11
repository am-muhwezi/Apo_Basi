from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.utils import timezone
from .models import Notification
from .serializers import NotificationSerializer


class ParentNotificationListView(generics.ListAPIView):
    """
    GET /api/notifications/ - List all notifications for authenticated parent
    Query params:
    - is_read: Filter by read status (true/false)
    - limit: Number of results (default: 20)
    """
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        user = self.request.user
        
        # Verify user is a parent
        if user.user_type != 'parent':
            return Notification.objects.none()
        
        # Get parent's notifications
        from parents.models import Parent
        try:
            parent = Parent.objects.get(user=user)
        except Parent.DoesNotExist:
            return Notification.objects.none()
        
        queryset = Notification.objects.filter(parent=parent)
        
        # Filter by read status
        is_read = self.request.query_params.get('is_read')
        if is_read is not None:
            is_read_bool = is_read.lower() == 'true'
            queryset = queryset.filter(is_read=is_read_bool)
        
        # Limit results
        limit = self.request.query_params.get('limit', 20)
        try:
            limit = int(limit)
            queryset = queryset[:limit]
        except ValueError:
            pass
        
        return queryset


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, notification_id):
    """
    POST /api/notifications/<id>/mark-read/ - Mark notification as read
    """
    user = request.user
    
    if user.user_type != 'parent':
        return Response(
            {"error": "Only parents can mark notifications as read"},
            status=status.HTTP_403_FORBIDDEN
        )
    
    from parents.models import Parent
    try:
        parent = Parent.objects.get(user=user)
    except Parent.DoesNotExist:
        return Response(
            {"error": "Parent record not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    
    try:
        notification = Notification.objects.get(id=notification_id, parent=parent)
        notification.is_read = True
        notification.read_at = timezone.now()
        notification.save()
        
        serializer = NotificationSerializer(notification)
        return Response(serializer.data)
    
    except Notification.DoesNotExist:
        return Response(
            {"error": "Notification not found"},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_all_notifications_read(request):
    """
    POST /api/notifications/mark-all-read/ - Mark all notifications as read
    """
    user = request.user
    
    if user.user_type != 'parent':
        return Response(
            {"error": "Only parents can mark notifications as read"},
            status=status.HTTP_403_FORBIDDEN
        )
    
    from parents.models import Parent
    try:
        parent = Parent.objects.get(user=user)
    except Parent.DoesNotExist:
        return Response(
            {"error": "Parent record not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Update all unread notifications
    updated_count = Notification.objects.filter(
        parent=parent,
        is_read=False
    ).update(
        is_read=True,
        read_at=timezone.now()
    )
    
    return Response({
        "message": f"{updated_count} notifications marked as read",
        "count": updated_count
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_unread_count(request):
    """
    GET /api/notifications/unread-count/ - Get count of unread notifications
    """
    user = request.user
    
    if user.user_type != 'parent':
        return Response({"count": 0})
    
    from parents.models import Parent
    try:
        parent = Parent.objects.get(user=user)
        count = Notification.objects.filter(parent=parent, is_read=False).count()
        return Response({"count": count})
    except Parent.DoesNotExist:
        return Response({"count": 0})
