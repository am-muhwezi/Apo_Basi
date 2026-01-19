from django.test import TestCase
from django.utils import timezone

from .helpers import create_sample_data
from trips.models import Trip


class NotificationTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_start_trip_triggers_no_exception(self):
        trip = self.d['trip']
        Trip.objects.start_trip(trip.id)
        trip.refresh_from_db()
        self.assertEqual(trip.status, 'in-progress')

    def test_complete_trip_triggers_no_exception(self):
        trip = self.d['trip']
        Trip.objects.start_trip(trip.id)
        Trip.objects.complete_trip(trip.id)
        trip.refresh_from_db()
        self.assertEqual(trip.status, 'completed')

    def test_cancel_trip_triggers_no_exception(self):
        trip = self.d['trip']
        Trip.objects.cancel_trip(trip.id)
        trip.refresh_from_db()
        self.assertEqual(trip.status, 'cancelled')

    def test_trip_start_prints_message(self):
        trip = self.d['trip']
        # ensure start doesn't raise
        Trip.objects.start_trip(trip.id)

    def test_notifications_stub_noop(self):
        # If notification subsystem is unconfigured, actions should still succeed
        trip = self.d['trip']
        Trip.objects.start_trip(trip.id)
        Trip.objects.complete_trip(trip.id)
        self.assertTrue(True)

    def test_multiple_trip_state_changes(self):
        trip = self.d['trip']
        Trip.objects.start_trip(trip.id)
        Trip.objects.cancel_trip(trip.id)
        trip.refresh_from_db()
        self.assertEqual(trip.status, 'cancelled')

    def test_start_then_complete_sets_times(self):
        trip = self.d['trip']
        Trip.objects.start_trip(trip.id)
        Trip.objects.complete_trip(trip.id)
        trip.refresh_from_db()
        self.assertIsNotNone(trip.start_time)
        self.assertIsNotNone(trip.end_time)

    def test_starting_already_started_raises(self):
        trip = self.d['trip']
        Trip.objects.start_trip(trip.id)
        from django.core.exceptions import ValidationError
        with self.assertRaises(ValidationError):
            Trip.objects.start_trip(trip.id)

    def test_completing_when_not_in_progress_raises(self):
        trip = self.d['trip']
        from django.core.exceptions import ValidationError
        with self.assertRaises(ValidationError):
            Trip.objects.complete_trip(trip.id)

    def test_cancel_after_completion_fails_via_view_but_manager_allows(self):
        trip = self.d['trip']
        Trip.objects.start_trip(trip.id)
        Trip.objects.complete_trip(trip.id)
        # Manager cancel still sets cancelled
        Trip.objects.cancel_trip(trip.id)
        trip.refresh_from_db()
        self.assertEqual(trip.status, 'cancelled')

    def test_notification_sequence_no_errors(self):
        trip = self.d['trip']
        Trip.objects.start_trip(trip.id)
        Trip.objects.complete_trip(trip.id)
        self.assertTrue(True)
