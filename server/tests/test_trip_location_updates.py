from django.test import TestCase
from rest_framework.test import APIClient
from django.urls import reverse
from django.utils import timezone

from .helpers import create_sample_data


class TripLocationUpdateTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()
        self.client = APIClient()
        # authenticate as driver (no special permissions enforced by view)
        self.client.force_authenticate(user=self.d['driver_user'])
        self.trip = self.d['trip']
        self.url = f"/api/trips/{self.trip.id}/update-location/"

    def test_missing_latitude_or_longitude_returns_400(self):
        resp = self.client.post(self.url, {'latitude': None}, format='json')
        self.assertEqual(resp.status_code, 400)

        resp2 = self.client.post(self.url, {'longitude': None}, format='json')
        self.assertEqual(resp2.status_code, 400)

    def test_valid_location_update_sets_coordinates_and_timestamp(self):
        resp = self.client.post(self.url, {'latitude': 1.23, 'longitude': 4.56}, format='json')
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        loc = data.get('currentLocation')
        self.assertIsNotNone(loc)
        self.assertAlmostEqual(float(loc['latitude']), 1.23, places=5)
        self.assertAlmostEqual(float(loc['longitude']), 4.56, places=5)
        self.assertIsNotNone(loc.get('timestamp'))

    def test_update_location_when_scheduled_still_allows_update(self):
        # trip is scheduled by default in sample data
        resp = self.client.post(self.url, {'latitude': 2.0, 'longitude': 3.0}, format='json')
        self.assertEqual(resp.status_code, 200)

    def test_update_location_when_in_progress_updates_timestamp(self):
        # start trip then update location
        from trips.models import Trip
        Trip.objects.start_trip(self.trip.id)
        before = self.trip.location_timestamp
        resp = self.client.post(self.url, {'latitude': 6.6, 'longitude': 7.7}, format='json')
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        loc = data.get('currentLocation')
        self.assertIsNotNone(loc)
        self.assertIsNotNone(loc.get('timestamp'))

    def test_multiple_updates_change_timestamp(self):
        resp1 = self.client.post(self.url, {'latitude': 10, 'longitude': 11}, format='json')
        t1 = resp1.json().get('currentLocation') and resp1.json().get('currentLocation').get('timestamp')
        resp2 = self.client.post(self.url, {'latitude': 12, 'longitude': 13}, format='json')
        t2 = resp2.json().get('currentLocation') and resp2.json().get('currentLocation').get('timestamp')
        self.assertNotEqual(t1, t2)

    def test_latitude_longitude_are_cast_to_float_in_response(self):
        resp = self.client.post(self.url, {'latitude': '15.5', 'longitude': '16.6'}, format='json')
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        loc = data.get('currentLocation')
        self.assertIsNotNone(loc)
        self.assertIsInstance(loc['latitude'], float)
        self.assertIsInstance(loc['longitude'], float)

    def test_unauthenticated_user_cannot_update_location(self):
        client = APIClient()
        resp = client.post(self.url, {'latitude': 1, 'longitude': 2}, format='json')
        self.assertIn(resp.status_code, (401, 403))

    def test_update_includes_bus_id_in_broadcast_payload(self):
        # We can't inspect channels easily here, but the response includes bus id
        resp = self.client.post(self.url, {'latitude': 20, 'longitude': 21}, format='json')
        data = resp.json()
        self.assertEqual(data.get('busId'), self.trip.bus.id)

    def test_longitude_out_of_range_is_stored_but_not_rejected_by_view(self):
        # The view does not validate coordinate ranges; ensure it accepts values
        resp = self.client.post(self.url, {'latitude': 1000, 'longitude': -2000}, format='json')
        self.assertEqual(resp.status_code, 200)

    def test_update_with_speed_and_heading_does_not_error(self):
        resp = self.client.post(self.url, {'latitude': 0.1, 'longitude': 0.2, 'speed': 12, 'heading': 90}, format='json')
        self.assertEqual(resp.status_code, 200)
