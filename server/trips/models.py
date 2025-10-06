from django.db import models
from django.contrib.auth import get_user_model
from buses.models import Bus
from drivers.models import Driver
from busminders.models import BusMinder
from children.models import Child

User = get_user_model()


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
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        help_text="Current GPS latitude"
    )
    current_longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
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

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

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
        max_digits=9,
        decimal_places=6,
        help_text="Stop GPS latitude"
    )
    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
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
