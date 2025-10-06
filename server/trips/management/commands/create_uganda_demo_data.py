from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from buses.models import Bus
from children.models import Child
from parents.models import Parent
from drivers.models import Driver
from busminders.models import BusMinder
from admins.models import Admin
from trips.models import Trip, Stop

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates demo data for a Ugandan school transport system'

    def handle(self, *args, **kwargs):
        self.stdout.write('Creating Ugandan school demo data...')

        # Clear existing data
        self.stdout.write('Clearing existing data...')
        Trip.objects.all().delete()
        Stop.objects.all().delete()
        Child.objects.all().delete()
        Parent.objects.all().delete()
        Driver.objects.all().delete()
        BusMinder.objects.all().delete()
        Admin.objects.all().delete()
        Bus.objects.all().delete()
        User.objects.filter(is_superuser=False).delete()

        # Create Admin
        self.stdout.write('Creating admin users...')
        from admins.models import Admin as AdminModel

        admin_user = User.objects.create_user(
            username='admin@stmarys.ug',
            email='admin@stmarys.ug',
            password='admin123',
            first_name='Grace',
            last_name='Nakato',
            user_type='admin'
        )
        AdminModel.objects.create(
            user=admin_user,
            contact_number='+256700123456',
            role='super-admin',
            status='active'
        )

        # Create Drivers
        self.stdout.write('Creating drivers...')
        drivers_data = [
            {'first_name': 'Moses', 'last_name': 'Okello', 'license': 'UG-DL-2345678', 'phone': '+256701234567'},
            {'first_name': 'Patrick', 'last_name': 'Ssemakula', 'license': 'UG-DL-3456789', 'phone': '+256702345678'},
            {'first_name': 'James', 'last_name': 'Kateregga', 'license': 'UG-DL-4567890', 'phone': '+256703456789'},
        ]
        drivers = []
        for data in drivers_data:
            user = User.objects.create_user(
                username=f"{data['first_name'].lower()}.{data['last_name'].lower()}@stmarys.ug",
                email=f"{data['first_name'].lower()}.{data['last_name'].lower()}@stmarys.ug",
                password='driver123',
                first_name=data['first_name'],
                last_name=data['last_name'],
                user_type='driver'
            )
            driver = Driver.objects.create(
                user=user,
                license_number=data['license'],
                phone_number=data['phone'],
                status='active'
            )
            drivers.append(user)

        # Create Bus Minders
        self.stdout.write('Creating bus minders...')
        minders_data = [
            {'first_name': 'Sarah', 'last_name': 'Namukasa', 'phone': '+256704567890'},
            {'first_name': 'Rebecca', 'last_name': 'Nabirye', 'phone': '+256705678901'},
            {'first_name': 'Joyce', 'last_name': 'Nakimera', 'phone': '+256706789012'},
        ]
        minders = []
        for data in minders_data:
            user = User.objects.create_user(
                username=f"{data['first_name'].lower()}.{data['last_name'].lower()}@stmarys.ug",
                email=f"{data['first_name'].lower()}.{data['last_name'].lower()}@stmarys.ug",
                password='minder123',
                first_name=data['first_name'],
                last_name=data['last_name'],
                user_type='busminder'
            )
            minder = BusMinder.objects.create(
                user=user,
                contact_number=data['phone'],
                status='active'
            )
            minders.append(user)

        # Create Buses
        self.stdout.write('Creating buses...')
        buses_data = [
            {'number': 'SMU-001', 'plate': 'UAM 123A', 'capacity': 35, 'driver': drivers[0], 'minder': minders[0]},
            {'number': 'SMU-002', 'plate': 'UAM 456B', 'capacity': 40, 'driver': drivers[1], 'minder': minders[1]},
            {'number': 'SMU-003', 'plate': 'UAM 789C', 'capacity': 30, 'driver': drivers[2], 'minder': minders[2]},
        ]
        buses = []
        for data in buses_data:
            bus = Bus.objects.create(
                bus_number=data['number'],
                number_plate=data['plate'],
                capacity=data['capacity'],
                model='Toyota Coaster',
                year=2020,
                driver=data['driver'],
                bus_minder=data['minder'],
                is_active=True,
                latitude=0.3476,  # Kampala coordinates
                longitude=32.5825
            )
            buses.append(bus)

        # Create Parents and Children
        self.stdout.write('Creating parents and children...')
        parents_children_data = [
            {
                'parent': {'first_name': 'David', 'last_name': 'Mukasa', 'phone': '+256771234567', 'address': 'Plot 45, Kiwatule, Kampala'},
                'children': [
                    {'first_name': 'Daniel', 'last_name': 'Mukasa', 'grade': 'Primary 5', 'age': 10, 'bus': buses[0]},
                    {'first_name': 'Diana', 'last_name': 'Mukasa', 'grade': 'Primary 3', 'age': 8, 'bus': buses[0]},
                ]
            },
            {
                'parent': {'first_name': 'Mary', 'last_name': 'Nalubega', 'phone': '+256772345678', 'address': 'House 12, Ntinda, Kampala'},
                'children': [
                    {'first_name': 'Mariam', 'last_name': 'Nalubega', 'grade': 'Primary 6', 'age': 11, 'bus': buses[0]},
                ]
            },
            {
                'parent': {'first_name': 'John', 'last_name': 'Ssebunya', 'phone': '+256773456789', 'address': 'Block 8, Bugolobi, Kampala'},
                'children': [
                    {'first_name': 'Joshua', 'last_name': 'Ssebunya', 'grade': 'Primary 4', 'age': 9, 'bus': buses[1]},
                    {'first_name': 'Joy', 'last_name': 'Ssebunya', 'grade': 'Primary 2', 'age': 7, 'bus': buses[1]},
                ]
            },
            {
                'parent': {'first_name': 'Susan', 'last_name': 'Nakabugo', 'phone': '+256774567890', 'address': 'Flat 3, Kololo, Kampala'},
                'children': [
                    {'first_name': 'Samuel', 'last_name': 'Nakabugo', 'grade': 'Primary 5', 'age': 10, 'bus': buses[1]},
                ]
            },
            {
                'parent': {'first_name': 'Robert', 'last_name': 'Kato', 'phone': '+256775678901', 'address': 'Villa 7, Muyenga, Kampala'},
                'children': [
                    {'first_name': 'Ruth', 'last_name': 'Kato', 'grade': 'Primary 3', 'age': 8, 'bus': buses[2]},
                    {'first_name': 'Ronald', 'last_name': 'Kato', 'grade': 'Primary 1', 'age': 6, 'bus': buses[2]},
                ]
            },
            {
                'parent': {'first_name': 'Grace', 'last_name': 'Namusoke', 'phone': '+256776789012', 'address': 'House 23, Nakasero, Kampala'},
                'children': [
                    {'first_name': 'Gloria', 'last_name': 'Namusoke', 'grade': 'Primary 6', 'age': 11, 'bus': buses[2]},
                ]
            },
        ]

        children_list = []
        for data in parents_children_data:
            # Create parent user
            parent_data = data['parent']
            parent_user = User.objects.create_user(
                username=f"{parent_data['first_name'].lower()}.{parent_data['last_name'].lower()}@parent.ug",
                email=f"{parent_data['first_name'].lower()}.{parent_data['last_name'].lower()}@parent.ug",
                password='parent123',
                first_name=parent_data['first_name'],
                last_name=parent_data['last_name'],
                user_type='parent'
            )
            parent = Parent.objects.create(
                user=parent_user,
                contact_number=parent_data['phone'],
                address=parent_data['address'],
                emergency_contact=parent_data['phone'],
                status='active'
            )

            # Create children
            for child_data in data['children']:
                child = Child.objects.create(
                    first_name=child_data['first_name'],
                    last_name=child_data['last_name'],
                    class_grade=child_data['grade'],
                    age=child_data['age'],
                    parent=parent,
                    assigned_bus=child_data['bus'],
                    status='active'
                )
                children_list.append(child)

        # Create Trips with Ugandan locations
        self.stdout.write('Creating trips...')

        # Morning Pickup Trips
        today = timezone.now().replace(hour=6, minute=30, second=0, microsecond=0)

        # Trip 1: SMU-001 Morning Pickup (Kiwatule - Ntinda Route)
        trip1 = Trip.objects.create(
            bus=buses[0],
            driver=drivers[0],
            bus_minder=minders[0],
            route='Kiwatule - Ntinda - Nakawa Route',
            trip_type='pickup',
            status='scheduled',
            scheduled_time=today,
            current_latitude=0.3476,
            current_longitude=32.5825
        )
        trip1.children.set([children_list[0], children_list[1], children_list[2]])

        # Create stops for Trip 1
        Stop.objects.create(
            trip=trip1,
            address='Kiwatule Trading Center, Kampala',
            latitude=0.3665,
            longitude=32.6208,
            scheduled_time=today + timedelta(minutes=10),
            status='pending',
            order=1
        ).children.set([children_list[0], children_list[1]])

        Stop.objects.create(
            trip=trip1,
            address='Ntinda Shopping Center, Kampala',
            latitude=0.3548,
            longitude=32.6115,
            scheduled_time=today + timedelta(minutes=20),
            status='pending',
            order=2
        ).children.set([children_list[2]])

        Stop.objects.create(
            trip=trip1,
            address='St. Mary\'s School, Nakawa',
            latitude=0.3296,
            longitude=32.6100,
            scheduled_time=today + timedelta(minutes=35),
            status='pending',
            order=3
        )

        # Trip 2: SMU-002 Morning Pickup (Bugolobi - Kololo Route)
        trip2 = Trip.objects.create(
            bus=buses[1],
            driver=drivers[1],
            bus_minder=minders[1],
            route='Bugolobi - Kololo - Nakawa Route',
            trip_type='pickup',
            status='in-progress',
            scheduled_time=today + timedelta(minutes=15),
            start_time=today + timedelta(minutes=15),
            current_latitude=0.3157,
            current_longitude=32.6053
        )
        trip2.children.set([children_list[3], children_list[4], children_list[5]])

        Stop.objects.create(
            trip=trip2,
            address='Bugolobi Plaza, Kampala',
            latitude=0.3157,
            longitude=32.6053,
            scheduled_time=today + timedelta(minutes=25),
            actual_time=today + timedelta(minutes=26),
            status='completed',
            order=1
        ).children.set([children_list[3], children_list[4]])

        Stop.objects.create(
            trip=trip2,
            address='Kololo Hill, Kampala',
            latitude=0.3321,
            longitude=32.5994,
            scheduled_time=today + timedelta(minutes=35),
            status='pending',
            order=2
        ).children.set([children_list[5]])

        Stop.objects.create(
            trip=trip2,
            address='St. Mary\'s School, Nakawa',
            latitude=0.3296,
            longitude=32.6100,
            scheduled_time=today + timedelta(minutes=50),
            status='pending',
            order=3
        )

        # Trip 3: SMU-003 Morning Pickup (Muyenga - Nakasero Route)
        trip3 = Trip.objects.create(
            bus=buses[2],
            driver=drivers[2],
            bus_minder=minders[2],
            route='Muyenga - Nakasero - Nakawa Route',
            trip_type='pickup',
            status='scheduled',
            scheduled_time=today + timedelta(minutes=20),
            current_latitude=0.2827,
            current_longitude=32.6011
        )
        trip3.children.set([children_list[6], children_list[7], children_list[8]])

        Stop.objects.create(
            trip=trip3,
            address='Muyenga Tank Hill Road, Kampala',
            latitude=0.2827,
            longitude=32.6011,
            scheduled_time=today + timedelta(minutes=30),
            status='pending',
            order=1
        ).children.set([children_list[6], children_list[7]])

        Stop.objects.create(
            trip=trip3,
            address='Nakasero Market, Kampala',
            latitude=0.3218,
            longitude=32.5779,
            scheduled_time=today + timedelta(minutes=45),
            status='pending',
            order=2
        ).children.set([children_list[8]])

        Stop.objects.create(
            trip=trip3,
            address='St. Mary\'s School, Nakawa',
            latitude=0.3296,
            longitude=32.6100,
            scheduled_time=today + timedelta(minutes=60),
            status='pending',
            order=3
        )

        # Afternoon Dropoff Trips
        afternoon = timezone.now().replace(hour=15, minute=0, second=0, microsecond=0)

        # Trip 4: SMU-001 Afternoon Dropoff
        trip4 = Trip.objects.create(
            bus=buses[0],
            driver=drivers[0],
            bus_minder=minders[0],
            route='School - Ntinda - Kiwatule Dropoff',
            trip_type='dropoff',
            status='scheduled',
            scheduled_time=afternoon,
            current_latitude=0.3296,
            current_longitude=32.6100
        )
        trip4.children.set([children_list[0], children_list[1], children_list[2]])

        Stop.objects.create(
            trip=trip4,
            address='St. Mary\'s School, Nakawa',
            latitude=0.3296,
            longitude=32.6100,
            scheduled_time=afternoon,
            status='pending',
            order=1
        )

        Stop.objects.create(
            trip=trip4,
            address='Ntinda Shopping Center, Kampala',
            latitude=0.3548,
            longitude=32.6115,
            scheduled_time=afternoon + timedelta(minutes=15),
            status='pending',
            order=2
        ).children.set([children_list[2]])

        Stop.objects.create(
            trip=trip4,
            address='Kiwatule Trading Center, Kampala',
            latitude=0.3665,
            longitude=32.6208,
            scheduled_time=afternoon + timedelta(minutes=25),
            status='pending',
            order=3
        ).children.set([children_list[0], children_list[1]])

        # Trip 5: Completed yesterday dropoff
        yesterday = timezone.now() - timedelta(days=1)
        yesterday = yesterday.replace(hour=15, minute=0, second=0, microsecond=0)

        trip5 = Trip.objects.create(
            bus=buses[1],
            driver=drivers[1],
            bus_minder=minders[1],
            route='School - Kololo - Bugolobi Dropoff',
            trip_type='dropoff',
            status='completed',
            scheduled_time=yesterday,
            start_time=yesterday,
            end_time=yesterday + timedelta(minutes=45)
        )
        trip5.children.set([children_list[3], children_list[4], children_list[5]])

        self.stdout.write(self.style.SUCCESS(' Successfully created Uganda school demo data!'))
        self.stdout.write(self.style.SUCCESS(f'Created {User.objects.count()} users'))
        self.stdout.write(self.style.SUCCESS(f'Created {Bus.objects.count()} buses'))
        self.stdout.write(self.style.SUCCESS(f'Created {Parent.objects.count()} parents'))
        self.stdout.write(self.style.SUCCESS(f'Created {Child.objects.count()} children'))
        self.stdout.write(self.style.SUCCESS(f'Created {Trip.objects.count()} trips'))
        self.stdout.write(self.style.SUCCESS(f'Created {Stop.objects.count()} stops'))
        self.stdout.write('')
        self.stdout.write('Login credentials:')
        self.stdout.write('  Admin: admin@stmarys.ug / admin123')
        self.stdout.write('  Driver: moses.okello@stmarys.ug / driver123')
        self.stdout.write('  Parent: david.mukasa@parent.ug / parent123')
