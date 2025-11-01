from django.db import models
from django.conf import settings
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.core.exceptions import ValidationError
from django.utils import timezone


class BusRoute(models.Model):
    """
    Represents a predefined bus route with default assignments and schedule.
    Routes define the standard path and stops for regular transportation.
    """

    # Basic route information
    name = models.CharField(
        max_length=100,
        help_text="Route name (e.g., 'Route A - Downtown Elementary')"
    )
    route_code = models.CharField(
        max_length=20,
        unique=True,
        help_text="Unique route identifier (e.g., 'ROUTE_A')"
    )
    description = models.TextField(
        blank=True,
        help_text="Detailed description of the route"
    )

    # Default assignments
    default_bus = models.ForeignKey(
        'buses.Bus',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='default_routes',
        help_text="Default bus assigned to this route"
    )
    default_driver = models.ForeignKey(
        'drivers.Driver',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='default_routes',
        help_text="Default driver assigned to this route"
    )
    default_minder = models.ForeignKey(
        'busminders.BusMinder',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='default_routes',
        help_text="Default bus minder assigned to this route"
    )

    # Schedule configuration
    schedule = models.JSONField(
        default=dict,
        blank=True,
        help_text="Route schedule with pickup/dropoff times in JSON format"
    )

    # Route details
    estimated_duration = models.IntegerField(
        null=True,
        blank=True,
        help_text="Estimated route duration in minutes"
    )
    total_distance = models.FloatField(
        null=True,
        blank=True,
        help_text="Total route distance in kilometers"
    )

    # Status
    is_active = models.BooleanField(
        default=True,
        help_text="Is this route currently active?"
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Bus Route"
        verbose_name_plural = "Bus Routes"
        ordering = ['route_code']

    def __str__(self):
        return f"{self.route_code} - {self.name}"

    def get_active_assignments(self):
        """Get all active assignments for this route"""
        return Assignment.objects.filter(
            assigned_to_content_type=ContentType.objects.get_for_model(BusRoute),
            assigned_to_object_id=self.id,
            status='active',
            effective_date__lte=timezone.now().date()
        ).filter(
            models.Q(expiry_date__isnull=True) |
            models.Q(expiry_date__gte=timezone.now().date())
        )


class Assignment(models.Model):
    """
    Unified assignment model supporting multiple assignment types using GenericForeignKey.
    Tracks who is assigned to what, when, and by whom, with full audit trail.

    Supported assignment types:
    - driver_to_bus: Driver assigned to Bus
    - minder_to_bus: BusMinder assigned to Bus
    - child_to_bus: Child assigned to Bus
    - bus_to_route: Bus assigned to Route
    - driver_to_route: Driver assigned to Route
    - minder_to_route: BusMinder assigned to Route
    - child_to_route: Child assigned to Route
    """

    ASSIGNMENT_TYPES = [
        ('driver_to_bus', 'Driver to Bus'),
        ('minder_to_bus', 'Bus Minder to Bus'),
        ('child_to_bus', 'Child to Bus'),
        ('bus_to_route', 'Bus to Route'),
        ('driver_to_route', 'Driver to Route'),
        ('minder_to_route', 'Bus Minder to Route'),
        ('child_to_route', 'Child to Route'),
    ]

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
        ('pending', 'Pending'),
    ]

    # Assignment type
    assignment_type = models.CharField(
        max_length=20,
        choices=ASSIGNMENT_TYPES,
        help_text="Type of assignment being made"
    )

    # Who is being assigned (Generic FK)
    assignee_content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        related_name='assignee_assignments',
        help_text="Type of entity being assigned (Driver, Child, Bus, etc.)"
    )
    assignee_object_id = models.PositiveIntegerField(
        help_text="ID of the entity being assigned"
    )
    assignee = GenericForeignKey('assignee_content_type', 'assignee_object_id')

    # What they're assigned to (Generic FK)
    assigned_to_content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        related_name='assigned_to_assignments',
        help_text="Type of entity being assigned to (Bus, Route, etc.)"
    )
    assigned_to_object_id = models.PositiveIntegerField(
        help_text="ID of the entity being assigned to"
    )
    assigned_to = GenericForeignKey('assigned_to_content_type', 'assigned_to_object_id')

    # Time-based assignment
    effective_date = models.DateField(
        default=timezone.now,
        help_text="When this assignment becomes effective"
    )
    expiry_date = models.DateField(
        null=True,
        blank=True,
        help_text="When this assignment expires (null = permanent)"
    )

    # Audit trail
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='assignments_made',
        help_text="User who made this assignment"
    )
    assigned_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When this assignment was created"
    )

    # Status and metadata
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='active',
        help_text="Current status of this assignment"
    )
    reason = models.TextField(
        blank=True,
        help_text="Reason for this assignment"
    )
    notes = models.TextField(
        blank=True,
        help_text="Additional notes about this assignment"
    )
    metadata = models.JSONField(
        default=dict,
        blank=True,
        help_text="Additional metadata in JSON format"
    )

    # Tracking
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Assignment"
        verbose_name_plural = "Assignments"
        ordering = ['-assigned_at']
        indexes = [
            models.Index(fields=['assignment_type', 'status']),
            models.Index(fields=['effective_date', 'expiry_date']),
            models.Index(fields=['assignee_content_type', 'assignee_object_id']),
            models.Index(fields=['assigned_to_content_type', 'assigned_to_object_id']),
        ]

    def __str__(self):
        return f"{self.assignment_type}: {self.assignee} → {self.assigned_to} ({self.status})"

    def clean(self):
        """Validate assignment logic"""
        super().clean()

        # Validate expiry date is after effective date
        if self.expiry_date and self.effective_date:
            if self.expiry_date < self.effective_date:
                raise ValidationError({
                    'expiry_date': 'Expiry date must be after effective date'
                })

        # Validate assignment type matches content types
        self._validate_assignment_type()

    def _validate_assignment_type(self):
        """Validate that assignment_type matches the actual content types"""
        type_mapping = {
            'driver_to_bus': ('drivers.Driver', 'buses.Bus'),
            'minder_to_bus': ('busminders.BusMinder', 'buses.Bus'),
            'child_to_bus': ('children.Child', 'buses.Bus'),
            'bus_to_route': ('buses.Bus', 'assignments.BusRoute'),
            'driver_to_route': ('drivers.Driver', 'assignments.BusRoute'),
            'minder_to_route': ('busminders.BusMinder', 'assignments.BusRoute'),
            'child_to_route': ('children.Child', 'assignments.BusRoute'),
        }

        if self.assignment_type in type_mapping:
            expected_assignee, expected_assigned_to = type_mapping[self.assignment_type]

            actual_assignee = f"{self.assignee_content_type.app_label}.{self.assignee_content_type.model}"
            actual_assigned_to = f"{self.assigned_to_content_type.app_label}.{self.assigned_to_content_type.model}"

            if actual_assignee.lower() != expected_assignee.lower():
                raise ValidationError({
                    'assignee_content_type': f'For {self.assignment_type}, assignee must be {expected_assignee}'
                })

            if actual_assigned_to.lower() != expected_assigned_to.lower():
                raise ValidationError({
                    'assigned_to_content_type': f'For {self.assignment_type}, assigned_to must be {expected_assigned_to}'
                })

    def is_currently_active(self):
        """Check if assignment is currently active based on dates and status"""
        if self.status != 'active':
            return False

        today = timezone.now().date()

        # Check if effective
        if self.effective_date > today:
            return False

        # Check if expired
        if self.expiry_date and self.expiry_date < today:
            return False

        return True

    def cancel(self, cancelled_by=None, reason=""):
        """Cancel this assignment"""
        self.status = 'cancelled'
        if reason:
            self.notes = f"{self.notes}\nCancelled: {reason}" if self.notes else f"Cancelled: {reason}"
        self.save()

    def expire(self):
        """Mark assignment as expired"""
        self.status = 'expired'
        self.save()

    @classmethod
    def get_active_assignments_for(cls, entity, assignment_type=None):
        """
        Get all active assignments for a given entity.

        Args:
            entity: The model instance (Driver, Child, Bus, etc.)
            assignment_type: Optional filter by assignment type

        Returns:
            QuerySet of active assignments
        """
        content_type = ContentType.objects.get_for_model(entity)
        today = timezone.now().date()

        filters = {
            'assignee_content_type': content_type,
            'assignee_object_id': entity.pk,
            'status': 'active',
            'effective_date__lte': today,
        }

        if assignment_type:
            filters['assignment_type'] = assignment_type

        return cls.objects.filter(**filters).filter(
            models.Q(expiry_date__isnull=True) |
            models.Q(expiry_date__gte=today)
        )

    @classmethod
    def get_assignments_to(cls, entity, assignment_type=None):
        """
        Get all active assignments TO a given entity.

        Args:
            entity: The model instance (Bus, Route, etc.)
            assignment_type: Optional filter by assignment type

        Returns:
            QuerySet of active assignments
        """
        content_type = ContentType.objects.get_for_model(entity)
        today = timezone.now().date()

        filters = {
            'assigned_to_content_type': content_type,
            'assigned_to_object_id': entity.pk,
            'status': 'active',
            'effective_date__lte': today,
        }

        if assignment_type:
            filters['assignment_type'] = assignment_type

        return cls.objects.filter(**filters).filter(
            models.Q(expiry_date__isnull=True) |
            models.Q(expiry_date__gte=today)
        )


class AssignmentHistory(models.Model):
    """
    Logs all changes to assignments for audit trail purposes.
    Automatically created via signals when assignments are modified.
    """

    assignment = models.ForeignKey(
        Assignment,
        on_delete=models.CASCADE,
        related_name='history',
        help_text="The assignment this history entry refers to"
    )

    action = models.CharField(
        max_length=20,
        choices=[
            ('created', 'Created'),
            ('updated', 'Updated'),
            ('cancelled', 'Cancelled'),
            ('expired', 'Expired'),
        ],
        help_text="Action performed on the assignment"
    )

    performed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        help_text="User who performed this action"
    )

    performed_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When this action was performed"
    )

    changes = models.JSONField(
        default=dict,
        help_text="Details of what changed"
    )

    notes = models.TextField(
        blank=True,
        help_text="Additional notes about this change"
    )

    class Meta:
        verbose_name = "Assignment History"
        verbose_name_plural = "Assignment Histories"
        ordering = ['-performed_at']

    def __str__(self):
        return f"{self.action} - {self.assignment} at {self.performed_at}"
