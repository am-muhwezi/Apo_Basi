from rest_framework import serializers
from .models import Bus
from django.contrib.auth import get_user_model

User = get_user_model()


class BusSerializer(serializers.ModelSerializer):
    """Full bus serializer - uses camelCase for frontend consistency"""
    busNumber = serializers.CharField(source='bus_number')
    licensePlate = serializers.CharField(source='number_plate')
    driverId = serializers.IntegerField(source='driver.id', read_only=True, allow_null=True)
    driverName = serializers.SerializerMethodField()
    minderId = serializers.IntegerField(source='bus_minder.id', read_only=True, allow_null=True)
    minderName = serializers.SerializerMethodField()
    assignedChildrenCount = serializers.SerializerMethodField()
    assignedChildrenIds = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()
    lastMaintenance = serializers.DateField(source='last_maintenance', allow_null=True)
    currentLocation = serializers.CharField(source='current_location', allow_blank=True)
    isActive = serializers.BooleanField(source='is_active')
    lastUpdated = serializers.DateTimeField(source='last_updated', read_only=True)

    class Meta:
        model = Bus
        fields = [
            'id', 'busNumber', 'licensePlate', 'capacity', 'model', 'year',
            'isActive', 'status', 'lastMaintenance', 'currentLocation',
            'driverId', 'driverName', 'minderId', 'minderName',
            'assignedChildrenCount', 'assignedChildrenIds',
            'latitude', 'longitude', 'lastUpdated'
        ]

    def get_driverName(self, obj):
        return f"{obj.driver.first_name} {obj.driver.last_name}" if obj.driver else None

    def get_minderName(self, obj):
        return f"{obj.bus_minder.first_name} {obj.bus_minder.last_name}" if obj.bus_minder else None

    def get_assignedChildrenCount(self, obj):
        return obj.children.count() if hasattr(obj, 'children') else 0

    def get_assignedChildrenIds(self, obj):
        """Return list of child IDs assigned to this bus"""
        if hasattr(obj, 'children'):
            return list(obj.children.values_list('id', flat=True))
        return []

    def get_status(self, obj):
        """Convert is_active boolean to status string for frontend"""
        if obj.is_active:
            return 'active'
        # You can add more logic here based on other fields
        # For now, return 'inactive' for non-active buses
        return 'inactive'


class BusCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating buses - uses camelCase"""
    busNumber = serializers.CharField(source='bus_number', required=True)
    licensePlate = serializers.CharField(source='number_plate', required=True)
    capacity = serializers.IntegerField(required=True)
    model = serializers.CharField(required=False, allow_blank=True)
    year = serializers.IntegerField(required=False, allow_null=True)
    status = serializers.ChoiceField(
        choices=['active', 'maintenance', 'inactive'],
        required=False,
        default='active'
    )
    lastMaintenance = serializers.DateField(source='last_maintenance', required=False, allow_null=True)

    class Meta:
        model = Bus
        fields = ["busNumber", "licensePlate", "capacity", "model", "year", "status", "lastMaintenance"]

    def create(self, validated_data):
        # Convert status to is_active boolean
        status = validated_data.pop('status', 'active')
        validated_data['is_active'] = (status == 'active')
        return super().create(validated_data)

    def update(self, instance, validated_data):
        # Convert status to is_active boolean
        status = validated_data.pop('status', None)
        if status:
            validated_data['is_active'] = (status == 'active')
        return super().update(instance, validated_data)
