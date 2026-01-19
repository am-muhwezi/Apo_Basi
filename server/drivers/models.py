from django.db import models
from django.contrib.auth import get_user_model
from buses.models import Bus

User = get_user_model()


class Driver(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, primary_key=True)
    license_number = models.CharField(max_length=50)
    license_expiry = models.DateField(null=True, blank=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True, unique=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    assigned_bus = models.ForeignKey(
        Bus, on_delete=models.SET_NULL, null=True, blank=True, related_name='driver_profile'
    )

    class Meta:
        ordering = ['user__first_name', 'user__last_name', 'user_id']

    def __str__(self):
        return f"Driver: {self.user.get_full_name() or self.user.username}"

    def delete(self, *args, **kwargs):
        """Override delete to clean up assignments before deletion"""
        from assignments.models import Assignment
        from django.contrib.contenttypes.models import ContentType

        # Clean up assignments where this driver is the assignee
        driver_content_type = ContentType.objects.get_for_model(Driver)
        Assignment.objects.filter(
            assignee_content_type=driver_content_type,
            assignee_object_id=self.pk
        ).delete()

        # Now delete the driver
        super().delete(*args, **kwargs)
