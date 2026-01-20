from django.contrib.auth.models import AbstractUser
from django.db import models

from .managers import UserManager


class User(AbstractUser):
    USER_TYPES = (
        ("parent", "Parent"),
        ("busminder", "Bus Minder"),
        ("driver", "Driver"),
        ("admin", "Admin"),
    )

    user_type = models.CharField(max_length=20, choices=USER_TYPES)
    phone_number = models.CharField(max_length=15, blank=True, null=True, unique=True)

    # Use custom manager to validate phone uniqueness before DB insert
    objects = UserManager()

    def __str__(self):
        return f"{self.username} ({self.get_user_type_display()})"
