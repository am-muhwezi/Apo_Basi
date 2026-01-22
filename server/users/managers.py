from django.contrib.auth.models import BaseUserManager
from django.db import IntegrityError


class UserManager(BaseUserManager):
    """Custom user manager for User model"""

    def create_user(self, username, password=None, **extra_fields):
        """Create and save a regular user"""
        if not username:
            raise ValueError('The Username field must be set')

        # Enforce cross-model phone uniqueness at creation time
        phone = extra_fields.get('phone_number')
        if phone:
            # Import models here to avoid circular imports at module import time
            from django.contrib.auth import get_user_model
            User = get_user_model()
            from drivers.models import Driver
            from busminders.models import BusMinder
            from parents.models import Parent

            # Check across User, Driver, BusMinder, Parent for existing phone/contact
            if User.objects.filter(phone_number=phone).exists() or Driver.objects.filter(phone_number=phone).exists() or BusMinder.objects.filter(phone_number=phone).exists() or Parent.objects.filter(contact_number=phone).exists():
                raise IntegrityError(f"Phone number '{phone}' already in use")

        user = self.model(username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, username, password=None, **extra_fields):
        """Create and save a superuser"""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('user_type', 'admin')

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(username, password, **extra_fields)
