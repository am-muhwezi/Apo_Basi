"""
Comprehensive tests for User model and phone number uniqueness.

This test suite covers:
- User creation for all user types
- Phone number uniqueness across all user types
- Username uniqueness
- User authentication
- User type validation
- Cross-profile phone number conflicts
"""

from django.test import TestCase
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.contrib.auth import get_user_model

from drivers.models import Driver
from busminders.models import BusMinder
from parents.models import Parent
from tests.factories import UserFactory, DriverFactory, BusMinderFactory, ParentFactory

User = get_user_model()


class UserCreationTests(TestCase):
    """Test user creation for all user types"""

    def test_create_parent_user(self):
        """Should create user with parent type"""
        user = User.objects.create_user(
            username='parent1',
            password='testpass123',
            user_type='parent',
            phone_number='0701111111'
        )

        self.assertEqual(user.user_type, 'parent')
        self.assertTrue(user.check_password('testpass123'))

    def test_create_driver_user(self):
        """Should create user with driver type"""
        user = User.objects.create_user(
            username='driver1',
            password='testpass123',
            user_type='driver',
            phone_number='0702222222'
        )

        self.assertEqual(user.user_type, 'driver')

    def test_create_busminder_user(self):
        """Should create user with busminder type"""
        user = User.objects.create_user(
            username='minder1',
            password='testpass123',
            user_type='busminder',
            phone_number='0703333333'
        )

        self.assertEqual(user.user_type, 'busminder')

    def test_create_admin_user(self):
        """Should create user with admin type"""
        user = User.objects.create_user(
            username='admin1',
            password='testpass123',
            user_type='admin',
            phone_number='0704444444'
        )

        self.assertEqual(user.user_type, 'admin')

    def test_create_superuser(self):
        """Should create superuser with admin type"""
        user = User.objects.create_superuser(
            username='superadmin',
            password='testpass123',
            phone_number='0705555555'
        )

        self.assertEqual(user.user_type, 'admin')
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)


class PhoneNumberUniquenessTests(TestCase):
    """Test phone number uniqueness constraints"""

    def test_phone_number_must_be_unique_at_database_level(self):
        """Database enforces phone number uniqueness"""
        phone = '0706666666'

        User.objects.create_user(
            username='user1',
            password='pass',
            user_type='parent',
            phone_number=phone
        )

        # Try to create another user with same phone
        with self.assertRaises(IntegrityError):
            User.objects.create_user(
                username='user2',
                password='pass',
                user_type='driver',
                phone_number=phone  # Duplicate
            )

    def test_parent_and_driver_cannot_share_phone_number(self):
        """Parent and driver cannot have the same phone number"""
        phone = '0707777777'

        User.objects.create_user(
            username='parent1',
            password='pass',
            user_type='parent',
            phone_number=phone
        )

        with self.assertRaises(IntegrityError):
            User.objects.create_user(
                username='driver1',
                password='pass',
                user_type='driver',
                phone_number=phone
            )

    def test_driver_and_busminder_cannot_share_phone_number(self):
        """Driver and busminder cannot have the same phone number"""
        phone = '0708888888'

        User.objects.create_user(
            username='driver1',
            password='pass',
            user_type='driver',
            phone_number=phone
        )

        with self.assertRaises(IntegrityError):
            User.objects.create_user(
                username='minder1',
                password='pass',
                user_type='busminder',
                phone_number=phone
            )

    def test_busminder_and_parent_cannot_share_phone_number(self):
        """BusMinder and parent cannot have the same phone number"""
        phone = '0709999999'

        User.objects.create_user(
            username='minder1',
            password='pass',
            user_type='busminder',
            phone_number=phone
        )

        with self.assertRaises(IntegrityError):
            User.objects.create_user(
                username='parent1',
                password='pass',
                user_type='parent',
                phone_number=phone
            )

    def test_multiple_users_with_null_phone_allowed(self):
        """Multiple users can have NULL phone numbers"""
        user1 = User.objects.create_user(
            username='user1',
            password='pass',
            user_type='parent',
            phone_number=None
        )

        user2 = User.objects.create_user(
            username='user2',
            password='pass',
            user_type='driver',
            phone_number=None
        )

        self.assertIsNone(user1.phone_number)
        self.assertIsNone(user2.phone_number)

    def test_phone_number_with_different_formats_still_unique(self):
        """Phone numbers with different formats are treated as different"""
        user1 = User.objects.create_user(
            username='user1',
            password='pass',
            user_type='parent',
            phone_number='0701234567'
        )

        # This should be allowed (different format)
        user2 = User.objects.create_user(
            username='user2',
            password='pass',
            user_type='driver',
            phone_number='+254701234567'  # Different format but conceptually same
        )

        # Both created successfully (no normalization)
        self.assertNotEqual(user1.phone_number, user2.phone_number)


