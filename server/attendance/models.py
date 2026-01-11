from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Attendance(models.Model):
    """
    Tracks individual student attendance records for bus trips.

    This model is the heart of the attendance tracking system, allowing bus minders
    to mark when students board the bus, when they arrive at school, and when they
    are dropped off at home. Parents can see real-time status updates for their children.

    Why it's needed:
    - Enables real-time tracking of student status ("On the way to school", "At school", etc.)
    - Provides accountability for bus minders and transparency for parents
    - Creates a historical record of attendance for reporting and safety audits

    Status Flow:
    - "not_on_bus" → Student hasn't boarded yet (default state)
    - "on_bus" → Student has boarded the bus (marked by bus minder)
    - "at_school" → Student has arrived at school and disembarked
    - "on_way_home" → Student boarded bus for return trip
    - "dropped_off" → Student has been dropped off at home
    - "absent" → Student was marked absent for this trip

    Assumptions:
    - Each child has TWO attendance records per day (one for pickup, one for dropoff)
    - Bus minders are responsible for marking attendance
    - Attendance is tied to a specific bus for tracking purposes

    Edge Cases:
    - If a child's bus assignment changes mid-day, old attendance records remain linked to original bus
    - Deleting a child cascades and removes all attendance history
    - Attendance without a bus assignment indicates the child was not assigned to transport that day

    Connections:
    - Linked to Child for tracking individual students
    - Linked to Bus to know which bus the child was assigned to
    - Linked to User (bus minder) who marked the attendance for accountability
    - Used by Parent views to display child status in real-time
    """

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('picked_up', 'Picked Up'),
        ('dropped_off', 'Dropped Off'),
        ('absent', 'Absent'),
        # Legacy statuses for backward compatibility
        ('not_on_bus', 'Not on Bus'),
        ('on_bus', 'On the way to school'),
        ('at_school', 'At School'),
        ('on_way_home', 'On the way home'),
    ]

    TRIP_TYPE_CHOICES = [
        ('pickup', 'Pickup'),
        ('dropoff', 'Dropoff'),
    ]

    child = models.ForeignKey(
        'children.Child',
        on_delete=models.CASCADE,
        related_name='attendance_records'
    )
    bus = models.ForeignKey(
        'buses.Bus',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='attendance_records',
        help_text="Bus assigned to this child for this attendance record"
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending'
    )
    trip_type = models.CharField(
        max_length=10,
        choices=TRIP_TYPE_CHOICES,
        default='pickup',
        help_text="Which trip type this attendance record is for (pickup or dropoff)"
    )
    date = models.DateField(auto_now_add=True)
    marked_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        limit_choices_to={'user_type': 'busminder'},
        related_name='marked_attendances',
        help_text="Bus minder who marked this attendance"
    )
    timestamp = models.DateTimeField(auto_now=True)
    notes = models.TextField(blank=True, help_text="Optional notes from bus minder")

    class Meta:
        ordering = ['-date', '-timestamp']
        unique_together = ['child', 'date', 'trip_type']  # One pickup and one dropoff record per child per day
        verbose_name_plural = "Attendance Records"

    def __str__(self):
        return f"{self.child} - {self.get_status_display()} ({self.date})"
