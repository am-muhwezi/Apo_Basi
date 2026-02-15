from rest_framework import serializers
from .models import Driver
from users.models import User
from assignments.models import Assignment


class DriverSerializer(serializers.ModelSerializer):
    """For GET requests - includes all data with relationships

    NOTE: Uses Assignment API for assignedBusId and assignedBusNumber
    """
    id = serializers.IntegerField(source='user.id', read_only=True)
    firstName = serializers.CharField(source='user.first_name', read_only=True)
    lastName = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    phone = serializers.CharField(source='phone_number', read_only=True)
    licenseNumber = serializers.CharField(source='license_number', read_only=True)
    licenseExpiry = serializers.DateField(source='license_expiry', read_only=True)
    assignedBusId = serializers.SerializerMethodField()
    assignedBusNumber = serializers.SerializerMethodField()

    class Meta:
        model = Driver
        fields = [
            'id', 'firstName', 'lastName', 'email', 'phone',
            'licenseNumber', 'licenseExpiry', 'status',
            'assignedBusId', 'assignedBusNumber'
        ]

    def get_assignedBusId(self, obj):
        """Get assigned bus ID from Assignment API"""
        assignment = Assignment.get_active_assignments_for(obj, 'driver_to_bus').first()
        return assignment.assigned_to.id if assignment and assignment.assigned_to else None

    def get_assignedBusNumber(self, obj):
        """Get assigned bus number from Assignment API"""
        assignment = Assignment.get_active_assignments_for(obj, 'driver_to_bus').first()
        return assignment.assigned_to.bus_number if assignment and assignment.assigned_to else None


class DriverCreateSerializer(serializers.Serializer):
    """For POST/PUT requests - validates input and creates User + Driver"""
    firstName = serializers.CharField(write_only=True)
    lastName = serializers.CharField(write_only=True)
    email = serializers.EmailField(required=False, allow_blank=True, write_only=True)
    phone = serializers.CharField(write_only=True)
    licenseNumber = serializers.CharField(write_only=True)
    licenseExpiry = serializers.DateField(required=False, allow_null=True, write_only=True)
    status = serializers.ChoiceField(choices=['active', 'inactive'], default='active', write_only=True)
    assignedBusId = serializers.IntegerField(required=False, allow_null=True, write_only=True)

    def validate_phone(self, value):
        """Check that phone number is unique across all roles"""
        from parents.models import Parent
        from busminders.models import BusMinder

        instance = getattr(self, 'instance', None)
        own_qs = Driver.objects.filter(phone_number=value)
        if instance:
            own_qs = own_qs.exclude(pk=instance.pk)
        if own_qs.exists():
            raise serializers.ValidationError(f"Phone number '{value}' is already registered as a Driver.")
        if Parent.objects.filter(contact_number=value).exists():
            raise serializers.ValidationError(f"Phone number '{value}' is already registered as a Parent.")
        if BusMinder.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError(f"Phone number '{value}' is already registered as a Bus Minder.")
        return value

    def validate_licenseNumber(self, value):
        """Check that license number is unique among drivers"""
        instance = getattr(self, 'instance', None)
        qs = Driver.objects.filter(license_number__iexact=value)
        if instance:
            qs = qs.exclude(pk=instance.pk)
        if qs.exists():
            raise serializers.ValidationError(f"A driver with license number '{value}' already exists.")
        return value

    def validate_email(self, value):
        """Check that email is unique if provided"""
        if not value:
            return value
        instance = getattr(self, 'instance', None)
        qs = User.objects.filter(email__iexact=value)
        if instance:
            qs = qs.exclude(pk=instance.user.pk)
        if qs.exists():
            raise serializers.ValidationError(f"A user with email '{value}' already exists.")
        return value

    def create(self, validated_data):
        from django.db import IntegrityError

        # Extract user data
        first_name = validated_data.pop('firstName')
        last_name = validated_data.pop('lastName')
        email = validated_data.pop('email', '') or ''

        # Generate a unique username (required by Django)
        import uuid
        username = email if email else f"{first_name.lower()}.{last_name.lower()}.{uuid.uuid4().hex[:8]}"

        # Create User
        try:
            user = User.objects.create_user(
                username=username,
                email=email,
                first_name=first_name,
                last_name=last_name,
                user_type='driver'
            )
        except IntegrityError as e:
            raise serializers.ValidationError({'non_field_errors': [str(e)]})

        # Extract assigned_bus if provided
        assigned_bus_id = validated_data.pop('assignedBusId', None)

        # Create Driver with remaining fields
        try:
            driver = Driver.objects.create(
                user=user,
                phone_number=validated_data.get('phone'),
                license_number=validated_data.get('licenseNumber'),
                license_expiry=validated_data.get('licenseExpiry'),
                status=validated_data.get('status', 'active'),
            )
        except IntegrityError as e:
            try:
                user.delete()
            except Exception:
                pass
            if 'already in use' in str(e):
                raise serializers.ValidationError({'phone': str(e)})
            raise serializers.ValidationError({'non_field_errors': [str(e)]})

        # Assign bus if provided (using Assignment API)
        if assigned_bus_id:
            from buses.models import Bus
            from assignments.services import AssignmentService
            try:
                bus = Bus.objects.get(id=assigned_bus_id)
                # Use Assignment API instead of direct ForeignKey
                AssignmentService.create_assignment(
                    assignment_type='driver_to_bus',
                    assignee=driver,
                    assigned_to=bus,
                    assigned_by=None,  # System assignment
                    reason="Created via driver creation",
                    auto_cancel_conflicting=True
                )
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
            from buses.models import Bus
            from assignments.services import AssignmentService

            if bus_id:
                # Assign to new bus using Assignment API
                try:
                    bus = Bus.objects.get(id=bus_id)
                    AssignmentService.create_assignment(
                        assignment_type='driver_to_bus',
                        assignee=instance,
                        assigned_to=bus,
                        assigned_by=None,  # System assignment
                        reason="Updated via driver edit",
                        auto_cancel_conflicting=True  # This will cancel old assignments
                    )
                except Bus.DoesNotExist:
                    pass
            else:
                # Cancel existing bus assignment
                existing_assignment = Assignment.get_active_assignments_for(instance, 'driver_to_bus').first()
                if existing_assignment:
                    existing_assignment.status = 'cancelled'
                    existing_assignment.save()

        instance.save()
        return instance

    def to_representation(self, instance):
        # Return the full DriverSerializer representation
        return DriverSerializer(instance).data
