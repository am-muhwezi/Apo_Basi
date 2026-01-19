from django.utils import timezone
from django.contrib.auth import get_user_model

from drivers.models import Driver
from busminders.models import BusMinder
from parents.models import Parent
from children.models import Child
from buses.models import Bus
from trips.models import Trip

User = get_user_model()


def create_sample_data():
    """Create shared sample data used by multiple tests."""
    data = {}
    # Users
    data['driver_user'] = User.objects.create_user(username='driver1', password='pass', user_type='driver', phone_number='100')
    data['driver_user2'] = User.objects.create_user(username='driver2', password='pass', user_type='driver', phone_number='101')
    data['minder_user'] = User.objects.create_user(username='minder1', password='pass', user_type='busminder', phone_number='200')
    data['parent_user'] = User.objects.create_user(username='parent1', password='pass', user_type='parent', phone_number='300')
    data['parent_user2'] = User.objects.create_user(username='parent2', password='pass', user_type='parent', phone_number='301')
    data['admin_user'] = User.objects.create_user(username='admin', password='pass', user_type='admin', phone_number='999')

    # Profiles
    data['driver_profile'] = Driver.objects.create(user=data['driver_user'], license_number='D123', phone_number='100')
    data['driver_profile2'] = Driver.objects.create(user=data['driver_user2'], license_number='D124', phone_number='101')
    data['minder_profile'] = BusMinder.objects.create(user=data['minder_user'], phone_number='200')
    data['parent_profile'] = Parent.objects.create(user=data['parent_user'], contact_number='300')
    data['parent_profile2'] = Parent.objects.create(user=data['parent_user2'], contact_number='301')

    # Buses
    data['bus'] = Bus.objects.create(bus_number='B1', number_plate='BUS-1', capacity=2, driver=data['driver_user'], bus_minder=data['minder_user'])
    data['bus2'] = Bus.objects.create(bus_number='B2', number_plate='BUS-2', capacity=3, driver=data['driver_user2'])

    data['driver_profile'].assigned_bus = data['bus']
    data['driver_profile'].save()

    # Children
    data['child1'] = Child.objects.create(first_name='Alice', last_name='A', class_grade='1', parent=data['parent_profile'], assigned_bus=data['bus'])
    data['child2'] = Child.objects.create(first_name='Ben', last_name='B', class_grade='1', parent=data['parent_profile'], assigned_bus=data['bus'])
    data['child3'] = Child.objects.create(first_name='Cathy', last_name='C', class_grade='2', parent=data['parent_profile2'], assigned_bus=data['bus2'])

    # Trip
    trip = Trip.objects.create(
        bus=data['bus'],
        driver=data['driver_user'],
        bus_minder=data['minder_user'],
        route='Route 1',
        trip_type='pickup',
        scheduled_time=timezone.now()
    )
    trip.children.add(data['child1'], data['child2'])
    data['trip'] = trip

    return data
