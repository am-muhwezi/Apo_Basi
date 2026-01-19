from django.test import TestCase
from parents.models import Parent
from children.models import Child

from .helpers import create_sample_data


class ChildrenTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_child_has_parent_and_parent_can_have_multiple_children(self):
        child1 = self.d['child1']
        parent = self.d['parent_profile']
        self.assertIsNotNone(child1.parent)
        self.assertGreaterEqual(parent.parent_children.count(), 1)

    def test_child_belongs_to_exactly_one_parent_model_enforced(self):
        child1 = self.d['child1']
        self.assertFalse(hasattr(child1, 'parents'))
        self.assertIsInstance(child1.parent, Parent)
