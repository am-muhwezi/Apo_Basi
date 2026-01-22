import factory
import factory.fuzzy
from django.contrib.auth import get_user_model

from buses.models import Bus
from parents.models import Parent
from drivers.models import Driver
from busminders.models import BusMinder
from children.models import Child
from assignments.models import BusRoute

User = get_user_model()


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    username = factory.Sequence(lambda n: f'user{n}')
    user_type = 'parent'
    phone_number = factory.Sequence(lambda n: f'07{n:07d}')


class ParentFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Parent

    user = factory.SubFactory(UserFactory, user_type='parent')
    contact_number = factory.SelfAttribute('user.phone_number')


class DriverFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Driver

    user = factory.SubFactory(UserFactory, user_type='driver')
    license_number = factory.Faker('bothify', text='D-#####')
    phone_number = factory.SelfAttribute('user.phone_number')


class BusMinderFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = BusMinder

    user = factory.SubFactory(UserFactory, user_type='busminder')
    phone_number = factory.SelfAttribute('user.phone_number')


class BusFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Bus

    bus_number = factory.Sequence(lambda n: f'B{n}')
    number_plate = factory.Sequence(lambda n: f'PLATE-{n}')
    capacity = 40


class ChildFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Child

    first_name = factory.Faker('first_name')
    last_name = factory.Faker('last_name')
    class_grade = factory.Faker('random_element', elements=['1', '2', '3'])
    parent = factory.SubFactory(ParentFactory)


class BusRouteFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = BusRoute

    name = factory.Sequence(lambda n: f'Route {n}')
    route_code = factory.Sequence(lambda n: f'ROUTE_{n}')
    description = factory.Faker('text', max_nb_chars=100)
    is_active = True
