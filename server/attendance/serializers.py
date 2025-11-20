from rest_framework import serializers
from .models import Attendance


class AttendanceSerializer(serializers.ModelSerializer):
    """Full attendance serializer with all details"""
    child_name = serializers.SerializerMethodField()
    child_grade = serializers.CharField(source='child.class_grade', read_only=True)
    parent_name = serializers.SerializerMethodField()
    bus_number = serializers.CharField(source='bus.bus_number', read_only=True, allow_null=True)
    marked_by_name = serializers.SerializerMethodField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Attendance
        fields = [
            'id',
            'child',
            'child_name',
            'child_grade',
            'parent_name',
            'bus',
            'bus_number',
            'status',
            'status_display',
            'trip_type',
            'date',
            'marked_by',
            'marked_by_name',
            'timestamp',
            'notes',
        ]
        read_only_fields = ['id', 'date', 'timestamp']

    def get_child_name(self, obj):
        return f"{obj.child.first_name} {obj.child.last_name}"

    def get_parent_name(self, obj):
        if obj.child.parent and obj.child.parent.user:
            return obj.child.parent.user.get_full_name()
        return None

    def get_marked_by_name(self, obj):
        if obj.marked_by:
            return obj.marked_by.get_full_name()
        return None


class AttendanceListSerializer(serializers.ModelSerializer):
    """Lightweight attendance serializer for list views"""
    child_name = serializers.SerializerMethodField()
    child_grade = serializers.CharField(source='child.class_grade', read_only=True)
    bus_number = serializers.CharField(source='bus.bus_number', read_only=True, allow_null=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Attendance
        fields = [
            'id',
            'child',
            'child_name',
            'child_grade',
            'bus_number',
            'status',
            'status_display',
            'trip_type',
            'timestamp',
        ]

    def get_child_name(self, obj):
        return f"{obj.child.first_name} {obj.child.last_name}"
