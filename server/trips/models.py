from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
from django.contrib.auth import get_user_model
from buses.models import Bus
from drivers.models import Driver
from busminders.models import BusMinder
from children.models import Child

User = get_user_model()


class TripManager(models.Manager):
    def start_trip(self, trip_id):
        trip = self.get(pk=trip_id)
        if not trip.driver:
            raise ValidationError('Trip must have a driver to start')
        if trip.children.count() == 0:
            raise ValidationError('Trip must have at least one child to start')
        if trip.status != 'scheduled':
            raise ValidationError('Trip must be scheduled to start')
        trip.status = 'in-progress'
        trip.start_time = timezone.now()
        trip.save()
        return trip

    def complete_trip(self, trip_id):
        trip = self.get(pk=trip_id)
        if trip.status != 'in-progress':
            raise ValidationError('Trip must be in-progress to be completed')
        trip.status = 'completed'
        trip.end_time = timezone.now()
        if hasattr(trip, 'total_students'):
            trip.total_students = trip.children.count()
        trip.save()
        return trip

    def cancel_trip(self, trip_id):
        trip = self.get(pk=trip_id)
        trip.status = 'cancelled'
        trip.save()
        return trip


class Trip(models.Model):
    """
    Represents a bus trip (pickup or dropoff) with route information and tracking.
    """
    TYPE_CHOICES = [
        ('pickup', 'Pickup'),
        ('dropoff', 'Dropoff'),
    ]

    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('in-progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    bus = models.ForeignKey(
        Bus,
        on_delete=models.CASCADE,
        related_name='trips',
        help_text="Bus assigned to this trip"
    )
    driver = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='driver_trips',
        limit_choices_to={'user_type': 'driver'},
        help_text="Driver assigned to this trip"
    )
    bus_minder = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='minder_trips',
        limit_choices_to={'user_type': 'busminder'},
        help_text="Bus minder assigned to this trip"
    )
    route = models.CharField(max_length=255, help_text="Route name/description")
    trip_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='pickup')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')

    # Time tracking
    scheduled_time = models.DateTimeField(help_text="Scheduled departure time")
    start_time = models.DateTimeField(null=True, blank=True, help_text="Actual start time")
    end_time = models.DateTimeField(null=True, blank=True, help_text="Actual completion time")

    # Current location (for in-progress trips)
    current_latitude = models.DecimalField(
        max_digits=12,
        decimal_places=8,
        null=True,
        blank=True,
        help_text="Current GPS latitude"
    )
    current_longitude = models.DecimalField(
        max_digits=12,
        decimal_places=8,
        null=True,
        blank=True,
        help_text="Current GPS longitude"
    )
    location_timestamp = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Last location update time"
    )

    # Children on this trip (many-to-many)
    children = models.ManyToManyField(
        Child,
        related_name='trips',
        blank=True,
        help_text="Children assigned to this trip"
    )

    # Trip Summary (populated when trip is completed)
    total_students = models.IntegerField(null=True, blank=True, help_text="Total students on this trip")
    students_completed = models.IntegerField(null=True, blank=True, help_text="Students picked up/dropped off")
    students_absent = models.IntegerField(null=True, blank=True, help_text="Students marked absent")
    students_pending = models.IntegerField(null=True, blank=True, help_text="Students not marked")

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = TripManager()

    def __str__(self):
        return f"{self.route} - {self.get_trip_type_display()} ({self.get_status_display()})"

    class Meta:
        ordering = ['-scheduled_time']
        verbose_name = 'Trip'
        verbose_name_plural = 'Trips'


class Stop(models.Model):
    """
    Represents a stop along a trip route.
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('skipped', 'Skipped'),
    ]

    trip = models.ForeignKey(
        Trip,
        on_delete=models.CASCADE,
        related_name='stops',
        help_text="Trip this stop belongs to"
    )
    address = models.CharField(max_length=255, help_text="Stop address")

    # Location
    latitude = models.DecimalField(
        max_digits=12,
        decimal_places=8,
        help_text="Stop GPS latitude"
    )
    longitude = models.DecimalField(
        max_digits=12,
        decimal_places=8,
        help_text="Stop GPS longitude"
    )

    # Children at this stop
    children = models.ManyToManyField(
        Child,
        related_name='trip_stops',
        blank=True,
        help_text="Children to pickup/dropoff at this stop"
    )

    # Time tracking
    scheduled_time = models.DateTimeField(help_text="Scheduled arrival time")
    actual_time = models.DateTimeField(null=True, blank=True, help_text="Actual arrival time")

    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    # Order in route
    order = models.IntegerField(default=0, help_text="Order of this stop in the route")

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.address} - {self.get_status_display()}"

    class Meta:
        ordering = ['trip', 'order']
        verbose_name = 'Stop'
        verbose_name_plural = 'Stops'
