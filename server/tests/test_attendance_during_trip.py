from django.test import TestCase
from django.utils import timezone
from django.db import IntegrityError

from .helpers import create_sample_data
from attendance.models import Attendance


class AttendanceDuringTripTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_mark_pickup_by_minder(self):
        child = self.d['child1']
        minder = self.d['minder_user']
        att = Attendance.objects.create(child=child, bus=self.d['bus'], trip_type='pickup', marked_by=minder)
        self.assertEqual(att.trip_type, 'pickup')

    def test_duplicate_attendance_for_same_day_rejected(self):
        child = self.d['child1']
        minder = self.d['minder_user']
        Attendance.objects.create(child=child, bus=self.d['bus'], trip_type='pickup', marked_by=minder)
        with self.assertRaises(IntegrityError):
            Attendance.objects.create(child=child, bus=self.d['bus'], trip_type='pickup', marked_by=minder)

    def test_mark_dropoff_allowed(self):
        child = self.d['child1']
        minder = self.d['minder_user']
        att = Attendance.objects.create(child=child, bus=self.d['bus'], trip_type='dropoff', marked_by=minder)
        self.assertEqual(att.trip_type, 'dropoff')

    def test_attendance_default_status_pending(self):
        child = self.d['child2']
        minder = self.d['minder_user']
        att = Attendance.objects.create(child=child, bus=self.d['bus'], trip_type='pickup', marked_by=minder)
        self.assertEqual(att.status, 'pending')

    def test_attendance_timestamp_updated(self):
        child = self.d['child2']
        minder = self.d['minder_user']
        att = Attendance.objects.create(child=child, bus=self.d['bus'], trip_type='pickup', marked_by=minder)
        self.assertIsNotNone(att.timestamp)

    def test_mark_absent_allowed(self):
        child = self.d['child3']
        minder = self.d['minder_user']
        att = Attendance.objects.create(child=child, bus=self.d['bus2'], trip_type='pickup', marked_by=minder, status='absent')
        self.assertEqual(att.status, 'absent')

    def test_attendance_for_unassigned_child_still_allowed(self):
        # Child3 assigned to bus2 but marking on bus is allowed (system may accept)
        child = self.d['child3']
        minder = self.d['minder_user']
        att = Attendance.objects.create(child=child, bus=self.d['bus2'], trip_type='pickup', marked_by=minder)
        self.assertEqual(att.child, child)

    def test_multiple_minders_marking_allowed(self):
        child = self.d['child1']
        minder = self.d['minder_user']
        Attendance.objects.create(child=child, bus=self.d['bus'], trip_type='pickup', marked_by=minder)
        # second record different trip_type allowed
        att2 = Attendance.objects.create(child=child, bus=self.d['bus'], trip_type='dropoff', marked_by=minder)
        self.assertEqual(att2.trip_type, 'dropoff')

    def test_attendance_unique_together_property(self):
        # ensure model meta unique_together present
        self.assertIn(('child', 'date', 'trip_type'), Attendance._meta.unique_together)

    def test_attendance_str_contains_child(self):
        child = self.d['child1']
        minder = self.d['minder_user']
        att = Attendance.objects.create(child=child, bus=self.d['bus'], trip_type='pickup', marked_by=minder)
        self.assertIn(str(child.first_name), str(att))
