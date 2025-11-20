from rest_framework import serializers
from .models import Trip, Stop
from children.serializers import ChildSerializer
from django.contrib.auth import get_user_model

User = get_user_model()


class StopSerializer(serializers.ModelSerializer):
    """Serializer for Stop model - uses camelCase for frontend"""
    childrenIds = serializers.PrimaryKeyRelatedField(
        source='children',
        many=True,
        read_only=True
    )
    location = serializers.SerializerMethodField()
    scheduledTime = serializers.DateTimeField(source='scheduled_time')
    actualTime = serializers.DateTimeField(source='actual_time', allow_null=True, required=False)

    class Meta:
        model = Stop
        fields = ['id', 'address', 'location', 'childrenIds', 'scheduledTime', 'actualTime', 'status', 'order']

    def get_location(self, obj):
        return {
            'latitude': float(obj.latitude),
            'longitude': float(obj.longitude),
            'timestamp': obj.scheduled_time.isoformat() if obj.scheduled_time else None
        }


class StopCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating stops"""
    childrenIds = serializers.ListField(
        child=serializers.IntegerField(),
        source='children',
        required=False,
        allow_empty=True
    )
    scheduledTime = serializers.DateTimeField(source='scheduled_time')
    actualTime = serializers.DateTimeField(source='actual_time', allow_null=True, required=False)

    class Meta:
        model = Stop
        fields = ['address', 'latitude', 'longitude', 'childrenIds', 'scheduledTime', 'actualTime', 'status', 'order']

    def create(self, validated_data):
        children_ids = validated_data.pop('children', [])
        stop = Stop.objects.create(**validated_data)
        if children_ids:
            stop.children.set(children_ids)
        return stop

    def update(self, instance, validated_data):
        children_ids = validated_data.pop('children', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if children_ids is not None:
            instance.children.set(children_ids)
        return instance


class TripSerializer(serializers.ModelSerializer):
    """Full trip serializer - uses camelCase for frontend consistency"""
    busId = serializers.IntegerField(source='bus.id', read_only=True)
    busNumber = serializers.CharField(source='bus.bus_number', read_only=True)
    driverId = serializers.IntegerField(source='driver.id', read_only=True)
    driverName = serializers.CharField(source='driver.get_full_name', read_only=True)
    minderId = serializers.IntegerField(source='bus_minder.id', read_only=True, allow_null=True)
    minderName = serializers.SerializerMethodField()
    type = serializers.CharField(source='trip_type')
    scheduledTime = serializers.DateTimeField(source='scheduled_time')
    startTime = serializers.DateTimeField(source='start_time', allow_null=True, required=False)
    endTime = serializers.DateTimeField(source='end_time', allow_null=True, required=False)
    currentLocation = serializers.SerializerMethodField()
    stops = StopSerializer(many=True, read_only=True)
    childrenIds = serializers.PrimaryKeyRelatedField(
        source='children',
        many=True,
        read_only=True
    )
    totalStudents = serializers.IntegerField(source='total_students', allow_null=True, required=False)
    studentsCompleted = serializers.IntegerField(source='students_completed', allow_null=True, required=False)
    studentsAbsent = serializers.IntegerField(source='students_absent', allow_null=True, required=False)
    studentsPending = serializers.IntegerField(source='students_pending', allow_null=True, required=False)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = Trip
        fields = [
            'id', 'busId', 'busNumber', 'driverId', 'driverName', 'minderId', 'minderName',
            'route', 'type', 'status',
            'scheduledTime', 'startTime', 'endTime', 'currentLocation',
            'stops', 'childrenIds', 'totalStudents', 'studentsCompleted',
            'studentsAbsent', 'studentsPending', 'createdAt'
        ]

    def get_minderName(self, obj):
        if obj.bus_minder:
            return obj.bus_minder.get_full_name()
        return None

    def get_currentLocation(self, obj):
        if obj.current_latitude and obj.current_longitude:
            return {
                'latitude': float(obj.current_latitude),
                'longitude': float(obj.current_longitude),
                'timestamp': obj.location_timestamp.isoformat() if obj.location_timestamp else None
            }
        return None


class TripCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating trips - uses camelCase"""
    busId = serializers.IntegerField(source='bus_id', required=True)
    driverId = serializers.IntegerField(source='driver_id', required=True)
    minderId = serializers.IntegerField(source='bus_minder_id', required=False, allow_null=True)
    type = serializers.ChoiceField(source='trip_type', choices=['pickup', 'dropoff'], required=True)
    scheduledTime = serializers.DateTimeField(source='scheduled_time', required=True)
    startTime = serializers.DateTimeField(source='start_time', required=False, allow_null=True)
    endTime = serializers.DateTimeField(source='end_time', required=False, allow_null=True)
    childrenIds = serializers.ListField(
        child=serializers.IntegerField(),
        source='children',
        required=False,
        allow_empty=True
    )
    stops = StopCreateSerializer(many=True, required=False)

    class Meta:
        model = Trip
        fields = [
            'busId', 'driverId', 'minderId', 'route', 'type', 'status',
            'scheduledTime', 'startTime', 'endTime', 'childrenIds', 'stops'
        ]

    def create(self, validated_data):
        children_ids = validated_data.pop('children', [])
        stops_data = validated_data.pop('stops', [])

        trip = Trip.objects.create(**validated_data)

        if children_ids:
            trip.children.set(children_ids)

        # Create stops
        for stop_data in stops_data:
            stop_children_ids = stop_data.pop('children', [])
            stop = Stop.objects.create(trip=trip, **stop_data)
            if stop_children_ids:
                stop.children.set(stop_children_ids)

        return trip

    def update(self, instance, validated_data):
        children_ids = validated_data.pop('children', None)
        stops_data = validated_data.pop('stops', None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if children_ids is not None:
            instance.children.set(children_ids)

        # Update stops if provided
        if stops_data is not None:
            # Delete existing stops
            instance.stops.all().delete()
            # Create new stops
            for stop_data in stops_data:
                stop_children_ids = stop_data.pop('children', [])
                stop = Stop.objects.create(trip=instance, **stop_data)
                if stop_children_ids:
                    stop.children.set(stop_children_ids)

        return instance

    def to_representation(self, instance):
        # Return the full TripSerializer representation
        return TripSerializer(instance).data
