"""
Django management command to create test data for real-time tracking

Usage: python manage.py setup_test_data
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from buses.models import Bus
from parents.models import Parent
from children.models import Child
from drivers.models import Driver

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates test data for real-time bus tracking'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('\n=== Creating Test Data for Real-Time Tracking ===\n'))

        # 1. Create Driver User
        driver_user, created = User.objects.get_or_create(
            username='testdriver',
            defaults={
                'user_type': 'driver',
                'email': 'driver@test.com',
                'first_name': 'John',
                'last_name': 'Driver',
            }
        )
        if created:
            driver_user.set_password('testpass123')
            driver_user.save()
            self.stdout.write(self.style.SUCCESS('✓ Created driver user: testdriver / testpass123'))
        else:
            self.stdout.write(self.style.WARNING('! Driver user already exists'))

        # 2. Create Parent User
        parent_user, created = User.objects.get_or_create(
            username='testparent',
            defaults={
                'user_type': 'parent',
                'email': 'parent@test.com',
                'first_name': 'Mary',
                'last_name': 'Parent',
            }
        )
        if created:
            parent_user.set_password('testpass123')
            parent_user.save()
            self.stdout.write(self.style.SUCCESS('✓ Created parent user: testparent / testpass123'))
        else:
            self.stdout.write(self.style.WARNING('! Parent user already exists'))

        # 3. Create Bus
        bus, created = Bus.objects.get_or_create(
            number_plate='ABC123',
            defaults={
                'current_location': 'Test Location',
                'is_active': False,
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'✓ Created bus: {bus.number_plate} (ID: {bus.id})'))
        else:
            self.stdout.write(self.style.WARNING(f'! Bus already exists: {bus.number_plate} (ID: {bus.id})'))

        # 4. Create Driver Profile
        driver_profile, created = Driver.objects.get_or_create(
            user=driver_user,
            defaults={
                'license_number': 'DL12345678',
                'phone_number': '1234567890',
                'assigned_bus': bus,
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'✓ Created driver profile for {driver_user.username}'))
        else:
            # Update assigned bus if profile exists
            if driver_profile.assigned_bus != bus:
                driver_profile.assigned_bus = bus
                driver_profile.save()
            self.stdout.write(self.style.WARNING('! Driver profile already exists'))

        # 5. Assign driver to bus
        if bus.driver != driver_user:
            bus.driver = driver_user
            bus.save()
            self.stdout.write(self.style.SUCCESS(f'✓ Assigned driver {driver_user.username} to bus {bus.number_plate}'))

        # 6. Create Parent Profile
        parent_profile, created = Parent.objects.get_or_create(
            user=parent_user,
            defaults={
                'contact_number': '0987654321',
                'address': '123 Test Street',
                'emergency_contact': '1112223333',
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'✓ Created parent profile for {parent_user.username}'))
        else:
            self.stdout.write(self.style.WARNING('! Parent profile already exists'))

        # 7. Create Child
        child, created = Child.objects.get_or_create(
            first_name='John',
            last_name='Doe',
            parent=parent_profile,
            defaults={
                'class_grade': 'Grade 5',
                'assigned_bus': bus,
            }
        )
        if created:
            self.stdout.write(self.style.SUCCESS(f'✓ Created child: {child.first_name} {child.last_name}'))
        else:
            # Update assigned bus if child exists
            if child.assigned_bus != bus:
                child.assigned_bus = bus
                child.save()
            self.stdout.write(self.style.WARNING('! Child already exists'))

        # Summary
        self.stdout.write(self.style.SUCCESS('\n=== Test Data Created Successfully! ===\n'))
        self.stdout.write(f'Driver User: testdriver / testpass123')
        self.stdout.write(f'Parent User: testparent / testpass123')
        self.stdout.write(f'Bus: {bus.number_plate} (ID: {bus.id})')
        self.stdout.write(f'Child: {child.first_name} {child.last_name}')
        self.stdout.write(self.style.SUCCESS('\n✓ Ready to test real-time tracking!\n'))
