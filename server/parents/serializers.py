from rest_framework import serializers
from .models import Parent


class ParentLoginSerializer(serializers.Serializer):
    """Validates phone number for login"""
    phone_number = serializers.CharField(
        required=True,
        max_length=15,
        error_messages={
            'required': 'Phone number is required',
            'blank': 'Phone number cannot be blank'
        }
    )

    def validate_phone_number(self, value):
        """Add custom phone validation if needed"""
        if not value.strip():
            raise serializers.ValidationError("Phone number cannot be empty")
        return value.strip()


class ParentSerializer(serializers.ModelSerializer):
    """
    For GET requests - includes all parent data with relationships.
    Uses camelCase for frontend consistency.
    """
    id = serializers.IntegerField(source='user.id', read_only=True)
    firstName = serializers.CharField(source='user.first_name', read_only=True)
    lastName = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    phone = serializers.CharField(source='contact_number', read_only=True)
    emergencyContact = serializers.CharField(source='emergency_contact', read_only=True)
    childrenCount = serializers.SerializerMethodField()
    childrenIds = serializers.SerializerMethodField()

    class Meta:
        model = Parent
        fields = [
            'id', 'firstName', 'lastName', 'email', 'phone',
            'address', 'emergencyContact', 'status', 'childrenCount', 'childrenIds'
        ]

    def get_childrenCount(self, obj):
        return obj.parent_children.count() if hasattr(obj, 'parent_children') else 0

    def get_childrenIds(self, obj):
        """Return list of child IDs assigned to this parent"""
        if hasattr(obj, 'parent_children'):
            return list(obj.parent_children.values_list('id', flat=True))
        return []


class ParentCreateSerializer(serializers.Serializer):
    """
    For POST/PUT requests - validates input and creates User + Parent.

    Email is optional but must be unique if provided.
    Phone number is mandatory.
    Address and emergency contact are optional.
    """
    firstName = serializers.CharField(write_only=True)
    lastName = serializers.CharField(write_only=True)
    email = serializers.EmailField(
        required=False,
        allow_blank=True,
        write_only=True,
        help_text="Optional - must be unique if provided"
    )
    phone = serializers.CharField(write_only=True, help_text="Mandatory - primary contact number")
    address = serializers.CharField(required=False, allow_blank=True, write_only=True)
    emergencyContact = serializers.CharField(required=False, allow_blank=True, write_only=True)
    status = serializers.ChoiceField(choices=['active', 'inactive'], default='active', write_only=True)

    def validate_phone(self, value):
        """Check that phone number is unique across all roles"""
        from drivers.models import Driver
        from busminders.models import BusMinder

        instance = getattr(self, 'instance', None)
        own_qs = Parent.objects.filter(contact_number=value)
        if instance:
            own_qs = own_qs.exclude(pk=instance.pk)
        if own_qs.exists():
            raise serializers.ValidationError(f"Phone number '{value}' is already registered as a Parent.")
        if Driver.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError(f"Phone number '{value}' is already registered as a Driver.")
        if BusMinder.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError(f"Phone number '{value}' is already registered as a Bus Minder.")
        return value

    def validate_email(self, value):
        """Check that email is unique if provided"""
        if not value:
            return value
        from django.contrib.auth import get_user_model
        User = get_user_model()
        instance = getattr(self, 'instance', None)
        qs = User.objects.filter(email__iexact=value)
        if instance:
            qs = qs.exclude(pk=instance.user.pk)
        if qs.exists():
            raise serializers.ValidationError(f"A user with email '{value}' already exists.")
        return value

    def create(self, validated_data):
        from django.contrib.auth import get_user_model
        from django.db import IntegrityError
        User = get_user_model()
        import uuid

        # Extract user data
        first_name = validated_data.pop('firstName')
        last_name = validated_data.pop('lastName')
        email = validated_data.pop('email', '') or ''

        # Generate a unique username (required by Django)
        username = email if email else f"{first_name.lower()}.{last_name.lower()}.{uuid.uuid4().hex[:8]}"

        # Create User
        try:
            user = User.objects.create_user(
                username=username,
                email=email,
                first_name=first_name,
                last_name=last_name,
                user_type='parent'
            )
        except IntegrityError as e:
            raise serializers.ValidationError({'non_field_errors': [str(e)]})

        # Create Parent
        try:
            parent = Parent.objects.create(
                user=user,
                contact_number=validated_data.get('phone'),
                address=validated_data.get('address', ''),
                emergency_contact=validated_data.get('emergencyContact', ''),
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

        return parent

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

        # Update Parent fields
        if 'phone' in validated_data:
            instance.contact_number = validated_data.pop('phone')
        if 'address' in validated_data:
            instance.address = validated_data.pop('address')
        if 'emergencyContact' in validated_data:
            instance.emergency_contact = validated_data.pop('emergencyContact')
        if 'status' in validated_data:
            instance.status = validated_data.pop('status')

        instance.save()
        return instance

    def to_representation(self, instance):
        # Return the full ParentSerializer representation
        return ParentSerializer(instance).data
