from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for Notification model"""

    type_display = serializers.CharField(source='get_type_display', read_only=True)
    parent_id = serializers.IntegerField(source='parent.user_id', read_only=True)
    parent_name = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = [
            'id',
            'parent_id',
            'parent_name',
            'type',
            'type_display',
            'title',
            'message',
            'is_read',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']

    def get_parent_name(self, obj):
        return obj.parent.user.get_full_name() if obj.parent and obj.parent.user else "Unknown"


class NotificationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating notifications"""

    class Meta:
        model = Notification
        fields = [
            'parent',
            'type',
            'title',
            'message',
        ]

    def validate_type(self, value):
        """Ensure valid notification type"""
        valid_types = [choice[0] for choice in Notification.NOTIFICATION_TYPES]
        if value not in valid_types:
            raise serializers.ValidationError(f"Invalid notification type. Must be one of: {', '.join(valid_types)}")
        return value


class MarkAsReadSerializer(serializers.Serializer):
    """Serializer for marking notifications as read"""
    notification_ids = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        help_text="List of notification IDs to mark as read. If empty, marks all as read."
    )
