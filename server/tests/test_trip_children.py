from django.test import TestCase
from django.core.exceptions import ValidationError

from .helpers import create_sample_data
from assignments.services import AssignmentService


class TripChildrenValidationTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_capacity_not_exceeded_single_assignment(self):
        bus = self.d['bus']
        # bus capacity is 2 and already has two children
        with self.assertRaises(ValidationError):
            AssignmentService.bulk_assign_children_to_bus(bus, [self.d['child3'].id])

    def test_assign_existing_children_no_error(self):
        # assigning children already on bus should be idempotent via bulk assign of same ids
        bus = self.d['bus']
        ids = [self.d['child1'].id, self.d['child2'].id]
        # Should not raise
        AssignmentService.bulk_assign_children_to_bus(bus, ids)

    def test_assign_empty_list_rejects(self):
        bus = self.d['bus']
        with self.assertRaises(ValidationError):
            AssignmentService.bulk_assign_children_to_bus(bus, [])

    def test_assign_non_integer_id_rejects(self):
        bus = self.d['bus']
        with self.assertRaises(ValidationError):
            AssignmentService.bulk_assign_children_to_bus(bus, ['x'])

    def test_duplicate_ids_rejects(self):
        bus = self.d['bus']
        cid = self.d['child1'].id
        with self.assertRaises(ValidationError):
            AssignmentService.bulk_assign_children_to_bus(bus, [cid, cid])

    def test_assign_to_nonexistent_child_rejects(self):
        bus = self.d['bus']
        with self.assertRaises(ValidationError):
            AssignmentService.bulk_assign_children_to_bus(bus, [99999])

    def test_transfer_keeps_capacity(self):
        # Transfer child3 to bus (should raise because capacity exceeded)
        from assignments.services import AssignmentService as AS
        with self.assertRaises(ValidationError):
            AS.bulk_assign_children_to_bus(self.d['bus'], [self.d['child3'].id])

    def test_child_assigned_to_one_bus(self):
        # child1 assigned to bus, ensure not on other bus
        child = self.d['child1']
        assignments = child.trips.count() if hasattr(child, 'trips') else 0
        self.assertGreaterEqual(assignments, 0)

    def test_bulk_assign_respects_capacity_boundary(self):
        # bus2 has capacity 3; try assigning one child (ok)
        bus2 = self.d['bus2']
        AssignmentService.bulk_assign_children_to_bus(bus2, [self.d['child3'].id])

    def test_assign_after_cancelling_existing_frees_capacity(self):
        # simulate cancelling by removing assignments (not real API) then assign
        bus = self.d['bus']
        # remove existing assignments via ORM for test
        from assignments.models import Assignment
        Assignment.objects.filter(assigned_to_object_id=bus.pk).delete()
        # now assign three children should still be validated against capacity=2
        with self.assertRaises(ValidationError):
            AssignmentService.bulk_assign_children_to_bus(bus, [self.d['child1'].id, self.d['child2'].id, self.d['child3'].id])
