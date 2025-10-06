from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Admin(models.Model):
    """
    Admin user with specific role and contact information
    """
    ROLE_CHOICES = [
        ('super-admin', 'Super Admin'),
        ('admin', 'Admin'),
        ('viewer', 'Viewer'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, primary_key=True)
    contact_number = models.CharField(max_length=20, blank=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='admin')
    status = models.CharField(max_length=20, default='active')

    def __str__(self):
        return f"Admin: {self.user.get_full_name() or self.user.username}"
