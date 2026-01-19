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
    license_number = models.CharField(max_length=50, unique=True)
    license_expiry = models.DateField(null=True, blank=True)
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    assigned_bus = models.ForeignKey(
        Bus, on_delete=models.SET_NULL, null=True, blank=True, related_name='driver_profile'
    )

    class Meta:
        ordering = ['user__first_name', 'user__last_name', 'user_id']

    def __str__(self):
        return f"Driver: {self.user.get_full_name() or self.user.username}"

    @property
    def id(self):
        return self.pk

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

    def save(self, *args, **kwargs):
        # Enforce cross-model phone uniqueness when saving driver profile
        phone = getattr(self, 'phone_number', None)
        if phone:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            from busminders.models import BusMinder
            from parents.models import Parent
            from django.db import IntegrityError

            # Exclude self when checking existing records (for updates)
            user_pk = getattr(self, 'user_id', None)
            if User.objects.filter(phone_number=phone).exclude(pk=user_pk).exists() or BusMinder.objects.filter(phone_number=phone).exclude(user_id=user_pk).exists() or Parent.objects.filter(contact_number=phone).exclude(user_id=user_pk).exists():
                raise IntegrityError(f"Phone number '{phone}' already in use")

        super().save(*args, **kwargs)
