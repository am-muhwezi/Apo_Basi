from rest_framework import serializers
from .models import Child
from assignments.models import Assignment


class ChildSerializer(serializers.ModelSerializer):
    """For GET requests - includes all data with relationships

    NOTE: Uses Assignment API for assignedBusId and assignedBusNumber
    """
    firstName = serializers.CharField(source='first_name', read_only=True)
    lastName = serializers.CharField(source='last_name', read_only=True)
    grade = serializers.CharField(source='class_grade', read_only=True)
    status = serializers.CharField(read_only=True)
    locationStatus = serializers.CharField(source='location_status', read_only=True)
    address = serializers.CharField(read_only=True)
    emergencyContact = serializers.CharField(source='emergency_contact', read_only=True)
    medicalInfo = serializers.CharField(source='medical_info', read_only=True)
    parentId = serializers.IntegerField(source='parent.user.id', read_only=True)
    parentName = serializers.SerializerMethodField()
    assignedBusId = serializers.SerializerMethodField()
    assignedBusNumber = serializers.SerializerMethodField()
    driverName = serializers.SerializerMethodField()
    route = serializers.SerializerMethodField()

    class Meta:
        model = Child
        fields = [
            'id', 'firstName', 'lastName', 'grade', 'age', 'status', 'locationStatus',
            'address', 'emergencyContact', 'medicalInfo',
            'parentId', 'parentName', 'assignedBusId', 'assignedBusNumber', 'driverName', 'route'
        ]

    def get_parentName(self, obj):
        if obj.parent and obj.parent.user:
            return f"{obj.parent.user.first_name} {obj.parent.user.last_name}"
        return None

    def get_assignedBusId(self, obj):
        """Get assigned bus ID from Assignment API"""
        assignment = Assignment.get_active_assignments_for(obj, 'child_to_bus').first()
        return assignment.assigned_to.id if assignment and assignment.assigned_to else None

    def get_assignedBusNumber(self, obj):
        """Get assigned bus number from Assignment API"""
        assignment = Assignment.get_active_assignments_for(obj, 'child_to_bus').first()
        return assignment.assigned_to.bus_number if assignment and assignment.assigned_to else None

    def get_driverName(self, obj):
        """Get driver name from bus assignment"""
        from assignments.models import Assignment
        child_bus_assignment = Assignment.get_active_assignments_for(obj, 'child_to_bus').first()
        if child_bus_assignment and child_bus_assignment.assigned_to:
            bus = child_bus_assignment.assigned_to
            driver_assignment = Assignment.get_assignments_to(bus, 'driver_to_bus').first()
            if driver_assignment and driver_assignment.assignee:
                driver = driver_assignment.assignee
                user = driver.user
                return f"{user.first_name} {user.last_name}" if user.first_name else user.username
        return None

    def get_route(self, obj):
        """Get route name from bus assignment

        TODO: Implement proper Routes model and link it to buses
        For now, returns None until Routes system is implemented
        """
        # from assignments.models import Assignment
        # assignment = Assignment.get_active_assignments_for(obj, 'child_to_bus').first()
        # if assignment and assignment.assigned_to:
        #     # Get route from bus.route field once implemented
        #     return assignment.assigned_to.route_name
        return None


