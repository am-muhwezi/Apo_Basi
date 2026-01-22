from django.test import TestCase
from .helpers import create_sample_data
from trips.models import Trip


class DriverTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_driver_only_sees_assigned_bus(self):
        driver_profile = self.d['driver_profile']
        self.assertEqual(driver_profile.assigned_bus, self.d['bus'])
        self.assertNotEqual(self.d['driver_profile2'].assigned_bus, self.d['bus'])

    def test_driver_cannot_start_trip_without_assigned_bus_or_children(self):
        # create a trip with a bus that has no children on it
        new_trip = Trip.objects.create(
            bus=self.d['bus2'],
            driver=self.d['driver_user2'],
            route='Route 2',
            trip_type='pickup',
            scheduled_time=self.d['trip'].scheduled_time
        )
        self.assertEqual(new_trip.children.count(), 0)
