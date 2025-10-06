from rest_framework import serializers
from users.models import User
from parents.models import Parent
from busminders.models import BusMinder
from .models import Admin


class AdminUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "first_name",
            "last_name",
            "email",
            "user_type",
            "phone_number",
        ]


class AdminParentSerializer(serializers.ModelSerializer):
    user = AdminUserSerializer()

    class Meta:
        model = Parent
        fields = ["id", "user", "address", "emergency_contact"]


class AdminBusMinderSerializer(serializers.ModelSerializer):
    user = AdminUserSerializer()

    class Meta:
        model = BusMinder
        fields = ["id", "user"]


class AdminSerializer(serializers.ModelSerializer):
    """Full admin serializer - uses camelCase for frontend"""
    id = serializers.IntegerField(source='user.id', read_only=True)
    firstName = serializers.CharField(source='user.first_name', read_only=True)
    lastName = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    phone = serializers.CharField(source='contact_number', read_only=True)
    permissions = serializers.SerializerMethodField()
    lastLogin = serializers.DateTimeField(source='user.last_login', read_only=True)
    createdAt = serializers.DateTimeField(source='user.date_joined', read_only=True)

    class Meta:
        model = Admin
        fields = ['id', 'firstName', 'lastName', 'email', 'phone', 'role', 'permissions', 'status', 'lastLogin', 'createdAt']

    def get_permissions(self, obj):
        # Return permissions based on role
        if obj.role == 'super-admin':
            return ['manage-children', 'manage-parents', 'manage-buses', 'manage-drivers', 'manage-minders', 'manage-trips', 'manage-admins', 'view-reports']
        elif obj.role == 'admin':
            return ['manage-children', 'manage-parents', 'manage-buses', 'manage-drivers', 'manage-minders', 'manage-trips', 'view-reports']
        else:  # viewer
            return ['view-reports']


class AdminRegistrationSerializer(serializers.Serializer):
    """Serializer for admin self-registration with password"""
    username = serializers.CharField(write_only=True)
    email = serializers.EmailField(write_only=True)
    password = serializers.CharField(write_only=True)
    password_confirm = serializers.CharField(write_only=True)
    first_name = serializers.CharField(write_only=True)
    last_name = serializers.CharField(write_only=True)
    phone_number = serializers.CharField(required=False, write_only=True)

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        phone_number = validated_data.pop('phone_number', '')

        # Create user
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            user_type='admin',
            phone_number=phone_number
        )
        user.set_password(password)
        user.save()

        # Create admin profile
        admin = Admin.objects.create(
            user=user,
            contact_number=phone_number,
            role='admin',
            status='active'
        )

        return user


class AdminCreateSerializer(serializers.Serializer):
    """Serializer for creating/updating admins"""
    firstName = serializers.CharField(write_only=True)
    lastName = serializers.CharField(write_only=True)
    email = serializers.EmailField(required=False, write_only=True)
    phone = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=['super-admin', 'admin', 'viewer'], default='admin', write_only=True)
    status = serializers.ChoiceField(choices=['active', 'inactive'], default='active', write_only=True)

    def create(self, validated_data):
        first_name = validated_data.pop('firstName')
        last_name = validated_data.pop('lastName')
        email = validated_data.pop('email', f"{first_name.lower()}.{last_name.lower()}@stmarys.ug")

        # Generate unique username
        username = email
        if User.objects.filter(email=email).exists():
            counter = 1
            while User.objects.filter(email=email).exists():
                email = f"{first_name.lower()}.{last_name.lower()}{counter}@stmarys.ug"
                counter += 1
            username = email

        # Create user
        user = User.objects.create_user(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            user_type='admin',
            password='admin123'  # Default password
        )

        # Create admin
        admin = Admin.objects.create(
            user=user,
            contact_number=validated_data.get('phone', ''),
            role=validated_data.get('role', 'admin'),
            status=validated_data.get('status', 'active')
        )

        return admin

    def update(self, instance, validated_data):
        # Update user fields
        if 'firstName' in validated_data:
            instance.user.first_name = validated_data.pop('firstName')
        if 'lastName' in validated_data:
            instance.user.last_name = validated_data.pop('lastName')
        if 'email' in validated_data:
            instance.user.email = validated_data.pop('email')
            instance.user.username = instance.user.email
        instance.user.save()

        # Update admin fields
        if 'phone' in validated_data:
            instance.contact_number = validated_data.pop('phone')
        if 'role' in validated_data:
            instance.role = validated_data.pop('role')
        if 'status' in validated_data:
            instance.status = validated_data.pop('status')

        instance.save()
        return instance

    def to_representation(self, instance):
        return AdminSerializer(instance).data
