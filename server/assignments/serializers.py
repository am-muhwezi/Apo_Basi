from rest_framework import serializers
from django.contrib.contenttypes.models import ContentType
from .models import Assignment, BusRoute, AssignmentHistory
from buses.models import Bus
from drivers.models import Driver
from busminders.models import BusMinder
from children.models import Child


class BusRouteSerializer(serializers.ModelSerializer):
    """Full BusRoute serializer - uses camelCase for frontend consistency"""

    routeCode = serializers.CharField(source='route_code')
    defaultBusId = serializers.IntegerField(source='default_bus.id', read_only=True, allow_null=True)
    defaultBusNumber = serializers.SerializerMethodField()
    defaultDriverId = serializers.IntegerField(source='default_driver.id', read_only=True, allow_null=True)
    defaultDriverName = serializers.SerializerMethodField()
    defaultMinderId = serializers.IntegerField(source='default_minder.id', read_only=True, allow_null=True)
    defaultMinderName = serializers.SerializerMethodField()
    estimatedDuration = serializers.IntegerField(source='estimated_duration', allow_null=True)
    totalDistance = serializers.FloatField(source='total_distance', allow_null=True)
    isActive = serializers.BooleanField(source='is_active')
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)
    updatedAt = serializers.DateTimeField(source='updated_at', read_only=True)

    # Additional computed fields
    activeAssignmentsCount = serializers.SerializerMethodField()
    assignedChildrenCount = serializers.SerializerMethodField()

    class Meta:
        model = BusRoute
        fields = [
            'id', 'name', 'routeCode', 'description',
            'defaultBusId', 'defaultBusNumber',
            'defaultDriverId', 'defaultDriverName',
            'defaultMinderId', 'defaultMinderName',
            'schedule', 'estimatedDuration', 'totalDistance',
            'isActive', 'createdAt', 'updatedAt',
            'activeAssignmentsCount', 'assignedChildrenCount'
        ]

    def get_defaultBusNumber(self, obj):
        return obj.default_bus.bus_number if obj.default_bus else None

    def get_defaultDriverName(self, obj):
        if obj.default_driver and obj.default_driver.user:
            user = obj.default_driver.user
            return f"{user.first_name} {user.last_name}"
        return None

    def get_defaultMinderName(self, obj):
        if obj.default_minder and obj.default_minder.user:
            user = obj.default_minder.user
            return f"{user.first_name} {user.last_name}"
        return None

    def get_activeAssignmentsCount(self, obj):
        """Count active assignments for this route"""
        return obj.get_active_assignments().count()

    def get_assignedChildrenCount(self, obj):
        """Count children assigned to this route"""
        from django.utils import timezone
        today = timezone.now().date()

        return Assignment.objects.filter(
            assigned_to_content_type=ContentType.objects.get_for_model(BusRoute),
            assigned_to_object_id=obj.id,
            assignment_type='child_to_route',
            status='active',
            effective_date__lte=today
        ).filter(
            models.Q(expiry_date__isnull=True) |
            models.Q(expiry_date__gte=today)
        ).count()


class BusRouteCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating BusRoutes - uses camelCase"""

    routeCode = serializers.CharField(source='route_code', required=True)
    defaultBusId = serializers.PrimaryKeyRelatedField(
        source='default_bus',
        queryset=Bus.objects.all(),
        required=False,
        allow_null=True
    )
    defaultDriverId = serializers.PrimaryKeyRelatedField(
        source='default_driver',
        queryset=Driver.objects.all(),
        required=False,
        allow_null=True
    )
    defaultMinderId = serializers.PrimaryKeyRelatedField(
        source='default_minder',
        queryset=BusMinder.objects.all(),
        required=False,
        allow_null=True
    )
    estimatedDuration = serializers.IntegerField(source='estimated_duration', required=False, allow_null=True)
    totalDistance = serializers.FloatField(source='total_distance', required=False, allow_null=True)
    isActive = serializers.BooleanField(source='is_active', required=False, default=True)

    class Meta:
        model = BusRoute
        fields = [
            'name', 'routeCode', 'description',
            'defaultBusId', 'defaultDriverId', 'defaultMinderId',
            'schedule', 'estimatedDuration', 'totalDistance', 'isActive'
        ]


class AssignmentSerializer(serializers.ModelSerializer):
    """Full Assignment serializer - uses camelCase for frontend consistency"""

    assignmentType = serializers.CharField(source='assignment_type')

    # Assignee information
    assigneeType = serializers.SerializerMethodField()
    assigneeId = serializers.IntegerField(source='assignee_object_id', read_only=True)
    assigneeName = serializers.SerializerMethodField()
    assigneeDetails = serializers.SerializerMethodField()

    # Assigned to information
    assignedToType = serializers.SerializerMethodField()
    assignedToId = serializers.IntegerField(source='assigned_to_object_id', read_only=True)
    assignedToName = serializers.SerializerMethodField()
    assignedToDetails = serializers.SerializerMethodField()

    # Dates
    effectiveDate = serializers.DateField(source='effective_date')
    expiryDate = serializers.DateField(source='expiry_date', allow_null=True)

    # Audit trail
    assignedById = serializers.IntegerField(source='assigned_by.id', read_only=True, allow_null=True)
    assignedByName = serializers.SerializerMethodField()
    assignedAt = serializers.DateTimeField(source='assigned_at', read_only=True)

    # Status
    isCurrentlyActive = serializers.SerializerMethodField()
    updatedAt = serializers.DateTimeField(source='updated_at', read_only=True)

    class Meta:
        model = Assignment
        fields = [
            'id', 'assignmentType', 'status',
            'assigneeType', 'assigneeId', 'assigneeName', 'assigneeDetails',
            'assignedToType', 'assignedToId', 'assignedToName', 'assignedToDetails',
            'effectiveDate', 'expiryDate',
            'assignedById', 'assignedByName', 'assignedAt',
            'reason', 'notes', 'metadata',
            'isCurrentlyActive', 'updatedAt'
        ]

    def get_assigneeType(self, obj):
        """Return human-readable assignee type"""
        return obj.assignee_content_type.model

    def get_assigneeName(self, obj):
        """Return name of the assignee"""
        try:
            assignee = obj.assignee
            if isinstance(assignee, Driver):
                return f"{assignee.user.first_name} {assignee.user.last_name}"
            elif isinstance(assignee, BusMinder):
                return f"{assignee.user.first_name} {assignee.user.last_name}"
            elif isinstance(assignee, Child):
                return f"{assignee.first_name} {assignee.last_name}"
            elif isinstance(assignee, Bus):
                return assignee.bus_number
            return str(assignee)
        except:
            return None

    def get_assigneeDetails(self, obj):
        """Return detailed info about assignee"""
        try:
            assignee = obj.assignee
            if isinstance(assignee, Driver):
                return {
                    'type': 'driver',
                    'id': assignee.user.id,
                    'name': f"{assignee.user.first_name} {assignee.user.last_name}",
                    'licenseNumber': assignee.license_number,
                    'status': assignee.status
                }
            elif isinstance(assignee, BusMinder):
                return {
                    'type': 'busminder',
                    'id': assignee.user.id,
                    'name': f"{assignee.user.first_name} {assignee.user.last_name}",
                    'phoneNumber': assignee.phone_number,
                    'status': assignee.status
                }
            elif isinstance(assignee, Child):
                return {
                    'type': 'child',
                    'id': assignee.id,
                    'name': f"{assignee.first_name} {assignee.last_name}",
                    'grade': assignee.class_grade,
                    'status': assignee.status
                }
            elif isinstance(assignee, Bus):
                return {
                    'type': 'bus',
                    'id': assignee.id,
                    'busNumber': assignee.bus_number,
                    'licensePlate': assignee.number_plate,
                    'capacity': assignee.capacity
                }
            return None
        except:
            return None

    def get_assignedToType(self, obj):
        """Return human-readable assigned-to type"""
        return obj.assigned_to_content_type.model

    def get_assignedToName(self, obj):
        """Return name of what's being assigned to"""
        try:
            assigned_to = obj.assigned_to
            if isinstance(assigned_to, Bus):
                return assigned_to.bus_number
            elif isinstance(assigned_to, BusRoute):
                return assigned_to.name
            return str(assigned_to)
        except:
            return None

    def get_assignedToDetails(self, obj):
        """Return detailed info about assigned-to entity"""
        try:
            assigned_to = obj.assigned_to
            if isinstance(assigned_to, Bus):
                return {
                    'type': 'bus',
                    'id': assigned_to.id,
                    'busNumber': assigned_to.bus_number,
                    'licensePlate': assigned_to.number_plate,
                    'capacity': assigned_to.capacity
                }
            elif isinstance(assigned_to, BusRoute):
                return {
                    'type': 'route',
                    'id': assigned_to.id,
                    'name': assigned_to.name,
                    'routeCode': assigned_to.route_code,
                    'isActive': assigned_to.is_active
                }
            return None
        except:
            return None

    def get_assignedByName(self, obj):
        """Return name of user who made the assignment"""
        if obj.assigned_by:
            return f"{obj.assigned_by.first_name} {obj.assigned_by.last_name}"
        return None

    def get_isCurrentlyActive(self, obj):
        """Check if assignment is currently active"""
        return obj.is_currently_active()


