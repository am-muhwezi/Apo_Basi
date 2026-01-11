from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Notification(models.Model):
    """
    Store notifications for parents to view notification history.
    """
    NOTIFICATION_TYPES = [
        ('trip_started', 'Trip Started'),
        ('trip_completed', 'Trip Completed'),
        ('child_picked_up', 'Child Picked Up'),
        ('child_dropped_off', 'Child Dropped Off'),
        ('route_change', 'Route Change'),
        ('emergency', 'Emergency Alert'),
        ('major_delay', 'Major Delay'),
        ('bus_approaching', 'Bus Approaching'),
        ('general', 'General Notification'),
    ]

    parent = models.ForeignKey(
        'parents.Parent',
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    notification_type = models.CharField(max_length=50, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=200)
    message = models.TextField()
    full_message = models.TextField(blank=True, null=True)
    
    # Related objects (optional)
    child = models.ForeignKey(
        'children.Child',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications'
    )
    bus = models.ForeignKey(
        'buses.Bus',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications'
    )
    trip = models.ForeignKey(
        'trips.Trip',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications'
    )
    
    # Additional data (stored as JSON for flexibility)
    additional_data = models.JSONField(default=dict, blank=True)
    
    # Status
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['parent', '-created_at']),
            models.Index(fields=['parent', 'is_read']),
        ]

    def __str__(self):
        return f"{self.notification_type} - {self.title} (Parent: {self.parent.user.get_full_name()})"
