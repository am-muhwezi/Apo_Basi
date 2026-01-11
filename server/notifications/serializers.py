from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    child_name = serializers.SerializerMethodField()
    bus_number = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = [
            'id',
            'notification_type',
            'title',
            'message',
            'full_message',
            'child_name',
            'bus_number',
            'additional_data',
            'is_read',
            'created_at',
            'read_at',
        ]
        read_only_fields = ['id', 'created_at']

    def get_child_name(self, obj):
        if obj.child:
            return f"{obj.child.first_name} {obj.child.last_name}"
        return None

    def get_bus_number(self, obj):
        if obj.bus:
            return obj.bus.bus_number
        return None
