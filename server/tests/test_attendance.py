from django.test import TestCase
from attendance.models import Attendance
from .helpers import create_sample_data


class AttendanceTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_assistant_can_mark_attendance(self):
        att = Attendance.objects.create(child=self.d['child1'], bus=self.d['bus'], trip_type='pickup', marked_by=self.d['minder_user'], status='picked_up')
        self.assertEqual(att.marked_by, self.d['minder_user'])

    def test_attendance_unique_together(self):
        # unique_together: child+date+trip_type
        Attendance.objects.create(child=self.d['child1'], bus=self.d['bus'], trip_type='pickup', marked_by=self.d['minder_user'], status='picked_up')
        with self.assertRaises(Exception):
            Attendance.objects.create(child=self.d['child1'], bus=self.d['bus'], trip_type='pickup', marked_by=self.d['minder_user'], status='picked_up')
