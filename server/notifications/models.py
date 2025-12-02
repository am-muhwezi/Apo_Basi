from django.db import models
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from parents.models import Parent


class Notification(models.Model):
    """
    Notification model to store notifications for parents about their children's
    pickup and dropoff events.

    Notification types:
    - pickup_confirmed: Child was picked up by bus
    - dropoff_complete: Child was dropped off
    - bus_approaching: Bus is approaching pickup/dropoff location
    - route_change: Route or schedule change
    - emergency: Emergency notification
    - major_delay: Significant delay in schedule
    - general: General information
    """

    NOTIFICATION_TYPES = [
        ('pickup_confirmed', 'Pickup Confirmed'),
        ('dropoff_complete', 'Dropoff Complete'),
        ('bus_approaching', 'Bus Approaching'),
        ('route_change', 'Route Change'),
        ('emergency', 'Emergency'),
        ('major_delay', 'Major Delay'),
        ('general', 'General'),
    ]

    # Who receives this notification
    parent = models.ForeignKey(Parent, on_delete=models.CASCADE, related_name='notifications')

    # Notification details
    type = models.CharField(max_length=30, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=200)
    message = models.TextField()

    # Read status
    is_read = models.BooleanField(default=False)

    # Related object (optional) - allows linking to attendance, trip, etc.
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE, null=True, blank=True)
    object_id = models.PositiveIntegerField(null=True, blank=True)
    related_object = GenericForeignKey('content_type', 'object_id')

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['parent', '-created_at']),
            models.Index(fields=['parent', 'is_read']),
        ]

    def __str__(self):
        return f"{self.get_type_display()} - {self.parent.user.get_full_name()} - {self.created_at.strftime('%Y-%m-%d %H:%M')}"

    def mark_as_read(self):
        """Mark notification as read"""
        if not self.is_read:
            self.is_read = True
            self.save(update_fields=['is_read', 'updated_at'])
