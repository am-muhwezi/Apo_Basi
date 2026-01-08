from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class BusMinder(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, primary_key=True)
    phone_number = models.CharField(max_length=20, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')

    class Meta:
        ordering = ['user__first_name', 'user__last_name', 'user_id']

    def __str__(self):
        return f"BusMinder: {self.user.get_full_name() or self.user.username}"

    def delete(self, *args, **kwargs):
        """Override delete to clean up assignments before deletion"""
        from assignments.models import Assignment
        from django.contrib.contenttypes.models import ContentType

        # Clean up assignments where this busminder is the assignee
        busminder_content_type = ContentType.objects.get_for_model(BusMinder)
        Assignment.objects.filter(
            assignee_content_type=busminder_content_type,
            assignee_object_id=self.pk
        ).delete()

        # Now delete the busminder
        super().delete(*args, **kwargs)
