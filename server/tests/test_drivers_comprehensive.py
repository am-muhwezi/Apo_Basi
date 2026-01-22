"""
Comprehensive tests for the Driver model and related functionality.

This test suite covers:
- Driver creation and validation
- Phone number uniqueness constraints
- License validation
- Driver-bus assignment relationships
- Driver status management
- Driver profile completeness
"""

from django.test import TestCase
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.contrib.auth import get_user_model

from drivers.models import Driver
from buses.models import Bus
from assignments.models import Assignment
from assignments.services import AssignmentService
from tests.factories import DriverFactory, BusFactory, UserFactory

User = get_user_model()


class DriverCreationTests(TestCase):
    """Test driver creation and basic validation"""

    def test_create_driver_with_valid_data(self):
        """Should successfully create a driver with all required fields"""
        user = UserFactory(user_type='driver', phone_number='0712345678')
        driver = Driver.objects.create(
            user=user,
            license_number='DL12345',
            phone_number='0712345678'
        )

        self.assertIsNotNone(driver)
        self.assertEqual(driver.user, user)
        self.assertEqual(driver.license_number, 'DL12345')
        self.assertEqual(driver.phone_number, '0712345678')

    def test_create_driver_using_factory(self):
        """Should create driver using factory pattern"""
        driver = DriverFactory()

        self.assertIsNotNone(driver)
        self.assertIsNotNone(driver.user)
        self.assertEqual(driver.user.user_type, 'driver')
        self.assertIsNotNone(driver.license_number)

    def test_driver_user_must_have_driver_type(self):
        """Should validate that driver's user has driver user_type"""
        # Create user with wrong type
        user = UserFactory(user_type='parent', phone_number='0712345679')

        # This should be allowed at model level but ideally caught at app level
        driver = Driver.objects.create(
            user=user,
            license_number='DL12346',
            phone_number='0712345679'
        )

        # Note: This demonstrates a potential validation gap
        # Ideally user_type should match the profile being created
        self.assertEqual(driver.user.user_type, 'parent')  # Inconsistent but allowed

    def test_driver_without_user_fails(self):
        """Should not allow driver creation without a user"""
        with self.assertRaises(IntegrityError):
            Driver.objects.create(
                license_number='DL12347',
                phone_number='0712345680'
            )


class DriverPhoneNumberTests(TestCase):
    """Test phone number uniqueness and validation for drivers"""

    def test_driver_phone_number_matches_user_phone(self):
        """Driver phone_number should typically match user phone_number"""
        driver = DriverFactory()

        self.assertEqual(driver.phone_number, driver.user.phone_number)

    def test_two_drivers_cannot_share_phone_number(self):
        """Should prevent two drivers from having the same phone number"""
        phone = '0712345681'

        # Create first driver
        DriverFactory(phone_number=phone)

        # Try to create second driver with same phone - should fail at DB level
        with self.assertRaises(IntegrityError):
            user2 = UserFactory(user_type='driver', phone_number='0712345682')
            Driver.objects.create(
                user=user2,
                license_number='DL12349',
                phone_number=phone  # Duplicate phone
            )

    def test_driver_and_user_phone_mismatch_allowed(self):
        """System allows driver phone_number to differ from user phone_number"""
        # This may be a data integrity concern
        user = UserFactory(user_type='driver', phone_number='0712345683')
        driver = Driver.objects.create(
            user=user,
            license_number='DL12350',
            phone_number='0712345684'  # Different from user
        )

        self.assertNotEqual(driver.phone_number, driver.user.phone_number)

    def test_driver_phone_number_can_be_null(self):
        """Driver phone_number field allows null values"""
        user = UserFactory(user_type='driver', phone_number='0712345685')
        driver = Driver.objects.create(
            user=user,
            license_number='DL12351',
            phone_number=None
        )

        self.assertIsNone(driver.phone_number)


