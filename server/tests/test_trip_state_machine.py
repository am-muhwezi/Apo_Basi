from django.test import TestCase
from django.utils import timezone
from django.core.exceptions import ValidationError
from django.db.utils import IntegrityError

from .helpers import create_sample_data
from trips.models import Trip


class TripStateMachineTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_trip_scheduled_to_in_progress_transition_requires_driver_and_children(self):
        trip = self.d['trip']
        # ensure trip is scheduled
        self.assertEqual(trip.status, 'scheduled')

        # The Trip model requires a driver (NOT NULL at DB level)
        driver_field = Trip._meta.get_field('driver')
        self.assertFalse(driver_field.null)

        # restore driver
        trip.driver = self.d['driver_user']
        trip.children.clear()
        trip.save()

        # Starting without children should fail
        with self.assertRaises(ValidationError):
            Trip.objects.start_trip(trip.id)

        # add children and start should succeed
        trip.children.add(self.d['child1'])
        Trip.objects.start_trip(trip.id)
        trip.refresh_from_db()
        self.assertEqual(trip.status, 'in-progress')
        self.assertIsNotNone(trip.start_time)

    def test_trip_in_progress_to_completed_sets_end_time_and_summary(self):
        trip = self.d['trip']
        # ensure trip is started
        Trip.objects.start_trip(trip.id)
        trip.refresh_from_db()
        self.assertEqual(trip.status, 'in-progress')

        # mark complete
        Trip.objects.complete_trip(trip.id)
        trip.refresh_from_db()
        self.assertEqual(trip.status, 'completed')
        self.assertIsNotNone(trip.end_time)
        # summary fields should reflect children count
        self.assertEqual(trip.total_students, trip.children.count())

    def test_invalid_direct_transition_from_scheduled_to_completed_raises(self):
        trip = self.d['trip']
        with self.assertRaises(ValidationError):
            Trip.objects.complete_trip(trip.id)

    def test_trip_cancel_from_any_state(self):
        trip = self.d['trip']
        # cancel while scheduled
        Trip.objects.cancel_trip(trip.id)
        trip.refresh_from_db()
        self.assertEqual(trip.status, 'cancelled')

        # create new trip and start then cancel
        trip2 = Trip.objects.create(
            bus=self.d['bus2'],
            driver=self.d['driver_user2'],
            route='X',
            trip_type='pickup',
            scheduled_time=timezone.now()
        )
        trip2.children.add(self.d['child3'])
        Trip.objects.start_trip(trip2.id)
        Trip.objects.cancel_trip(trip2.id)
        trip2.refresh_from_db()
        self.assertEqual(trip2.status, 'cancelled')
