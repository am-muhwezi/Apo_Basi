from rest_framework import serializers
from .models import Bus, BusLocationHistory
from django.contrib.auth import get_user_model
from assignments.models import Assignment

User = get_user_model()


class BusSerializer(serializers.ModelSerializer):
    """Full bus serializer - uses camelCase for frontend consistency

    NOTE: Uses Assignment API instead of legacy ForeignKeys for:
    - driverId, driverName (via Assignment)
    - minderId, minderName (via Assignment)
    - assignedChildrenCount, assignedChildrenIds (via Assignment)
    """
    busNumber = serializers.CharField(source='bus_number')
    licensePlate = serializers.CharField(source='number_plate')
    driverId = serializers.SerializerMethodField()
    driverName = serializers.SerializerMethodField()
    minderId = serializers.SerializerMethodField()
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

    def get_driverId(self, obj):
        """Get driver ID from Assignment API"""
        driver_assignment = Assignment.get_assignments_to(obj, 'driver_to_bus').first()
        return driver_assignment.assignee.user_id if driver_assignment else None

    def get_driverName(self, obj):
        """Get driver name from Assignment API"""
        driver_assignment = Assignment.get_assignments_to(obj, 'driver_to_bus').first()
        if driver_assignment:
            driver = driver_assignment.assignee
            return f"{driver.user.first_name} {driver.user.last_name}"
        return None

    def get_minderId(self, obj):
        """Get minder ID from Assignment API"""
        minder_assignment = Assignment.get_assignments_to(obj, 'minder_to_bus').first()
        return minder_assignment.assignee.user_id if minder_assignment else None

    def get_minderName(self, obj):
        """Get minder name from Assignment API"""
        minder_assignment = Assignment.get_assignments_to(obj, 'minder_to_bus').first()
        if minder_assignment:
            minder = minder_assignment.assignee
            return f"{minder.user.first_name} {minder.user.last_name}"
        return None

    def get_assignedChildrenCount(self, obj):
        """Get children count from Assignment API"""
        child_assignments = Assignment.get_assignments_to(obj, 'child_to_bus')
        return child_assignments.count()

    def get_assignedChildrenIds(self, obj):
        """Get list of child IDs from Assignment API"""
        child_assignments = Assignment.get_assignments_to(obj, 'child_to_bus')
        return [ca.assignee_object_id for ca in child_assignments]

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

    def validate_licensePlate(self, value):
        """Check that license plate is unique"""
        instance = getattr(self, 'instance', None)
        qs = Bus.objects.filter(number_plate__iexact=value)
        if instance:
            qs = qs.exclude(pk=instance.pk)
        if qs.exists():
            raise serializers.ValidationError(f"A bus with license plate '{value}' already exists.")
        return value

    def validate_busNumber(self, value):
        """Check that bus number is unique"""
        instance = getattr(self, 'instance', None)
        qs = Bus.objects.filter(bus_number__iexact=value)
        if instance:
            qs = qs.exclude(pk=instance.pk)
        if qs.exists():
            raise serializers.ValidationError(f"A bus with number '{value}' already exists.")
        return value

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


class PushLocationSerializer(serializers.Serializer):
    """
    Serializer for driver pushing location updates.

    Used by drivers to send real-time GPS coordinates from their mobile app.

    Example Request Body:
    {
        "lat": 9.0820,
        "lng": 7.5340,
        "speed": 45.5,       // Optional
        "heading": 180.0     // Optional
    }
    """
    lat = serializers.DecimalField(
        max_digits=12,
        decimal_places=8,
        required=True,
        help_text="GPS latitude (-90 to 90)",
        coerce_to_string=False
    )
    lng = serializers.DecimalField(
        max_digits=12,
        decimal_places=8,
        required=True,
        help_text="GPS longitude (-180 to 180)",
        coerce_to_string=False
    )
    speed = serializers.FloatField(
        required=False,
        allow_null=True,
        help_text="Speed in m/s (will be converted from GPS speed)"
    )
    heading = serializers.FloatField(
        required=False,
        allow_null=True,
        help_text="Direction in degrees (0-360)"
    )

    def validate_lat(self, value):
        """Validate latitude is within valid range"""
        if not (-90 <= value <= 90):
            raise serializers.ValidationError("Latitude must be between -90 and 90")
        return value

    def validate_lng(self, value):
        """Validate longitude is within valid range"""
        if not (-180 <= value <= 180):
            raise serializers.ValidationError("Longitude must be between -180 and 180")
        return value

    def validate_heading(self, value):
        """Validate heading is within valid range"""
        if value is not None and not (0 <= value <= 360):
            raise serializers.ValidationError("Heading must be between 0 and 360 degrees")
        return value


class CurrentLocationSerializer(serializers.Serializer):
    """
    Serializer for returning current bus location to parents/admins.

    Response format optimized for mobile map display.
    """
    busId = serializers.IntegerField(source='bus_id')
    busNumber = serializers.CharField(source='bus_number')
    lat = serializers.DecimalField(max_digits=9, decimal_places=6)
    lng = serializers.DecimalField(max_digits=9, decimal_places=6)
    speed = serializers.FloatField(allow_null=True)
    heading = serializers.FloatField(allow_null=True)
    isActive = serializers.BooleanField(source='is_active')
    timestamp = serializers.DateTimeField()


class BusLocationHistorySerializer(serializers.ModelSerializer):
    """
    Serializer for historical location data.

    Used for trip reports and analytics.
    """
    busNumber = serializers.CharField(source='bus.bus_number', read_only=True)

    class Meta:
        model = BusLocationHistory
        fields = ['id', 'busNumber', 'latitude', 'longitude', 'speed', 'heading', 'is_active', 'timestamp', 'trip']
        read_only_fields = ['id', 'timestamp']
