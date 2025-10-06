#!/usr/bin/env python
"""
Script to create a test parent with children for ParentsApp testing
"""
import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'apo_basi.settings')
django.setup()

from django.contrib.auth import get_user_model
from parents.models import Parent
from children.models import Child
from buses.models import Bus

User = get_user_model()

def create_test_parent():
    phone = "0776102830"

    # Check if parent already exists
    if Parent.objects.filter(contact_number=phone).exists():
        print(f"Parent with phone {phone} already exists!")
        parent = Parent.objects.get(contact_number=phone)
        print(f"Parent User ID: {parent.user.id}")
        print(f"Parent Username: {parent.user.username}")
        children = Child.objects.filter(parent=parent)
        print(f"Children count: {children.count()}")
        for child in children:
            print(f"  - {child.first_name} {child.last_name} ({child.class_grade})")
        return

    # Create user for parent
    user = User.objects.create_user(
        username=f'parent_{phone}',
        email='testparent@apobasi.com',
        password='testpass123',
        first_name='John',
        last_name='Doe'
    )

    # Create parent profile
    parent = Parent.objects.create(
        user=user,
        contact_number=phone,
        address='Kampala, Uganda',
        emergency_contact='0777123456',
        status='active'
    )

    print(f"✅ Created parent: {user.get_full_name()} ({phone})")

    # Create test bus if it doesn't exist
    bus, created = Bus.objects.get_or_create(
        number_plate='UAH 123X',
        defaults={
            'capacity': 30,
            'model': 'Toyota Coaster',
            'is_active': True
        }
    )
    if created:
        print(f"✅ Created bus: {bus.number_plate}")

    # Create children
    children_data = [
        {'first_name': 'Alice', 'last_name': 'Doe', 'class_grade': 'Primary 5', 'age': 10},
        {'first_name': 'Bob', 'last_name': 'Doe', 'class_grade': 'Primary 3', 'age': 8},
    ]

    for child_data in children_data:
        child = Child.objects.create(
            parent=parent,
            assigned_bus=bus,
            **child_data
        )
        print(f"✅ Created child: {child.first_name} {child.last_name} ({child.class_grade})")

    print("\n" + "="*50)
    print("TEST LOGIN CREDENTIALS:")
    print("="*50)
    print(f"Phone Number: {phone}")
    print(f"OTP: Any 6 digits (e.g., 123456)")
    print("="*50)

if __name__ == '__main__':
    create_test_parent()
