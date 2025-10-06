from rest_framework import serializers
from .models import Driver
from users.models import User


class DriverSerializer(serializers.ModelSerializer):
    """For GET requests - includes all data with relationships"""
    id = serializers.IntegerField(source='user.id', read_only=True)
    firstName = serializers.CharField(source='user.first_name', read_only=True)
    lastName = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    phone = serializers.CharField(source='phone_number', read_only=True)
    licenseNumber = serializers.CharField(source='license_number', read_only=True)
    licenseExpiry = serializers.DateField(source='license_expiry', read_only=True)
    assignedBusId = serializers.IntegerField(source='assigned_bus.id', read_only=True, allow_null=True)
    assignedBusNumber = serializers.CharField(source='assigned_bus.bus_number', read_only=True, allow_null=True)

    class Meta:
        model = Driver
        fields = [
            'id', 'firstName', 'lastName', 'email', 'phone',
            'licenseNumber', 'licenseExpiry', 'status',
            'assignedBusId', 'assignedBusNumber'
        ]


class DriverCreateSerializer(serializers.Serializer):
    """For POST/PUT requests - validates input and creates User + Driver"""
    firstName = serializers.CharField(write_only=True)
    lastName = serializers.CharField(write_only=True)
    email = serializers.EmailField(required=False, write_only=True)
    phone = serializers.CharField(write_only=True)
    licenseNumber = serializers.CharField(write_only=True)
    licenseExpiry = serializers.DateField(required=False, allow_null=True, write_only=True)
    status = serializers.ChoiceField(choices=['active', 'inactive'], default='active', write_only=True)
    assignedBusId = serializers.IntegerField(required=False, allow_null=True, write_only=True)

    def create(self, validated_data):
        # Extract user data
        first_name = validated_data.pop('firstName')
        last_name = validated_data.pop('lastName')
        email = validated_data.pop('email', f"{first_name.lower()}.{last_name.lower()}@driver.com")

        # Create User
        user = User.objects.create_user(
            username=email,
            email=email,
            first_name=first_name,
            last_name=last_name,
            user_type='driver'
        )

        # Extract assigned_bus if provided
        assigned_bus_id = validated_data.pop('assignedBusId', None)

        # Create Driver with remaining fields
        driver = Driver.objects.create(
            user=user,
            phone_number=validated_data.get('phone'),
            license_number=validated_data.get('licenseNumber'),
            license_expiry=validated_data.get('licenseExpiry'),
            status=validated_data.get('status', 'active'),
        )

        # Assign bus if provided
        if assigned_bus_id:
            from buses.models import Bus
            try:
                bus = Bus.objects.get(id=assigned_bus_id)
                driver.assigned_bus = bus
                driver.save()
            except Bus.DoesNotExist:
                pass

        return driver

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

        # Update Driver fields
        if 'phone' in validated_data:
            instance.phone_number = validated_data.pop('phone')
        if 'licenseNumber' in validated_data:
            instance.license_number = validated_data.pop('licenseNumber')
        if 'licenseExpiry' in validated_data:
            instance.license_expiry = validated_data.pop('licenseExpiry')
        if 'status' in validated_data:
            instance.status = validated_data.pop('status')
        if 'assignedBusId' in validated_data:
            bus_id = validated_data.pop('assignedBusId')
            if bus_id:
                from buses.models import Bus
                try:
                    bus = Bus.objects.get(id=bus_id)
                    instance.assigned_bus = bus
                except Bus.DoesNotExist:
                    pass
            else:
                instance.assigned_bus = None

        instance.save()
        return instance

    def to_representation(self, instance):
        # Return the full DriverSerializer representation
        return DriverSerializer(instance).data