class UsernameUniquenessTests(TestCase):
    """Test username uniqueness constraints"""

    def test_username_must_be_unique(self):
        """Username must be unique across all users"""
        User.objects.create_user(
            username='john',
            password='pass',
            user_type='parent',
            phone_number='0701111112'
        )

        with self.assertRaises(IntegrityError):
            User.objects.create_user(
                username='john',  # Duplicate
                password='pass',
                user_type='driver',
                phone_number='0701111113'
            )

    def test_username_case_sensitive(self):
        """Username uniqueness is case-sensitive"""
        User.objects.create_user(
            username='John',
            password='pass',
            user_type='parent',
            phone_number='0701111114'
        )

        # Lowercase 'john' should be different from 'John'
        user2 = User.objects.create_user(
            username='john',
            password='pass',
            user_type='driver',
            phone_number='0701111115'
        )

        self.assertIsNotNone(user2)


class UserTypeValidationTests(TestCase):
    """Test user type validation and constraints"""

    def test_user_type_must_be_valid_choice(self):
        """User type must be one of the valid choices"""
        # Valid types: parent, busminder, driver, admin
        valid_types = ['parent', 'busminder', 'driver', 'admin']

        for user_type in valid_types:
            user = User.objects.create_user(
                username=f'{user_type}_user',
                password='pass',
                user_type=user_type,
                phone_number=f'070111111{valid_types.index(user_type)}'
            )
            self.assertEqual(user.user_type, user_type)

    def test_user_type_invalid_raises_error(self):
        """Invalid user type should raise validation error"""
        # This might be caught at validation level
        user = User(
            username='invalid_user',
            user_type='invalid_type',  # Invalid
            phone_number='0701111120'
        )

        # ValidationError should be raised on full_clean
        with self.assertRaises(ValidationError):
            user.full_clean()

    def test_user_can_change_type(self):
        """User type can be changed (edge case)"""
        user = UserFactory(user_type='parent')

        user.user_type = 'driver'
        user.save()

        user.refresh_from_db()
        self.assertEqual(user.user_type, 'driver')


class CrossProfilePhoneConflictTests(TestCase):
    """Test phone number conflicts across User and Profile models"""

    def test_user_and_driver_profile_phone_mismatch(self):
        """User phone and Driver profile phone can differ (integrity gap)"""
        user = UserFactory(user_type='driver', phone_number='0701111121')

        driver = Driver.objects.create(
            user=user,
            license_number='DL123',
            phone_number='0701111122'  # Different from user
        )

        self.assertNotEqual(user.phone_number, driver.phone_number)

    def test_user_and_busminder_profile_phone_mismatch(self):
        """User phone and BusMinder profile phone can differ (integrity gap)"""
        user = UserFactory(user_type='busminder', phone_number='0701111123')

        busminder = BusMinder.objects.create(
            user=user,
            phone_number='0701111124'  # Different from user
        )

        self.assertNotEqual(user.phone_number, busminder.phone_number)

    def test_user_and_parent_profile_phone_mismatch(self):
        """User phone and Parent profile phone can differ (integrity gap)"""
        user = UserFactory(user_type='parent', phone_number='0701111125')

        parent = Parent.objects.create(
            user=user,
            contact_number='0701111126'  # Different from user
        )

        self.assertNotEqual(user.phone_number, parent.contact_number)

    def test_driver_profile_phone_conflicts_with_another_user_phone(self):
        """Driver profile phone can match another user's phone (potential issue)"""
        user1 = UserFactory(user_type='parent', phone_number='0701111127')
        user2 = UserFactory(user_type='driver', phone_number='0701111128')

        # Driver profile with same phone as user1
        try:
            driver = Driver.objects.create(
                user=user2,
                license_number='DL124',
                phone_number='0701111127'  # Same as user1
            )
            # This is allowed, demonstrating a potential integrity gap
            self.assertEqual(driver.phone_number, user1.phone_number)
        except IntegrityError:
            # If this fails, it means there's cross-table uniqueness
            pass