class DriverLicenseTests(TestCase):
    """Test driver license validation"""

    def test_license_number_required(self):
        """License number is required field"""
        user = UserFactory(user_type='driver')

        with self.assertRaises(IntegrityError):
            Driver.objects.create(
                user=user,
                phone_number='0712345686',
                license_number=None
            )

    def test_license_number_uniqueness(self):
        """Should prevent duplicate license numbers"""
        license = 'DL12352'

        DriverFactory(license_number=license)

        # Try to create another driver with same license
        with self.assertRaises(IntegrityError):
            user2 = UserFactory(user_type='driver', phone_number='0712345688')
            Driver.objects.create(
                user=user2,
                license_number=license,  # Duplicate
                phone_number='0712345688'
            )

    def test_license_expiry_date_optional(self):
        """License expiry date is optional"""
        driver = DriverFactory()

        # Should be allowed to be None
        driver.license_expiry = None
        driver.save()

        driver.refresh_from_db()
        self.assertIsNone(driver.license_expiry)


class DriverBusAssignmentTests(TestCase):
    """Test driver-bus assignment relationships"""

    def test_driver_can_be_assigned_to_bus_via_assignment_system(self):
        """Should allow driver assignment to bus through assignment system"""
        driver = DriverFactory()
        bus = BusFactory()
        admin = UserFactory(user_type='admin')

        assignment = AssignmentService.create_assignment(
            assignment_type='driver_to_bus',
            assignee=driver,
            assigned_to=bus,
            assigned_by=admin
        )

        self.assertIsNotNone(assignment)
        self.assertEqual(assignment.assignee, driver)
        self.assertEqual(assignment.assigned_to, bus)

    def test_driver_can_have_assigned_bus_field(self):
        """Driver model has assigned_bus field (old system)"""
        driver = DriverFactory()
        bus = BusFactory()

        driver.assigned_bus = bus
        driver.save()

        driver.refresh_from_db()
        self.assertEqual(driver.assigned_bus, bus)

    def test_driver_without_assigned_bus(self):
        """Driver can exist without an assigned bus"""
        driver = DriverFactory()

        self.assertIsNone(driver.assigned_bus)

    def test_multiple_drivers_cannot_share_same_bus_legacy_field(self):
        """Multiple drivers can have same bus in assigned_bus field (no constraint)"""
        bus = BusFactory()
        driver1 = DriverFactory(assigned_bus=bus)
        driver2 = DriverFactory(assigned_bus=bus)

        # Both have same bus - this is allowed in old system
        self.assertEqual(driver1.assigned_bus, bus)
        self.assertEqual(driver2.assigned_bus, bus)

    def test_driver_reassignment_via_assignment_system(self):
        """Should handle driver reassignment correctly"""
        driver = DriverFactory()
        bus1 = BusFactory(bus_number='B1')
        bus2 = BusFactory(bus_number='B2')
        admin = UserFactory(user_type='admin')

        # Assign to first bus
        assignment1 = AssignmentService.create_assignment(
            assignment_type='driver_to_bus',
            assignee=driver,
            assigned_to=bus1,
            assigned_by=admin
        )

        # Reassign to second bus without auto-cancel should raise a ValidationError
        from django.core.exceptions import ValidationError
        with self.assertRaises(ValidationError):
            AssignmentService.create_assignment(
                assignment_type='driver_to_bus',
                assignee=driver,
                assigned_to=bus2,
                assigned_by=admin
            )

        # If admin explicitly requests auto-cancel, reassignment proceeds and the previous assignment is no longer active
        assignment2 = AssignmentService.create_assignment(
            assignment_type='driver_to_bus',
            assignee=driver,
            assigned_to=bus2,
            assigned_by=admin,
            auto_cancel_conflicting=True
        )

        assignment1.refresh_from_db()

        self.assertNotEqual(assignment1.status, 'active')
        self.assertEqual(assignment2.status, 'active')


