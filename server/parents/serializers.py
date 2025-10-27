from rest_framework import serializers
from .models import Parent
from users.models import User


class ParentSerializer(serializers.ModelSerializer):
    """For GET requests - includes all data with relationships"""
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
    """For POST/PUT requests - validates input and creates User + Parent"""
    firstName = serializers.CharField(write_only=True)
    lastName = serializers.CharField(write_only=True)
    email = serializers.EmailField(required=False, write_only=True)
    phone = serializers.CharField(write_only=True)
    address = serializers.CharField(required=False, allow_blank=True, write_only=True)
    emergencyContact = serializers.CharField(required=False, allow_blank=True, write_only=True)
    status = serializers.ChoiceField(choices=['active', 'inactive'], default='active', write_only=True)

    def create(self, validated_data):
        # Extract user data
        first_name = validated_data.pop('firstName')
        last_name = validated_data.pop('lastName')
        email = validated_data.pop('email', f"{first_name.lower()}.{last_name.lower()}@parent.com")

        # Generate unique username and email
        if not User.objects.filter(email=email).exists():
            username = email
        else:
            base_email = f"{first_name.lower()}.{last_name.lower()}@parent.com"
            email = base_email
            counter = 1
            while User.objects.filter(email=email).exists():
                email = f"{first_name.lower()}.{last_name.lower()}{counter}@parent.com"
                counter += 1
            username = email

        # Create User
        user = User.objects.create_user(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            user_type='parent'
        )

        # Create Parent
        parent = Parent.objects.create(
            user=user,
            contact_number=validated_data.get('phone', ''),
            address=validated_data.get('address', ''),
            emergency_contact=validated_data.get('emergencyContact', ''),
            status=validated_data.get('status', 'active'),
        )

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
