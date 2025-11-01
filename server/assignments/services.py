"""
Assignment service layer for business logic and complex operations.
"""

from django.contrib.contenttypes.models import ContentType
from django.db import transaction
from django.utils import timezone
from django.core.exceptions import ValidationError

from .models import Assignment, BusRoute, AssignmentHistory
from buses.models import Bus
from drivers.models import Driver
from busminders.models import BusMinder
from children.models import Child


class AssignmentService:
    """Service class for handling assignment operations"""

    @staticmethod
    def create_assignment(
        assignment_type,
        assignee,
        assigned_to,
        assigned_by=None,
        effective_date=None,
        expiry_date=None,
        reason="",
        notes="",
        metadata=None,
        auto_cancel_conflicting=False
    ):
        """
        Create a new assignment with validation and conflict handling.

        Args:
            assignment_type: Type of assignment (e.g., 'driver_to_bus')
            assignee: The entity being assigned (Driver, Child, etc.)
            assigned_to: What they're being assigned to (Bus, Route, etc.)
            assigned_by: User creating the assignment
            effective_date: When assignment starts (defaults to today)
            expiry_date: When assignment ends (None = permanent)
            reason: Why this assignment is being made
            notes: Additional notes
            metadata: JSON metadata
            auto_cancel_conflicting: If True, cancel conflicting assignments

        Returns:
            Assignment instance

        Raises:
            ValidationError: If assignment is invalid or conflicts exist
        """
        if effective_date is None:
            effective_date = timezone.now().date()

        if metadata is None:
            metadata = {}

        # Get content types
        assignee_ct = ContentType.objects.get_for_model(assignee)
        assigned_to_ct = ContentType.objects.get_for_model(assigned_to)

        # Check for conflicts
        conflicts = AssignmentService.check_conflicts(
            assignment_type=assignment_type,
            assignee=assignee,
            assigned_to=assigned_to,
            effective_date=effective_date,
            expiry_date=expiry_date
        )

        if conflicts:
            if auto_cancel_conflicting:
                # Cancel conflicting assignments
                for conflict in conflicts:
                    conflict.cancel(
                        cancelled_by=assigned_by,
                        reason=f"Cancelled due to new assignment created on {timezone.now().date()}"
                    )
            else:
                # Raise error with conflict details
                conflict_details = [
                    f"Assignment #{c.id}: {c.assignee} → {c.assigned_to} ({c.effective_date} to {c.expiry_date or 'permanent'})"
                    for c in conflicts
                ]
                raise ValidationError({
                    'conflicts': f"Conflicting assignments found: {'; '.join(conflict_details)}"
                })

        # Create assignment
        with transaction.atomic():
            assignment = Assignment.objects.create(
                assignment_type=assignment_type,
                assignee_content_type=assignee_ct,
                assignee_object_id=assignee.pk,
                assigned_to_content_type=assigned_to_ct,
                assigned_to_object_id=assigned_to.pk,
                effective_date=effective_date,
                expiry_date=expiry_date,
                assigned_by=assigned_by,
                status='active',
                reason=reason,
                notes=notes,
                metadata=metadata
            )

            # Create history entry
            AssignmentHistory.objects.create(
                assignment=assignment,
                action='created',
                performed_by=assigned_by,
                changes={
                    'assignment_type': assignment_type,
                    'assignee': str(assignee),
                    'assigned_to': str(assigned_to),
                    'effective_date': str(effective_date),
                    'expiry_date': str(expiry_date) if expiry_date else None
                },
                notes=f"Assignment created: {reason}"
            )

        return assignment

    @staticmethod
    def check_conflicts(assignment_type, assignee, assigned_to, effective_date, expiry_date=None):
        """
        Check for conflicting assignments.

        Conflicts occur when:
        1. Same assignee is already assigned to a different entity of same type
           during the same time period
        2. For buses: exceeding capacity

        Returns:
            QuerySet of conflicting assignments
        """
        from django.db.models import Q

        assignee_ct = ContentType.objects.get_for_model(assignee)
        assigned_to_ct = ContentType.objects.get_for_model(assigned_to)

        # Build date range query
        if expiry_date:
            # New assignment has expiry date
            date_conflict = (
                Q(effective_date__lte=expiry_date, expiry_date__gte=effective_date) |
                Q(effective_date__lte=expiry_date, expiry_date__isnull=True)
            )
        else:
            # New assignment is permanent
            date_conflict = (
                Q(effective_date__lte=effective_date) &
                (Q(expiry_date__gte=effective_date) | Q(expiry_date__isnull=True))
            ) | Q(effective_date__gte=effective_date)

        # Find same assignee assigned to different entity of same type
        conflicts = Assignment.objects.filter(
            assignment_type=assignment_type,
            assignee_content_type=assignee_ct,
            assignee_object_id=assignee.pk,
            assigned_to_content_type=assigned_to_ct,
            status='active'
        ).exclude(
            assigned_to_object_id=assigned_to.pk
        ).filter(date_conflict)

        return conflicts

    @staticmethod
    def bulk_assign_children_to_bus(bus, children_ids, assigned_by=None, effective_date=None):
        """
        Bulk assign multiple children to a bus with capacity validation.

        Args:
            bus: Bus instance
            children_ids: List of child IDs
            assigned_by: User making assignments
            effective_date: When assignments start

        Returns:
            List of created Assignment instances

        Raises:
            ValidationError: If capacity exceeded or children don't exist
        """
        if effective_date is None:
            effective_date = timezone.now().date()

        # Get children
        children = Child.objects.filter(id__in=children_ids)

        if len(children) != len(children_ids):
            raise ValidationError({
                'children': 'One or more children not found'
            })

        # Check capacity
        current_assignments = Assignment.get_assignments_to(bus, 'child_to_bus').count()
        total_after_assignment = current_assignments + len(children)

        if total_after_assignment > bus.capacity:
            raise ValidationError({
                'capacity': f'Bus capacity ({bus.capacity}) exceeded. Current: {current_assignments}, Attempting to add: {len(children)}'
            })

        # Create assignments
        assignments = []
        with transaction.atomic():
            for child in children:
                assignment = AssignmentService.create_assignment(
                    assignment_type='child_to_bus',
                    assignee=child,
                    assigned_to=bus,
                    assigned_by=assigned_by,
                    effective_date=effective_date,
                    reason=f"Bulk assignment to bus {bus.bus_number}",
                    auto_cancel_conflicting=True
                )
                assignments.append(assignment)

        return assignments

    @staticmethod
    def bulk_assign_children_to_route(route, children_ids, assigned_by=None, effective_date=None):
        """
        Bulk assign multiple children to a route.

        Args:
            route: BusRoute instance
            children_ids: List of child IDs
            assigned_by: User making assignments
            effective_date: When assignments start

        Returns:
            List of created Assignment instances
        """
        if effective_date is None:
            effective_date = timezone.now().date()

        # Get children
        children = Child.objects.filter(id__in=children_ids)

        if len(children) != len(children_ids):
            raise ValidationError({
                'children': 'One or more children not found'
            })

        # Create assignments
        assignments = []
        with transaction.atomic():
            for child in children:
                assignment = AssignmentService.create_assignment(
                    assignment_type='child_to_route',
                    assignee=child,
                    assigned_to=route,
                    assigned_by=assigned_by,
                    effective_date=effective_date,
                    reason=f"Bulk assignment to route {route.route_code}",
                    auto_cancel_conflicting=True
                )
                assignments.append(assignment)

        return assignments

    @staticmethod
    def get_entity_current_assignments(entity):
        """
        Get all current active assignments for an entity.

        Args:
            entity: Model instance (Driver, Child, Bus, etc.)

        Returns:
            Dict with assignments as assignee and assignments as assigned_to
        """
        return {
            'as_assignee': Assignment.get_active_assignments_for(entity),
            'as_assigned_to': Assignment.get_assignments_to(entity)
        }

    @staticmethod
    def transfer_assignment(assignment, new_assigned_to, assigned_by=None, reason=""):
        """
        Transfer an assignment to a new entity (e.g., move child from one bus to another).

        Args:
            assignment: Existing Assignment instance
            new_assigned_to: New entity to assign to
            assigned_by: User making the transfer
            reason: Reason for transfer

        Returns:
            New Assignment instance
        """
        with transaction.atomic():
            # Cancel old assignment
            assignment.cancel(
                cancelled_by=assigned_by,
                reason=f"Transferred to {new_assigned_to}. {reason}"
            )

            # Create new assignment
            new_assignment = AssignmentService.create_assignment(
                assignment_type=assignment.assignment_type,
                assignee=assignment.assignee,
                assigned_to=new_assigned_to,
                assigned_by=assigned_by,
                effective_date=timezone.now().date(),
                reason=f"Transfer from {assignment.assigned_to}. {reason}",
                metadata={'transferred_from_assignment_id': assignment.id}
            )

        return new_assignment

    @staticmethod
    def expire_old_assignments():
        """
        Expire assignments that have passed their expiry date.
        Should be run as a scheduled task (e.g., daily cron job).

        Returns:
            Number of assignments expired
        """
        today = timezone.now().date()

        expired_assignments = Assignment.objects.filter(
            status='active',
            expiry_date__lt=today
        )

        count = 0
        with transaction.atomic():
            for assignment in expired_assignments:
                assignment.expire()
                AssignmentHistory.objects.create(
                    assignment=assignment,
                    action='expired',
                    performed_by=None,
                    changes={'status': 'expired'},
                    notes='Automatically expired by system'
                )
                count += 1

        return count

    @staticmethod
    def get_route_statistics(route):
        """
        Get statistics for a route including assignments and capacity.

        Args:
            route: BusRoute instance

        Returns:
            Dict with route statistics
        """
        active_assignments = route.get_active_assignments()

        # Count by assignment type
        stats = {
            'route_id': route.id,
            'route_code': route.route_code,
            'route_name': route.name,
            'is_active': route.is_active,
            'total_assignments': active_assignments.count(),
            'drivers': active_assignments.filter(assignment_type='driver_to_route').count(),
            'minders': active_assignments.filter(assignment_type='minder_to_route').count(),
            'children': active_assignments.filter(assignment_type='child_to_route').count(),
            'buses': active_assignments.filter(assignment_type='bus_to_route').count(),
            'default_bus': route.default_bus.bus_number if route.default_bus else None,
            'default_driver': f"{route.default_driver.user.first_name} {route.default_driver.user.last_name}" if route.default_driver else None,
            'default_minder': f"{route.default_minder.user.first_name} {route.default_minder.user.last_name}" if route.default_minder else None,
        }

        # Get bus capacity info if default bus exists
        if route.default_bus:
            bus_children = Assignment.get_assignments_to(route.default_bus, 'child_to_bus').count()
            stats['bus_capacity'] = route.default_bus.capacity
            stats['bus_current_occupancy'] = bus_children
            stats['bus_available_seats'] = route.default_bus.capacity - bus_children

        return stats

    @staticmethod
    def get_bus_utilization():
        """
        Get utilization statistics for all buses.

        Returns:
            List of dicts with bus utilization data
        """
        buses = Bus.objects.all()
        utilization = []

        for bus in buses:
            child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus').count()
            utilization.append({
                'bus_id': bus.id,
                'bus_number': bus.bus_number,
                'capacity': bus.capacity,
                'assigned_children': child_assignments,
                'available_seats': bus.capacity - child_assignments,
                'utilization_percentage': round((child_assignments / bus.capacity * 100), 2) if bus.capacity > 0 else 0,
                'driver': f"{bus.driver.first_name} {bus.driver.last_name}" if bus.driver else None,
                'minder': f"{bus.bus_minder.first_name} {bus.bus_minder.last_name}" if bus.bus_minder else None,
            })

        return sorted(utilization, key=lambda x: x['utilization_percentage'], reverse=True)
