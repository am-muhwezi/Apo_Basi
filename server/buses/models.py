from django.db import models
from django.conf import settings
from django.utils import timezone


class Bus(models.Model):
    # Basic bus information
    bus_number = models.CharField(max_length=20, help_text="Bus identification number")
    number_plate = models.CharField(
        max_length=20, unique=True, help_text="License plate number"
    )
    capacity = models.IntegerField(default=40, help_text="Maximum number of children")
    model = models.CharField(max_length=100, blank=True, help_text="Bus model/make")
    year = models.IntegerField(null=True, blank=True, help_text="Manufacturing year")

    # Location tracking
    current_location = models.CharField(
        max_length=255, blank=True
    )  # Human-readable address

    # GPS coordinates for real-time tracking
    latitude = models.DecimalField(
        max_digits=12,
        decimal_places=8,
        null=True,
        blank=True,
        help_text="GPS latitude coordinate",
    )
    longitude = models.DecimalField(
        max_digits=12,
        decimal_places=8,
        null=True,
        blank=True,
        help_text="GPS longitude coordinate",
    )

    # Tracking metadata
    last_updated = models.DateTimeField(
        auto_now=True, help_text="Last GPS update timestamp"
    )
    is_active = models.BooleanField(
        default=False, help_text="Is bus currently on route?"
    )
    speed = models.FloatField(null=True, blank=True, help_text="Current speed in km/h")
    heading = models.FloatField(
        null=True, blank=True, help_text="Direction in degrees (0-360)"
    )

    # Maintenance tracking
    last_maintenance = models.DateField(
        null=True, blank=True, help_text="Last maintenance date"
    )

    # Link to driver
    driver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="driven_buses",
        limit_choices_to={"user_type": "driver"},
    )

    # Link to bus minder
    bus_minder = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="managed_buses",
        limit_choices_to={"user_type": "busminder"},
        help_text="Bus minder responsible for this bus",
    )

    def __str__(self):
        return self.number_plate

    class Meta:
        verbose_name_plural = "Buses"
        ordering = ['bus_number', 'id']


class BusLocationHistory(models.Model):
    """
    Stores historical location data for buses for trip history and analytics.

    Purpose:
    - Track bus movement over time
    - Generate trip reports
    - Analyze routes and timing
    - Provide audit trail for location updates

    Storage Strategy:
    - Real-time data: Redis (fast, expires in 60s)
    - Historical data: PostgreSQL (persistent, queryable)

    Relationship:
    - One bus can have many location history records
    - Each record is a snapshot at a specific timestamp
    """

    bus = models.ForeignKey(
        Bus,
        on_delete=models.CASCADE,
        related_name='location_history',
        help_text="Bus this location record belongs to"
    )

    latitude = models.DecimalField(
        max_digits=12,
        decimal_places=8,
        help_text="GPS latitude coordinate"
    )

    longitude = models.DecimalField(
        max_digits=12,
        decimal_places=8,
        help_text="GPS longitude coordinate"
    )

    speed = models.FloatField(
        null=True,
        blank=True,
        help_text="Speed in km/h at time of recording"
    )

    heading = models.FloatField(
        null=True,
        blank=True,
        help_text="Direction in degrees (0-360)"
    )

    is_active = models.BooleanField(
        default=True,
        help_text="Was bus active when location was recorded"
    )

    timestamp = models.DateTimeField(
        default=timezone.now,
        db_index=True,
        help_text="When this location was recorded"
    )

    # Optional: Link to trip if part of an active trip
    trip = models.ForeignKey(
        'trips.Trip',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='location_points',
        help_text="Trip this location was recorded during"
    )

    class Meta:
        verbose_name_plural = "Bus Location History"
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['bus', '-timestamp']),
            models.Index(fields=['trip', '-timestamp']),
        ]

    def __str__(self):
        return f"{self.bus.bus_number} - {self.timestamp}"
