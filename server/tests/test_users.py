from django.test import TestCase
from django.contrib.auth import get_user_model
from .helpers import create_sample_data

User = get_user_model()


class UserTests(TestCase):
    def setUp(self):
        self.d = create_sample_data()

    def test_unique_phone_numbers_for_accounts(self):
        number = '555-UNIQUE'
        from django.db.utils import IntegrityError

        User.objects.create_user(username='u1', password='p', user_type='parent', phone_number=number)
        # Creating another user with the same phone number should raise a DB integrity error
        with self.assertRaises(IntegrityError):
            User.objects.create_user(username='u2', password='p', user_type='driver', phone_number=number)

    def test_admin_can_see_everything_by_user_type(self):
        self.assertEqual(self.d['admin_user'].user_type, 'admin')
