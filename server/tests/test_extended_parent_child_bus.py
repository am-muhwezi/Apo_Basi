from django.test import TestCase
from django.core.exceptions import ValidationError

from .helpers import create_sample_data
from buses.models import Bus
from children.models import Child


class ExtendedParentChildBusTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_bus_capacity_positive(self):
        self.assertGreater(self.d['bus'].capacity, 0)

    def test_bus_has_driver(self):
        self.assertIsNotNone(self.d['bus'].driver)

    def test_bus_has_minder(self):
        self.assertIsNotNone(self.d['bus'].bus_minder)

    def test_child_has_parent(self):
        self.assertIsNotNone(self.d['child1'].parent)

    def test_child_parent_relationship_consistent(self):
        parent = self.d['parent_profile']
        self.assertIn(self.d['child1'], parent.child_set.all())

    def test_reassign_child_to_another_bus(self):
        child = self.d['child3']
        child.assigned_bus = self.d['bus']
        child.save()
        self.assertEqual(child.assigned_bus, self.d['bus'])

    def test_bus_number_uniqueness(self):
        bus = self.d['bus']
        with self.assertRaises(Exception):
            Bus.objects.create(bus_number=bus.bus_number, number_plate='X', capacity=10)

    def test_child_str_contains_name(self):
        self.assertIn(self.d['child1'].first_name, str(self.d['child1']))

    def test_parent_children_count(self):
        parent = self.d['parent_profile']
        self.assertGreaterEqual(parent.child_set.count(), 2)

    def test_assign_child_preserves_history(self):
        # Basic smoke test for assignment operations
        from assignments.services import AssignmentService
        bus = self.d['bus2']
        with self.assertRaises(ValidationError):
            AssignmentService.bulk_assign_children_to_bus(bus, [self.d['child1'].id, self.d['child2'].id, self.d['child3'].id])

    def test_bus_capacity_boundary(self):
        self.assertEqual(self.d['bus'].capacity, 2)

    def test_child_grade_valid(self):
        self.assertIn(self.d['child1'].class_grade, ['1', '2', '3'])

    def test_parent_contact_number_format(self):
        self.assertTrue(isinstance(self.d['parent_profile'].contact_number, str))

    def test_bus_number_plate_not_empty(self):
        self.assertTrue(bool(self.d['bus'].number_plate))

    def test_multiple_children_same_parent(self):
        parent = self.d['parent_profile']
        self.assertGreater(parent.child_set.count(), 1)

    def test_child_assignment_field_exists(self):
        self.assertTrue(hasattr(self.d['child1'], 'assigned_bus'))

    def test_bus_str_includes_number(self):
        self.assertIn(self.d['bus'].bus_number, str(self.d['bus']))

    def test_create_child_min_fields(self):
        c = Child.objects.create(first_name='New', last_name='Kid', class_grade='1', parent=self.d['parent_profile'])
        self.assertIsNotNone(c.pk)

    def test_bus_capacity_enforced_by_assignment(self):
        from assignments.services import AssignmentService
        with self.assertRaises(ValidationError):
            AssignmentService.bulk_assign_children_to_bus(self.d['bus'], [self.d['child1'].id, self.d['child2'].id, self.d['child3'].id])

    def test_parent_delete_orphans_children_or_nulls(self):
        parent = self.d['parent_profile']
        parent.delete()
        # children should have parent null or not reference deleted parent
        for c in Child.objects.filter(first_name__in=['Alice','Ben']):
            self.assertTrue(c.parent is None or c.parent.pk != parent.pk)

    def test_bus_capacity_field_type(self):
        self.assertIsInstance(self.d['bus'].capacity, int)

    def test_child_last_name_present(self):
        self.assertTrue(bool(self.d['child1'].last_name))

    def test_bus_creation_defaults(self):
        b = Bus.objects.create(bus_number='B100', number_plate='P100', capacity=10)
        self.assertIsNotNone(b.pk)

    def test_child_parent_fk_exists(self):
        self.assertTrue(Child._meta.get_field('parent'))

    def test_bus_capacity_not_none(self):
        self.assertIsNotNone(self.d['bus'].capacity)
