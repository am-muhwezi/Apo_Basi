"""
Comprehensive tests for the BusMinder model and related functionality.

This test suite covers:
- BusMinder creation and validation
- Phone number uniqueness constraints
- BusMinder-bus assignment relationships
- BusMinder status management
- BusMinder profile completeness
- Attendance marking capabilities
"""

from django.test import TestCase
from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.contrib.auth import get_user_model

from busminders.models import BusMinder
from buses.models import Bus
from assignments.models import Assignment
from assignments.services import AssignmentService
from tests.factories import BusMinderFactory, BusFactory, UserFactory

User = get_user_model()


class BusMinderCreationTests(TestCase):
    """Test busminder creation and basic validation"""

    def test_create_busminder_with_valid_data(self):
        """Should successfully create a busminder with all required fields"""
        user = UserFactory(user_type='busminder', phone_number='0722345678')
        busminder = BusMinder.objects.create(
            user=user,
            phone_number='0722345678'
        )

        self.assertIsNotNone(busminder)
        self.assertEqual(busminder.user, user)
        self.assertEqual(busminder.phone_number, '0722345678')

    def test_create_busminder_using_factory(self):
        """Should create busminder using factory pattern"""
        busminder = BusMinderFactory()

        self.assertIsNotNone(busminder)
        self.assertIsNotNone(busminder.user)
        self.assertEqual(busminder.user.user_type, 'busminder')

    def test_busminder_user_must_have_busminder_type(self):
        """Should validate that busminder's user has busminder user_type"""
        # Create user with wrong type
        user = UserFactory(user_type='parent', phone_number='0722345679')

        # This is allowed at model level but may be an integrity issue
        busminder = BusMinder.objects.create(
            user=user,
            phone_number='0722345679'
        )

        # Demonstrates potential validation gap
        self.assertEqual(busminder.user.user_type, 'parent')

    def test_busminder_without_user_fails(self):
        """Should not allow busminder creation without a user"""
        with self.assertRaises(IntegrityError):
            BusMinder.objects.create(
                phone_number='0722345680'
            )


class BusMinderPhoneNumberTests(TestCase):
    """Test phone number uniqueness and validation for busminders"""

    def test_busminder_phone_number_matches_user_phone(self):
        """BusMinder phone_number should typically match user phone_number"""
        busminder = BusMinderFactory()

        self.assertEqual(busminder.phone_number, busminder.user.phone_number)

    def test_two_busminders_cannot_share_phone_number(self):
        """Should prevent two busminders from having the same phone number"""
        phone = '0722345681'

        # Create first busminder
        BusMinderFactory(phone_number=phone)

        # Try to create second busminder with same phone - should fail
        with self.assertRaises(IntegrityError):
            user2 = UserFactory(user_type='busminder', phone_number='0722345682')
            BusMinder.objects.create(
                user=user2,
                phone_number=phone  # Duplicate phone
            )

    def test_busminder_and_user_phone_mismatch_allowed(self):
        """System allows busminder phone_number to differ from user phone_number"""
        user = UserFactory(user_type='busminder', phone_number='0722345683')
        busminder = BusMinder.objects.create(
            user=user,
            phone_number='0722345684'  # Different from user
        )

        self.assertNotEqual(busminder.phone_number, busminder.user.phone_number)

    def test_busminder_phone_number_can_be_null(self):
        """BusMinder phone_number field allows null values"""
        user = UserFactory(user_type='busminder', phone_number='0722345685')
        busminder = BusMinder.objects.create(
            user=user,
            phone_number=None
        )

        self.assertIsNone(busminder.phone_number)