class ChildCreateSerializer(serializers.Serializer):
    """For POST/PUT requests - validates input"""
    firstName = serializers.CharField(write_only=True)
    lastName = serializers.CharField(write_only=True)
    grade = serializers.CharField(write_only=True)
    age = serializers.IntegerField(required=False, allow_null=True, write_only=True)
    status = serializers.ChoiceField(
        choices=['active', 'inactive'],
        default='active',
        write_only=True,
        help_text="Enrollment status"
    )
    locationStatus = serializers.ChoiceField(
        choices=['home', 'at-school', 'on-bus', 'picked-up', 'dropped-off'],
        default='home',
        required=False,
        write_only=True,
        help_text="Current location/tracking status"
    )
    address = serializers.CharField(
        required=False,
        allow_blank=True,
        write_only=True,
        help_text="Child's address (optional, inherits from parent if not provided)"
    )
    emergencyContact = serializers.CharField(
        required=False,
        allow_blank=True,
        write_only=True,
        help_text="Emergency contact (optional, inherits from parent if not provided)"
    )
    medicalInfo = serializers.CharField(
        required=False,
        allow_blank=True,
        write_only=True,
        help_text="Medical information"
    )
    parentId = serializers.IntegerField(write_only=True)
    assignedBusId = serializers.IntegerField(required=False, allow_null=True, write_only=True)

    def create(self, validated_data):
        from parents.models import Parent
        from buses.models import Bus

        # Get parent
        parent_id = validated_data.pop('parentId')
        try:
            parent = Parent.objects.get(user_id=parent_id)
        except Parent.DoesNotExist:
            raise serializers.ValidationError({"parentId": "Parent not found"})

        # Get bus if provided
        bus_id = validated_data.pop('assignedBusId', None)

        # Auto-inherit address from parent if not provided
        address = validated_data.get('address', '').strip()
        if not address:
            address = parent.address or ''

        # Auto-inherit emergency contact from parent if not provided
        emergency_contact = validated_data.get('emergencyContact', '').strip()
        if not emergency_contact:
            emergency_contact = parent.emergency_contact or ''

        # Create Child (without assigned_bus - will use Assignment API)
        child = Child.objects.create(
            first_name=validated_data.get('firstName'),
            last_name=validated_data.get('lastName'),
            class_grade=validated_data.get('grade'),
            age=validated_data.get('age'),
            status=validated_data.get('status', 'active'),
            location_status=validated_data.get('locationStatus', 'home'),
            address=address,
            emergency_contact=emergency_contact,
            medical_info=validated_data.get('medicalInfo', ''),
            parent=parent
        )

        # Assign to bus using Assignment API
        if bus_id:
            from assignments.services import AssignmentService
            try:
                bus = Bus.objects.get(id=bus_id)
                AssignmentService.create_assignment(
                    assignment_type='child_to_bus',
                    assignee=child,
                    assigned_to=bus,
                    assigned_by=None,  # System assignment
                    reason="Created via child creation",
                    auto_cancel_conflicting=True
                )
            except Bus.DoesNotExist:
                raise serializers.ValidationError({"assignedBusId": "Bus not found"})

        return child

    def update(self, instance, validated_data):
        from parents.models import Parent
        from buses.models import Bus

        # Update basic fields
        if 'firstName' in validated_data:
            instance.first_name = validated_data.pop('firstName')
        if 'lastName' in validated_data:
            instance.last_name = validated_data.pop('lastName')
        if 'grade' in validated_data:
            instance.class_grade = validated_data.pop('grade')
        if 'age' in validated_data:
            instance.age = validated_data.pop('age')
        if 'status' in validated_data:
            instance.status = validated_data.pop('status')
        if 'locationStatus' in validated_data:
            instance.location_status = validated_data.pop('locationStatus')
        if 'address' in validated_data:
            instance.address = validated_data.pop('address')
        if 'emergencyContact' in validated_data:
            instance.emergency_contact = validated_data.pop('emergencyContact')
        if 'medicalInfo' in validated_data:
            instance.medical_info = validated_data.pop('medicalInfo')

        # Update parent
        if 'parentId' in validated_data:
            parent_id = validated_data.pop('parentId')
            try:
                parent = Parent.objects.get(user_id=parent_id)
                instance.parent = parent
            except Parent.DoesNotExist:
                raise serializers.ValidationError({"parentId": "Parent not found"})

        # Update bus using Assignment API
        if 'assignedBusId' in validated_data:
            bus_id = validated_data.pop('assignedBusId')
            from assignments.services import AssignmentService

            if bus_id:
                # Assign to new bus
                try:
                    bus = Bus.objects.get(id=bus_id)
                    AssignmentService.create_assignment(
                        assignment_type='child_to_bus',
                        assignee=instance,
                        assigned_to=bus,
                        assigned_by=None,  # System assignment
                        reason="Updated via child edit",
                        auto_cancel_conflicting=True  # This will cancel old assignments
                    )
                except Bus.DoesNotExist:
                    raise serializers.ValidationError({"assignedBusId": "Bus not found"})
            else:
                # Cancel existing bus assignment
                existing_assignment = Assignment.get_active_assignments_for(instance, 'child_to_bus').first()
                if existing_assignment:
                    existing_assignment.status = 'cancelled'
                    existing_assignment.save()

        instance.save()
        return instance

    def to_representation(self, instance):
        # Return the full ChildSerializer representation
        return ChildSerializer(instance).data
