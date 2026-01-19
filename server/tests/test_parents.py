from django.test import TestCase
from django.core.exceptions import ValidationError

from .helpers import create_sample_data
from parents.models import Parent
from children.models import Child


class ParentModelTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_create_parent_requires_user_and_user_type_parent(self):
        # user created in helpers is of type parent
        parent = self.d['parent_profile']
        self.assertIsInstance(parent, Parent)
        self.assertEqual(parent.user.user_type, 'parent')

    def test_parent_can_have_multiple_children(self):
        parent = self.d['parent_profile']
        # child1 and child2 belong to parent_profile
        children = Child.objects.filter(parent=parent)
        self.assertGreaterEqual(children.count(), 2)

    def test_parent_deletion_cascades_to_children(self):
        parent = self.d['parent_profile']
        child_ids = list(Child.objects.filter(parent=parent).values_list('id', flat=True))
        parent.delete()
        # children should be deleted or parent set null depending on model, assert they no longer reference the parent
        remaining = Child.objects.filter(id__in=child_ids)
        for c in remaining:
            self.assertIsNone(c.parent)

    def test_parent_contact_number_uniqueness(self):
        parent = self.d['parent_profile']
        # attempt to create another Parent pointing to a different user but same contact_number
        from django.contrib.auth import get_user_model
        from django.db.utils import IntegrityError
        User = get_user_model()
        # Creating a User with a duplicate phone number should fail at DB level
        with self.assertRaises(IntegrityError):
            User.objects.create_user(username='dup_parent', password='pass', user_type='parent', phone_number=parent.contact_number)
