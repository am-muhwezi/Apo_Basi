from django.db import models


class Child(models.Model):
    """
    Represents a child enrolled in the school transport system.

    This model is essential for tracking individual students, their assigned buses, and their relationship to parents within the ApoBasi platform. Each Child instance connects to a Parent (who manages the child's transport and attendance) and optionally to a Bus (for live tracking and route assignment).

    Why it's needed:
    - Enables granular tracking of students for attendance, safety, and live bus location features.
    - Supports parent-child relationships, allowing parents to view and manage their children's transport status in the mobile app.
    - Facilitates bus assignment, which is critical for route planning and real-time tracking.

    Assumptions:
    - Each child has one parent (the Parent model), but a parent may have multiple children.
    - A child may or may not be assigned to a bus at any given time (e.g., if not currently riding or if the bus assignment changes).
    - The Parent model is expected to be the source of truth for guardianship; edge cases like multiple guardians are not handled here.

    Edge Cases:
    - If a child's bus assignment is removed (set to null), the system should handle attendance and tracking gracefully.
    - Deleting a parent cascades and deletes all associated children, which may affect historical attendance records.
    - Bus assignment is optional; children without a bus should not break tracking or reporting features.

    Connections:
    - Linked to Parent via ForeignKey for family management and notifications.
    - Linked to Bus for live tracking, route management, and attendance logging.
    - Used by attendance, notification, and reporting modules to aggregate and display student data to parents and school admins.
    """

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
    ]

    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
    class_grade = models.CharField(max_length=10)
    age = models.IntegerField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    parent = models.ForeignKey(
        "parents.Parent", on_delete=models.CASCADE, related_name="parent_children"
    )
    assigned_bus = models.ForeignKey(
        "buses.Bus",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="children",
    )

    def __str__(self):
        return f"{self.first_name} {self.last_name}"
