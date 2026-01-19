from django.test import TestCase
from django.utils import timezone

from .helpers import create_sample_data
from trips.models import Stop, Trip


class StopManagementTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()
        self.trip = self.d['trip']

    def test_create_stop(self):
        stop = Stop.objects.create(trip=self.trip, address='123 Road', latitude=1.0, longitude=2.0, scheduled_time=timezone.now(), order=1)
        self.assertEqual(stop.trip, self.trip)

    def test_stop_ordering(self):
        Stop.objects.create(trip=self.trip, address='A', latitude=0, longitude=0, scheduled_time=timezone.now(), order=2)
        s = Stop.objects.create(trip=self.trip, address='B', latitude=0, longitude=0, scheduled_time=timezone.now(), order=1)
        stops = list(self.trip.stops.order_by('order'))
        self.assertEqual(stops[0].order, 1)

    def test_complete_stop_changes_status(self):
        s = Stop.objects.create(trip=self.trip, address='C', latitude=0, longitude=0, scheduled_time=timezone.now(), order=3)
        s.status = 'completed'
        s.save()
        self.assertEqual(s.status, 'completed')

    def test_delete_stop(self):
        s = Stop.objects.create(trip=self.trip, address='D', latitude=0, longitude=0, scheduled_time=timezone.now(), order=4)
        sid = s.id
        s.delete()
        self.assertFalse(Stop.objects.filter(pk=sid).exists())

    def test_stop_children_setting(self):
        s = Stop.objects.create(trip=self.trip, address='E', latitude=0, longitude=0, scheduled_time=timezone.now(), order=5)
        s.children.set([self.d['child1'].id])
        self.assertEqual(s.children.count(), 1)

    def test_multiple_stops_same_trip(self):
        Stop.objects.create(trip=self.trip, address='X', latitude=0, longitude=0, scheduled_time=timezone.now(), order=1)
        Stop.objects.create(trip=self.trip, address='Y', latitude=0, longitude=0, scheduled_time=timezone.now(), order=2)
        self.assertGreaterEqual(self.trip.stops.count(), 2)

    def test_stop_requires_coordinates(self):
        with self.assertRaises(Exception):
            Stop.objects.create(trip=self.trip, address='NoCoords', scheduled_time=timezone.now(), order=6)

    def test_stop_actual_time_optional(self):
        s = Stop.objects.create(trip=self.trip, address='F', latitude=0, longitude=0, scheduled_time=timezone.now(), order=7)
        self.assertIsNone(s.actual_time)

    def test_stop_str_contains_address(self):
        s = Stop.objects.create(trip=self.trip, address='G', latitude=0, longitude=0, scheduled_time=timezone.now(), order=8)
        self.assertIn('G', str(s))

    def test_stop_order_change(self):
        s = Stop.objects.create(trip=self.trip, address='H', latitude=0, longitude=0, scheduled_time=timezone.now(), order=9)
        s.order = 1
        s.save()
        self.assertEqual(s.order, 1)