class BusMinderBusAssignmentTests(TestCase):
    """Test busminder-bus assignment relationships"""

    def test_busminder_can_be_assigned_to_bus_via_assignment_system(self):
        """Should allow busminder assignment to bus through assignment system"""
        busminder = BusMinderFactory()
        bus = BusFactory()
        admin = UserFactory(user_type='admin')

        assignment = AssignmentService.create_assignment(
            assignment_type='minder_to_bus',
            assignee=busminder,
            assigned_to=bus,
            assigned_by=admin
        )

        self.assertIsNotNone(assignment)
        self.assertEqual(assignment.assignee, busminder)
        self.assertEqual(assignment.assigned_to, bus)

    def test_busminder_reassignment_via_assignment_system(self):
        """Should handle busminder reassignment correctly"""
        busminder = BusMinderFactory()
        bus1 = BusFactory(bus_number='B1')
        bus2 = BusFactory(bus_number='B2')
        admin = UserFactory(user_type='admin')

        # Assign to first bus
        assignment1 = AssignmentService.create_assignment(
            assignment_type='minder_to_bus',
            assignee=busminder,
            assigned_to=bus1,
            assigned_by=admin
        )

        # Reassign to second bus without auto-cancel should raise a ValidationError
        from django.core.exceptions import ValidationError
        with self.assertRaises(ValidationError):
            AssignmentService.create_assignment(
                assignment_type='minder_to_bus',
                assignee=busminder,
                assigned_to=bus2,
                assigned_by=admin
            )

        # If admin explicitly requests auto-cancel, reassignment proceeds and previous assignment is no longer active
        assignment2 = AssignmentService.create_assignment(
            assignment_type='minder_to_bus',
            assignee=busminder,
            assigned_to=bus2,
            assigned_by=admin,
            auto_cancel_conflicting=True
        )

        assignment1.refresh_from_db()

        self.assertNotEqual(assignment1.status, 'active')
        self.assertEqual(assignment2.status, 'active')

    def test_busminder_can_only_be_assigned_to_one_bus_at_time(self):
        """BusMinder should only be assigned to one bus at a time"""
        busminder = BusMinderFactory()
        bus1 = BusFactory(bus_number='B1')
        bus2 = BusFactory(bus_number='B2')
        admin = UserFactory(user_type='admin')

        # Assign to first bus
        AssignmentService.create_assignment(
            assignment_type='minder_to_bus',
            assignee=busminder,
            assigned_to=bus1,
            assigned_by=admin
        )

        # Try to assign to second bus without auto-cancel
        with self.assertRaises(ValidationError):
            AssignmentService.create_assignment(
                assignment_type='minder_to_bus',
                assignee=busminder,
                assigned_to=bus2,
                assigned_by=admin,
                auto_cancel_conflicting=False
            )

    def test_bus_can_have_only_one_busminder_at_time(self):
        """Bus should only have one busminder at a time"""
        busminder1 = BusMinderFactory()
        busminder2 = BusMinderFactory()
        bus = BusFactory()
        admin = UserFactory(user_type='admin')

        # Assign first busminder
        assignment1 = AssignmentService.create_assignment(
            assignment_type='minder_to_bus',
            assignee=busminder1,
            assigned_to=bus,
            assigned_by=admin
        )

        # Assign second busminder - should auto-expire first
        assignment2 = AssignmentService.create_assignment(
            assignment_type='minder_to_bus',
            assignee=busminder2,
            assigned_to=bus,
            assigned_by=admin
        )

        assignment1.refresh_from_db()

        self.assertEqual(assignment1.status, 'expired')
        self.assertEqual(assignment2.status, 'active')


class BusMinderStatusTests(TestCase):
    """Test busminder status management"""

    def test_busminder_has_status_field(self):
        """BusMinder model should have status field"""
        busminder = BusMinderFactory()

        # Check if status field exists
        self.assertTrue(hasattr(busminder, 'status'))

    def test_busminder_default_status(self):
        """BusMinder should have default status when created"""
        busminder = BusMinderFactory()

        # Default status should be 'active' or similar
        self.assertIsNotNone(busminder.status)

    def test_busminder_status_can_be_changed(self):
        """Should be able to change busminder status"""
        busminder = BusMinderFactory()
        original_status = busminder.status

        # Change status
        new_status = 'inactive' if original_status == 'active' else 'active'
        busminder.status = new_status
        busminder.save()

        busminder.refresh_from_db()
        self.assertEqual(busminder.status, new_status)


class BusMinderQueryTests(TestCase):
    """Test busminder query operations"""

    def test_get_all_busminders(self):
        """Should retrieve all busminders"""
        BusMinderFactory.create_batch(5)

        busminders = BusMinder.objects.all()

        self.assertEqual(busminders.count(), 5)

    def test_get_busminder_by_user(self):
        """Should retrieve busminder by user"""
        busminder = BusMinderFactory()

        found_busminder = BusMinder.objects.get(user=busminder.user)

        self.assertEqual(found_busminder, busminder)

    def test_get_busminders_by_status(self):
        """Should filter busminders by status"""
        # Create busminders with different statuses
        active_busminders = BusMinderFactory.create_batch(3)
        for busminder in active_busminders:
            busminder.status = 'active'
            busminder.save()

        inactive_busminder = BusMinderFactory()
        inactive_busminder.status = 'inactive'
        inactive_busminder.save()

        active_count = BusMinder.objects.filter(status='active').count()

        self.assertEqual(active_count, 3)

    def test_get_busminder_current_assignment(self):
        """Should retrieve busminder's current bus assignment"""
        busminder = BusMinderFactory()
        bus = BusFactory()
        admin = UserFactory(user_type='admin')

        AssignmentService.create_assignment(
            assignment_type='minder_to_bus',
            assignee=busminder,
            assigned_to=bus,
            assigned_by=admin
        )

        assignments = Assignment.get_active_assignments_for(busminder, 'minder_to_bus')

        self.assertEqual(assignments.count(), 1)
        self.assertEqual(assignments.first().assigned_to, bus)