class AssignmentCreateSerializer(serializers.Serializer):
    """Serializer for creating assignments - uses camelCase"""

    assignmentType = serializers.ChoiceField(
        source='assignment_type',
        choices=Assignment.ASSIGNMENT_TYPES,
        required=True
    )
    assigneeId = serializers.IntegerField(source='assignee_id', required=True)
    assignedToId = serializers.IntegerField(source='assigned_to_id', required=True)
    effectiveDate = serializers.DateField(source='effective_date', required=False)
    expiryDate = serializers.DateField(source='expiry_date', required=False, allow_null=True)
    status = serializers.ChoiceField(
        choices=Assignment.STATUS_CHOICES,
        required=False,
        default='active'
    )
    reason = serializers.CharField(required=False, allow_blank=True)
    notes = serializers.CharField(required=False, allow_blank=True)
    metadata = serializers.JSONField(required=False, default=dict)

    def validate(self, data):
        """Validate assignment data"""
        assignment_type = data.get('assignment_type')
        assignee_id = data.get('assignee_id')
        assigned_to_id = data.get('assigned_to_id')

        # Validate expiry date
        if data.get('expiry_date') and data.get('effective_date'):
            if data['expiry_date'] < data['effective_date']:
                raise serializers.ValidationError({
                    'expiryDate': 'Expiry date must be after effective date'
                })

        # Map assignment type to model classes
        type_mapping = {
            'driver_to_bus': (Driver, Bus),
            'minder_to_bus': (BusMinder, Bus),
            'child_to_bus': (Child, Bus),
            'bus_to_route': (Bus, BusRoute),
            'driver_to_route': (Driver, BusRoute),
            'minder_to_route': (BusMinder, BusRoute),
            'child_to_route': (Child, BusRoute),
        }

        if assignment_type not in type_mapping:
            raise serializers.ValidationError({
                'assignmentType': f'Invalid assignment type: {assignment_type}'
            })

        assignee_model, assigned_to_model = type_mapping[assignment_type]

        # Validate assignee exists
        try:
            assignee = assignee_model.objects.get(pk=assignee_id)
            data['assignee'] = assignee
            data['assignee_content_type'] = ContentType.objects.get_for_model(assignee_model)
        except assignee_model.DoesNotExist:
            raise serializers.ValidationError({
                'assigneeId': f'{assignee_model.__name__} with id {assignee_id} does not exist'
            })

        # Validate assigned_to exists
        try:
            assigned_to = assigned_to_model.objects.get(pk=assigned_to_id)
            data['assigned_to'] = assigned_to
            data['assigned_to_content_type'] = ContentType.objects.get_for_model(assigned_to_model)
        except assigned_to_model.DoesNotExist:
            raise serializers.ValidationError({
                'assignedToId': f'{assigned_to_model.__name__} with id {assigned_to_id} does not exist'
            })

        return data

    def create(self, validated_data):
        """Create assignment instance"""
        # Extract data needed for creation
        assignee = validated_data.pop('assignee')
        assigned_to = validated_data.pop('assigned_to')
        assignee_content_type = validated_data.pop('assignee_content_type')
        assigned_to_content_type = validated_data.pop('assigned_to_content_type')
        assignee_id = validated_data.pop('assignee_id')
        assigned_to_id = validated_data.pop('assigned_to_id')

        # Get assigned_by from context
        request = self.context.get('request')
        assigned_by = request.user if request and request.user.is_authenticated else None

        # Create assignment
        assignment = Assignment.objects.create(
            assignee_content_type=assignee_content_type,
            assignee_object_id=assignee.pk,
            assigned_to_content_type=assigned_to_content_type,
            assigned_to_object_id=assigned_to.pk,
            assigned_by=assigned_by,
            **validated_data
        )

        return assignment


class AssignmentHistorySerializer(serializers.ModelSerializer):
    """Serializer for assignment history - uses camelCase"""

    assignmentId = serializers.IntegerField(source='assignment.id', read_only=True)
    performedById = serializers.IntegerField(source='performed_by.id', read_only=True, allow_null=True)
    performedByName = serializers.SerializerMethodField()
    performedAt = serializers.DateTimeField(source='performed_at', read_only=True)

    class Meta:
        model = AssignmentHistory
        fields = [
            'id', 'assignmentId', 'action',
            'performedById', 'performedByName', 'performedAt',
            'changes', 'notes'
        ]

    def get_performedByName(self, obj):
        if obj.performed_by:
            return f"{obj.performed_by.first_name} {obj.performed_by.last_name}"
        return None


# Import models at the end to avoid circular imports
from django.db import models