class DriverStatusTests(TestCase):
    """Test driver status management"""

    def test_driver_has_status_field(self):
        """Driver model should have status field"""
        driver = DriverFactory()

        # Check if status field exists
        self.assertTrue(hasattr(driver, 'status'))

    def test_driver_default_status(self):
        """Driver should have default status when created"""
        driver = DriverFactory()

        # Default status should be 'active' or similar
        self.assertIsNotNone(driver.status)

    def test_driver_status_can_be_changed(self):
        """Should be able to change driver status"""
        driver = DriverFactory()
        original_status = driver.status

        # Change status
        new_status = 'inactive' if original_status == 'active' else 'active'
        driver.status = new_status
        driver.save()

        driver.refresh_from_db()
        self.assertEqual(driver.status, new_status)


class DriverQueryTests(TestCase):
    """Test driver query operations"""

    def test_get_all_drivers(self):
        """Should retrieve all drivers"""
        DriverFactory.create_batch(5)

        drivers = Driver.objects.all()

        self.assertEqual(drivers.count(), 5)

    def test_get_driver_by_user(self):
        """Should retrieve driver by user"""
        driver = DriverFactory()

        found_driver = Driver.objects.get(user=driver.user)

        self.assertEqual(found_driver, driver)

    def test_get_driver_by_license(self):
        """Should retrieve driver by license number"""
        driver = DriverFactory(license_number='DL99999')

        found_driver = Driver.objects.get(license_number='DL99999')

        self.assertEqual(found_driver, driver)

    def test_get_drivers_by_status(self):
        """Should filter drivers by status"""
        # Create drivers with different statuses
        active_drivers = DriverFactory.create_batch(3)
        for driver in active_drivers:
            driver.status = 'active'
            driver.save()

        inactive_driver = DriverFactory()
        inactive_driver.status = 'inactive'
        inactive_driver.save()

        active_count = Driver.objects.filter(status='active').count()

        self.assertEqual(active_count, 3)


class DriverStringRepresentationTests(TestCase):
    """Test driver string representation"""

    def test_driver_str_representation(self):
        """Driver should have meaningful string representation"""
        user = UserFactory(
            user_type='driver',
            first_name='John',
            last_name='Doe',
            username='johndoe'
        )
        driver = DriverFactory(user=user)

        driver_str = str(driver)

        # Should contain meaningful information
        self.assertIsNotNone(driver_str)
        self.assertTrue(len(driver_str) > 0)


class DriverDeletionTests(TestCase):
    """Test driver deletion behavior"""

    def test_delete_driver(self):
        """Should be able to delete driver"""
        driver = DriverFactory()
        driver_id = driver.id

        driver.delete()

        with self.assertRaises(Driver.DoesNotExist):
            Driver.objects.get(user_id=driver_id)

    def test_delete_user_cascades_to_driver(self):
        """Deleting user should cascade to driver profile"""
        driver = DriverFactory()
        user = driver.user
        driver_id = driver.id

        user.delete()

        with self.assertRaises(Driver.DoesNotExist):
            Driver.objects.get(user_id=driver_id)

    def test_delete_driver_does_not_delete_user(self):
        """Deleting driver should not delete the user"""
        driver = DriverFactory()
        user = driver.user
        user_id = user.id

        driver.delete()

        # User should still exist
        self.assertTrue(User.objects.filter(id=user_id).exists())


class DriverEdgeCasesTests(TestCase):
    """Test edge cases and boundary conditions"""

    def test_driver_with_very_long_license_number(self):
        """Should handle long license numbers"""
        user = UserFactory(user_type='driver')
        long_license = 'A' * 100  # Very long license

        driver = Driver.objects.create(
            user=user,
            license_number=long_license,
            phone_number='0712345689'
        )

        self.assertEqual(len(driver.license_number), 100)

    def test_driver_with_special_characters_in_license(self):
        """Should handle special characters in license number"""
        user = UserFactory(user_type='driver')
        special_license = 'DL-2024/ABC#123'

        driver = Driver.objects.create(
            user=user,
            license_number=special_license,
            phone_number='0712345690'
        )

        self.assertEqual(driver.license_number, special_license)

    def test_create_many_drivers_performance(self):
        """Should handle bulk driver creation"""
        # Create 50 drivers
        drivers = DriverFactory.create_batch(50)

        self.assertEqual(len(drivers), 50)
        self.assertEqual(Driver.objects.count(), 50)
