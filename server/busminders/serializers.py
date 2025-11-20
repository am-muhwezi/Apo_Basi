from rest_framework import serializers
from .models import BusMinder
from users.models import User
from assignments.models import Assignment


class BusMinderSerializer(serializers.ModelSerializer):
    """For GET requests - includes all data with relationships

    NOTE: Uses Assignment API for assignedBusId, assignedBusNumber, and assignedBusesCount
    """
    id = serializers.IntegerField(source='user.id', read_only=True)
    firstName = serializers.CharField(source='user.first_name', read_only=True)
    lastName = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    phone = serializers.CharField(source='phone_number', read_only=True)
    assignedBusId = serializers.SerializerMethodField()
    assignedBusNumber = serializers.SerializerMethodField()
    assignedBusesCount = serializers.SerializerMethodField()

    class Meta:
        model = BusMinder
        fields = [
            'id', 'firstName', 'lastName', 'email', 'phone',
            'status', 'assignedBusId', 'assignedBusNumber', 'assignedBusesCount'
        ]

    def get_assignedBusId(self, obj):
        """Get the first assigned bus ID from Assignment API"""
        assignment = Assignment.get_active_assignments_for(obj, 'minder_to_bus').first()
        return assignment.assigned_to.id if assignment else None

    def get_assignedBusNumber(self, obj):
        """Get the first assigned bus number from Assignment API"""
        assignment = Assignment.get_active_assignments_for(obj, 'minder_to_bus').first()
        return assignment.assigned_to.bus_number if assignment else None

    def get_assignedBusesCount(self, obj):
        """Get count of assigned buses from Assignment API"""
        assignments = Assignment.get_active_assignments_for(obj, 'minder_to_bus')
        return assignments.count()


class BusMinderCreateSerializer(serializers.Serializer):
    """For POST/PUT requests - validates input and creates User + BusMinder"""
    firstName = serializers.CharField(write_only=True)
    lastName = serializers.CharField(write_only=True)
    email = serializers.EmailField(required=False, write_only=True)
    phone = serializers.CharField(write_only=True)
    status = serializers.ChoiceField(choices=['active', 'inactive'], default='active', write_only=True)

    def create(self, validated_data):
        # Extract user data
        first_name = validated_data.pop('firstName')
        last_name = validated_data.pop('lastName')
        email = validated_data.pop('email', f"{first_name.lower()}.{last_name.lower()}@busminder.com")

        # Generate unique username and email
        if not User.objects.filter(email=email).exists():
            username = email
        else:
            base_email = f"{first_name.lower()}.{last_name.lower()}@busminder.com"
            email = base_email
            counter = 1
            while User.objects.filter(email=email).exists():
                email = f"{first_name.lower()}.{last_name.lower()}{counter}@busminder.com"
                counter += 1
            username = email

        # Create User
        user = User.objects.create_user(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            user_type='busminder'
        )

        # Create BusMinder
        busminder = BusMinder.objects.create(
            user=user,
            phone_number=validated_data.get('phone'),
            status=validated_data.get('status', 'active'),
        )

        return busminder

    def update(self, instance, validated_data):
        # Update User fields
        if 'firstName' in validated_data:
            instance.user.first_name = validated_data.pop('firstName')
        if 'lastName' in validated_data:
            instance.user.last_name = validated_data.pop('lastName')
        if 'email' in validated_data:
            instance.user.email = validated_data.pop('email')
            instance.user.username = instance.user.email
        instance.user.save()

        # Update BusMinder fields
        if 'phone' in validated_data:
            instance.phone_number = validated_data.pop('phone')
        if 'status' in validated_data:
            instance.status = validated_data.pop('status')

        instance.save()
        return instance

    def to_representation(self, instance):
        # Return the full BusMinderSerializer representation
        return BusMinderSerializer(instance).data
