from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Parent(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, primary_key=True)
    contact_number = models.CharField(max_length=15, blank=True)
    address = models.TextField(blank=True)
    emergency_contact = models.CharField(max_length=15, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')

    def __str__(self):
        return f"Parent: {self.user.get_full_name() or self.user.username}"

    @property
    def id(self):
        return self.pk

    @property
    def child_set(self):
        # Backwards-compatible alias for related children manager used in tests
        return getattr(self, 'parent_children')

    def save(self, *args, **kwargs):
        # Enforce cross-model phone uniqueness when saving parent contact number
        contact = getattr(self, 'contact_number', None)
        if contact:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            from drivers.models import Driver
            from busminders.models import BusMinder
            from django.db import IntegrityError

            user_pk = getattr(self, 'user_id', None)
            if User.objects.filter(phone_number=contact).exclude(pk=user_pk).exists() or Driver.objects.filter(phone_number=contact).exclude(user_id=user_pk).exists() or BusMinder.objects.filter(phone_number=contact).exclude(user_id=user_pk).exists():
                raise IntegrityError(f"Contact number '{contact}' already in use by another account")

        super().save(*args, **kwargs)