class UserAuthenticationTests(TestCase):
    """Test user authentication functionality"""

    def test_user_can_login_with_correct_password(self):
        """User can authenticate with correct password"""
        user = User.objects.create_user(
            username='testuser',
            password='correctpass',
            user_type='parent',
            phone_number='0701111129'
        )

        self.assertTrue(user.check_password('correctpass'))

    def test_user_cannot_login_with_incorrect_password(self):
        """User cannot authenticate with incorrect password"""
        user = User.objects.create_user(
            username='testuser2',
            password='correctpass',
            user_type='parent',
            phone_number='0701111130'
        )

        self.assertFalse(user.check_password('wrongpass'))

    def test_user_password_is_hashed(self):
        """User password should be hashed, not plain text"""
        user = User.objects.create_user(
            username='testuser3',
            password='mypassword',
            user_type='parent',
            phone_number='0701111131'
        )

        # Password should not be stored as plain text
        self.assertNotEqual(user.password, 'mypassword')
        self.assertTrue(user.password.startswith('pbkdf2_'))


class UserQueryTests(TestCase):
    """Test user query operations"""

    def test_filter_users_by_type(self):
        """Should filter users by user type"""
        UserFactory.create_batch(3, user_type='parent')
        UserFactory.create_batch(2, user_type='driver')
        UserFactory.create_batch(1, user_type='admin')

        parents = User.objects.filter(user_type='parent')
        drivers = User.objects.filter(user_type='driver')
        admins = User.objects.filter(user_type='admin')

        self.assertEqual(parents.count(), 3)
        self.assertEqual(drivers.count(), 2)
        self.assertEqual(admins.count(), 1)

    def test_get_user_by_phone_number(self):
        """Should retrieve user by phone number"""
        user = UserFactory(phone_number='0701111132')

        found_user = User.objects.get(phone_number='0701111132')

        self.assertEqual(found_user, user)

    def test_get_user_by_username(self):
        """Should retrieve user by username"""
        user = UserFactory(username='uniqueuser')

        found_user = User.objects.get(username='uniqueuser')

        self.assertEqual(found_user, user)


class UserDeletionTests(TestCase):
    """Test user deletion and cascading behavior"""

    def test_delete_user(self):
        """Should be able to delete user"""
        user = UserFactory()
        user_id = user.id

        user.delete()

        with self.assertRaises(User.DoesNotExist):
            User.objects.get(id=user_id)

    def test_delete_user_cascades_to_driver_profile(self):
        """Deleting user should delete driver profile"""
        driver = DriverFactory()
        user = driver.user
        driver_id = driver.id

        user.delete()

        with self.assertRaises(Driver.DoesNotExist):
            Driver.objects.get(user_id=driver_id)

    def test_delete_user_cascades_to_busminder_profile(self):
        """Deleting user should delete busminder profile"""
        busminder = BusMinderFactory()
        user = busminder.user
        busminder_id = busminder.id

        user.delete()

        with self.assertRaises(BusMinder.DoesNotExist):
            BusMinder.objects.get(user_id=busminder_id)

    def test_delete_user_cascades_to_parent_profile(self):
        """Deleting user should delete parent profile"""
        parent = ParentFactory()
        user = parent.user
        parent_id = parent.id

        user.delete()

        with self.assertRaises(Parent.DoesNotExist):
            Parent.objects.get(user_id=parent_id)


class UserStringRepresentationTests(TestCase):
    """Test user string representation"""

    def test_user_str_includes_username_and_type(self):
        """User string should include username and user type"""
        user = UserFactory(username='testuser', user_type='parent')

        user_str = str(user)

        self.assertIn('testuser', user_str)
        self.assertIn('Parent', user_str)


class UserEdgeCasesTests(TestCase):
    """Test edge cases and boundary conditions"""

    def test_user_with_very_long_phone_number(self):
        """Should handle long phone numbers"""
        long_phone = '0' * 15  # 15 digits

        user = User.objects.create_user(
            username='longphone',
            password='pass',
            user_type='parent',
            phone_number=long_phone
        )

        self.assertEqual(user.phone_number, long_phone)

    def test_user_with_special_characters_in_phone(self):
        """Should handle special characters in phone number"""
        special_phone = '+254-701-234-567'

        user = User.objects.create_user(
            username='specialphone',
            password='pass',
            user_type='parent',
            phone_number=special_phone
        )

        self.assertEqual(user.phone_number, special_phone)

    def test_user_with_empty_string_phone_vs_null(self):
        """Empty string phone number vs NULL phone number"""
        # NULL phone
        user1 = User.objects.create_user(
            username='user1',
            password='pass',
            user_type='parent',
            phone_number=None
        )

        # Empty string phone
        user2 = User.objects.create_user(
            username='user2',
            password='pass',
            user_type='driver',
            phone_number=''
        )

        self.assertIsNone(user1.phone_number)
        self.assertEqual(user2.phone_number, '')

    def test_create_many_users_performance(self):
        """Should handle bulk user creation"""
        users = UserFactory.create_batch(100)

        self.assertEqual(len(users), 100)
        self.assertEqual(User.objects.count(), 100)
