from django.test import TestCase
from .helpers import create_sample_data


class BusTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_bus_has_driver_and_busminder_and_trip_route(self):
        bus = self.d['bus']
        trip = self.d['trip']
        self.assertIsNotNone(bus.driver)
        self.assertEqual(bus.bus_minder, self.d['minder_user'])
        self.assertEqual(trip.route, 'Route 1')

    def test_bus_capacity_enforced_by_business_rule(self):
        trip = self.d['trip']
        bus = self.d['bus']
        self.assertLessEqual(trip.children.count(), bus.capacity)

    def test_cannot_assign_bus_more_than_capacity_children(self):
        # adding multiple children beyond capacity should raise a ValidationError via AssignmentService
        from django.core.exceptions import ValidationError
        from assignments.services import AssignmentService

        bus = self.d['bus']
        # attempt to bulk assign three children to a bus with capacity=2
        child_ids = [self.d['child1'].id, self.d['child2'].id, self.d['child3'].id]
        with self.assertRaises(ValidationError):
            AssignmentService.bulk_assign_children_to_bus(bus, child_ids)