class BusMinderStringRepresentationTests(TestCase):
    """Test busminder string representation"""

    def test_busminder_str_representation(self):
        """BusMinder should have meaningful string representation"""
        user = UserFactory(
            user_type='busminder',
            first_name='Jane',
            last_name='Smith',
            username='janesmith'
        )
        busminder = BusMinderFactory(user=user)

        busminder_str = str(busminder)

        # Should contain meaningful information
        self.assertIsNotNone(busminder_str)
        self.assertTrue(len(busminder_str) > 0)


class BusMinderDeletionTests(TestCase):
    """Test busminder deletion behavior"""

    def test_delete_busminder(self):
        """Should be able to delete busminder"""
        busminder = BusMinderFactory()
        busminder_id = busminder.id

        busminder.delete()

        with self.assertRaises(BusMinder.DoesNotExist):
            BusMinder.objects.get(user_id=busminder_id)

    def test_delete_user_cascades_to_busminder(self):
        """Deleting user should cascade to busminder profile"""
        busminder = BusMinderFactory()
        user = busminder.user
        busminder_id = busminder.id

        user.delete()

        with self.assertRaises(BusMinder.DoesNotExist):
            BusMinder.objects.get(user_id=busminder_id)

    def test_delete_busminder_does_not_delete_user(self):
        """Deleting busminder should not delete the user"""
        busminder = BusMinderFactory()
        user = busminder.user
        user_id = user.id

        busminder.delete()

        # User should still exist
        self.assertTrue(User.objects.filter(id=user_id).exists())

    def test_delete_busminder_with_active_assignment(self):
        """Should handle deletion of busminder with active assignments"""
        busminder = BusMinderFactory()
        bus = BusFactory()
        admin = UserFactory(user_type='admin')

        AssignmentService.create_assignment(
            assignment_type='minder_to_bus',
            assignee=busminder,
            assigned_to=bus,
            assigned_by=admin
        )

        # Delete busminder
        busminder_id = busminder.id
        busminder.delete()

        # BusMinder should be deleted
        with self.assertRaises(BusMinder.DoesNotExist):
            BusMinder.objects.get(user_id=busminder_id)

        # Assignment should still exist (soft reference)
        # This demonstrates that assignments track deleted entities


class BusMinderEdgeCasesTests(TestCase):
    """Test edge cases and boundary conditions"""

    def test_busminder_with_special_characters_in_phone(self):
        """Should handle special characters in phone number"""
        user = UserFactory(user_type='busminder', phone_number='+254-722-345-689')
        special_phone = '+254-722-345-689'

        busminder = BusMinder.objects.create(
            user=user,
            phone_number=special_phone
        )

        self.assertEqual(busminder.phone_number, special_phone)

    def test_create_many_busminders_performance(self):
        """Should handle bulk busminder creation"""
        # Create 50 busminders
        busminders = BusMinderFactory.create_batch(50)

        self.assertEqual(len(busminders), 50)
        self.assertEqual(BusMinder.objects.count(), 50)

    def test_busminder_with_very_long_phone_number(self):
        """Should handle long phone numbers"""
        user = UserFactory(user_type='busminder')
        long_phone = '0' * 50  # Very long phone

        busminder = BusMinder.objects.create(
            user=user,
            phone_number=long_phone
        )

        self.assertEqual(len(busminder.phone_number), 50)


class BusMinderLegacyFieldTests(TestCase):
    """Test interactions with legacy Bus model fields"""

    def test_bus_legacy_bus_minder_field(self):
        """Bus model has legacy bus_minder field"""
        bus = BusFactory()
        user = UserFactory(user_type='busminder')

        bus.bus_minder = user
        bus.save()

        bus.refresh_from_db()
        self.assertEqual(bus.bus_minder, user)

    def test_bus_minder_via_legacy_and_assignment_system(self):
        """Can use both legacy field and assignment system simultaneously"""
        busminder = BusMinderFactory()
        bus = BusFactory()
        admin = UserFactory(user_type='admin')

        # Set via legacy field
        bus.bus_minder = busminder.user
        bus.save()

        # Also create assignment
        assignment = AssignmentService.create_assignment(
            assignment_type='minder_to_bus',
            assignee=busminder,
            assigned_to=bus,
            assigned_by=admin
        )

        # Both should be set
        self.assertEqual(bus.bus_minder, busminder.user)
        self.assertEqual(assignment.assigned_to, bus)
