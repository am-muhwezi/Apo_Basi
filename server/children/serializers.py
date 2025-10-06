from rest_framework import serializers
from .models import Child


class ChildSerializer(serializers.ModelSerializer):
    """For GET requests - includes all data with relationships"""
    firstName = serializers.CharField(source='first_name', read_only=True)
    lastName = serializers.CharField(source='last_name', read_only=True)
    grade = serializers.CharField(source='class_grade', read_only=True)
    parentId = serializers.IntegerField(source='parent.user.id', read_only=True)
    parentName = serializers.SerializerMethodField()
    assignedBusId = serializers.IntegerField(source='assigned_bus.id', read_only=True, allow_null=True)
    assignedBusNumber = serializers.CharField(source='assigned_bus.bus_number', read_only=True, allow_null=True)

    class Meta:
        model = Child
        fields = [
            'id', 'firstName', 'lastName', 'grade', 'age', 'status',
            'parentId', 'parentName', 'assignedBusId', 'assignedBusNumber'
        ]

    def get_parentName(self, obj):
        if obj.parent and obj.parent.user:
            return f"{obj.parent.user.first_name} {obj.parent.user.last_name}"
        return None


class ChildCreateSerializer(serializers.Serializer):
    """For POST/PUT requests - validates input"""
    firstName = serializers.CharField(write_only=True)
    lastName = serializers.CharField(write_only=True)
    grade = serializers.CharField(write_only=True)
    age = serializers.IntegerField(required=False, allow_null=True, write_only=True)
    status = serializers.ChoiceField(choices=['active', 'inactive'], default='active', write_only=True)
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
        bus = None
        if bus_id:
            try:
                bus = Bus.objects.get(id=bus_id)
            except Bus.DoesNotExist:
                raise serializers.ValidationError({"assignedBusId": "Bus not found"})

        # Create Child
        child = Child.objects.create(
            first_name=validated_data.get('firstName'),
            last_name=validated_data.get('lastName'),
            class_grade=validated_data.get('grade'),
            age=validated_data.get('age'),
            status=validated_data.get('status', 'active'),
            parent=parent,
            assigned_bus=bus
        )

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

        # Update parent
        if 'parentId' in validated_data:
            parent_id = validated_data.pop('parentId')
            try:
                parent = Parent.objects.get(user_id=parent_id)
                instance.parent = parent
            except Parent.DoesNotExist:
                raise serializers.ValidationError({"parentId": "Parent not found"})

        # Update bus
        if 'assignedBusId' in validated_data:
            bus_id = validated_data.pop('assignedBusId')
            if bus_id:
                try:
                    bus = Bus.objects.get(id=bus_id)
                    instance.assigned_bus = bus
                except Bus.DoesNotExist:
                    raise serializers.ValidationError({"assignedBusId": "Bus not found"})
            else:
                instance.assigned_bus = None

        instance.save()
        return instance

    def to_representation(self, instance):
        # Return the full ChildSerializer representation
        return ChildSerializer(instance).data
