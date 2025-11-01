"""
Validators for assignment business rules and constraints.
"""

from django.core.exceptions import ValidationError
from django.utils import timezone
from .models import Assignment


class AssignmentValidator:
    """Validator class for assignment business rules"""

    @staticmethod
    def validate_bus_capacity(bus, additional_children=1):
        """
        Validate that adding children won't exceed bus capacity.

        Args:
            bus: Bus instance
            additional_children: Number of children to add

        Raises:
            ValidationError: If capacity would be exceeded
        """
        current_count = Assignment.get_assignments_to(bus, 'child_to_bus').count()
        total = current_count + additional_children

        if total > bus.capacity:
            raise ValidationError(
                f"Bus capacity exceeded. Capacity: {bus.capacity}, "
                f"Current: {current_count}, Attempting to add: {additional_children}"
            )

    @staticmethod
    def validate_driver_availability(driver, effective_date, expiry_date=None):
        """
        Validate that driver is not already assigned to another bus in the same period.

        Args:
            driver: Driver instance
            effective_date: Start date of assignment
            expiry_date: End date of assignment (None = permanent)

        Raises:
            ValidationError: If driver is already assigned
        """
        from django.db.models import Q

        # Check for overlapping assignments
        existing = Assignment.objects.filter(
            assignee_content_type__model='driver',
            assignee_object_id=driver.pk,
            assignment_type__in=['driver_to_bus', 'driver_to_route'],
            status='active'
        )

        if expiry_date:
            existing = existing.filter(
                Q(effective_date__lte=expiry_date, expiry_date__gte=effective_date) |
                Q(effective_date__lte=expiry_date, expiry_date__isnull=True)
            )
        else:
            existing = existing.filter(
                Q(effective_date__lte=effective_date) &
                (Q(expiry_date__gte=effective_date) | Q(expiry_date__isnull=True))
            )

        if existing.exists():
            assignments = ", ".join([
                f"{a.assigned_to} ({a.effective_date} to {a.expiry_date or 'permanent'})"
                for a in existing
            ])
            raise ValidationError(
                f"Driver already assigned during this period: {assignments}"
            )

    @staticmethod
    def validate_minder_availability(minder, effective_date, expiry_date=None):
        """
        Validate that bus minder is not already assigned to another bus in the same period.

        Args:
            minder: BusMinder instance
            effective_date: Start date of assignment
            expiry_date: End date of assignment (None = permanent)

        Raises:
            ValidationError: If minder is already assigned
        """
        from django.db.models import Q

        existing = Assignment.objects.filter(
            assignee_content_type__model='busminder',
            assignee_object_id=minder.pk,
            assignment_type__in=['minder_to_bus', 'minder_to_route'],
            status='active'
        )

        if expiry_date:
            existing = existing.filter(
                Q(effective_date__lte=expiry_date, expiry_date__gte=effective_date) |
                Q(effective_date__lte=expiry_date, expiry_date__isnull=True)
            )
        else:
            existing = existing.filter(
                Q(effective_date__lte=effective_date) &
                (Q(expiry_date__gte=effective_date) | Q(expiry_date__isnull=True))
            )

        if existing.exists():
            assignments = ", ".join([
                f"{a.assigned_to} ({a.effective_date} to {a.expiry_date or 'permanent'})"
                for a in existing
            ])
            raise ValidationError(
                f"Bus minder already assigned during this period: {assignments}"
            )

    @staticmethod
    def validate_child_not_already_assigned(child, effective_date, expiry_date=None):
        """
        Validate that child is not already assigned to a bus or route in the same period.

        Args:
            child: Child instance
            effective_date: Start date of assignment
            expiry_date: End date of assignment (None = permanent)

        Raises:
            ValidationError: If child is already assigned
        """
        from django.db.models import Q

        existing = Assignment.objects.filter(
            assignee_content_type__model='child',
            assignee_object_id=child.pk,
            assignment_type__in=['child_to_bus', 'child_to_route'],
            status='active'
        )

        if expiry_date:
            existing = existing.filter(
                Q(effective_date__lte=expiry_date, expiry_date__gte=effective_date) |
                Q(effective_date__lte=expiry_date, expiry_date__isnull=True)
            )
        else:
            existing = existing.filter(
                Q(effective_date__lte=effective_date) &
                (Q(expiry_date__gte=effective_date) | Q(expiry_date__isnull=True))
            )

        if existing.exists():
            assignments = ", ".join([
                f"{a.assigned_to} ({a.effective_date} to {a.expiry_date or 'permanent'})"
                for a in existing
            ])
            raise ValidationError(
                f"Child already assigned during this period: {assignments}"
            )

    @staticmethod
    def validate_date_range(effective_date, expiry_date):
        """
        Validate that date range is logical.

        Args:
            effective_date: Start date
            expiry_date: End date (can be None)

        Raises:
            ValidationError: If dates are invalid
        """
        if expiry_date and effective_date:
            if expiry_date < effective_date:
                raise ValidationError("Expiry date must be after effective date")

        if effective_date < timezone.now().date():
            raise ValidationError("Cannot create assignment with past effective date")

    @staticmethod
    def validate_entity_status(entity):
        """
        Validate that entity is in active status and can be assigned.

        Args:
            entity: Model instance (Driver, Child, etc.)

        Raises:
            ValidationError: If entity is not active
        """
        # Check if entity has a status field
        if hasattr(entity, 'status'):
            if entity.status != 'active':
                raise ValidationError(
                    f"{entity.__class__.__name__} is not active (status: {entity.status})"
                )

    @staticmethod
    def validate_route_has_bus(route):
        """
        Validate that route has a default bus assigned.

        Args:
            route: BusRoute instance

        Raises:
            ValidationError: If route has no bus
        """
        if not route.default_bus:
            raise ValidationError("Route must have a default bus assigned")

    @staticmethod
    def validate_assignment_type_compatibility(assignment_type, assignee, assigned_to):
        """
        Validate that assignment type matches the actual entities.

        Args:
            assignment_type: Type string (e.g., 'driver_to_bus')
            assignee: Entity being assigned
            assigned_to: Entity being assigned to

        Raises:
            ValidationError: If types don't match
        """
        from buses.models import Bus
        from drivers.models import Driver
        from busminders.models import BusMinder
        from children.models import Child
        from .models import BusRoute

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
            raise ValidationError(f"Invalid assignment type: {assignment_type}")

        expected_assignee_type, expected_assigned_to_type = type_mapping[assignment_type]

        if not isinstance(assignee, expected_assignee_type):
            raise ValidationError(
                f"For {assignment_type}, assignee must be {expected_assignee_type.__name__}, "
                f"got {assignee.__class__.__name__}"
            )

        if not isinstance(assigned_to, expected_assigned_to_type):
            raise ValidationError(
                f"For {assignment_type}, assigned_to must be {expected_assigned_to_type.__name__}, "
                f"got {assigned_to.__class__.__name__}"
            )

    @staticmethod
    def validate_full_assignment(assignment_type, assignee, assigned_to, effective_date, expiry_date=None):
        """
        Run all relevant validations for an assignment.

        Args:
            assignment_type: Type of assignment
            assignee: Entity being assigned
            assigned_to: Entity being assigned to
            effective_date: Start date
            expiry_date: End date (optional)

        Raises:
            ValidationError: If any validation fails
        """
        from buses.models import Bus
        from drivers.models import Driver
        from busminders.models import BusMinder
        from children.models import Child

        # Validate type compatibility
        AssignmentValidator.validate_assignment_type_compatibility(
            assignment_type, assignee, assigned_to
        )

        # Validate date range
        AssignmentValidator.validate_date_range(effective_date, expiry_date)

        # Validate entity statuses
        AssignmentValidator.validate_entity_status(assignee)
        if hasattr(assigned_to, 'is_active'):
            if not assigned_to.is_active:
                raise ValidationError(
                    f"{assigned_to.__class__.__name__} is not active"
                )

        # Type-specific validations
        if isinstance(assignee, Driver):
            AssignmentValidator.validate_driver_availability(assignee, effective_date, expiry_date)

        if isinstance(assignee, BusMinder):
            AssignmentValidator.validate_minder_availability(assignee, effective_date, expiry_date)

        if isinstance(assignee, Child):
            AssignmentValidator.validate_child_not_already_assigned(assignee, effective_date, expiry_date)
            # If assigning to bus, check capacity
            if isinstance(assigned_to, Bus):
                AssignmentValidator.validate_bus_capacity(assigned_to, 1)
