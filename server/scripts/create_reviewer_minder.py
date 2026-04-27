#!/usr/bin/env python
"""
Creates the Apple reviewer BusMinder account for DriversandMinders demo login.

Credentials are controlled by env vars:
  REVIEWER_MINDER_EMAIL    (default: reviewer.minder@apobasi.com)
  REVIEWER_MINDER_PASSWORD (default: AppleReview2026)

Run from server/:
  python scripts/create_reviewer_minder.py
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'apo_basi.settings')
django.setup()

from django.contrib.auth import get_user_model
from busminders.models import BusMinder
from buses.models import Bus
from assignments.models import Assignment
from django.contrib.contenttypes.models import ContentType

User = get_user_model()

REVIEWER_EMAIL = os.environ.get('REVIEWER_MINDER_EMAIL', 'reviewer.minder@apobasi.com')
REVIEWER_PASSWORD = os.environ.get('REVIEWER_MINDER_PASSWORD', 'AppleReview2026')


def run():
    # ── User ────────────────────────────────────────────────────────────────
    user, created = User.objects.get_or_create(
        email__iexact=REVIEWER_EMAIL,
        defaults={
            'username': 'reviewer_minder',
            'email': REVIEWER_EMAIL,
            'first_name': 'Apple',
            'last_name': 'Reviewer Minder',
            'user_type': 'busminder',
            'phone_number': '+256700000003',
        },
    )
    if not created:
        print(f'ℹ️  User already exists: {user.email}')
    else:
        print(f'✅ Created user: {user.email}')

    user.set_password(REVIEWER_PASSWORD)
    user.save()
    print(f'✅ Password set')

    # ── BusMinder profile ────────────────────────────────────────────────────
    minder, m_created = BusMinder.objects.get_or_create(
        user=user,
        defaults={
            'phone_number': '+256700000003',
            'status': 'active',
        },
    )
    if not m_created:
        if minder.status != 'active':
            minder.status = 'active'
            minder.save()
        print(f'ℹ️  BusMinder profile already exists')
    else:
        print(f'✅ Created BusMinder profile')

    # ── Reuse the reviewer demo bus (created by create_reviewer_driver.py) ───
    bus = Bus.objects.filter(bus_number='REVIEW-BUS-01').first()
    if not bus:
        bus = Bus.objects.create(
            bus_number='REVIEW-BUS-01',
            number_plate='UAH 999R',
            capacity=40,
            model='Toyota Coaster',
            is_active=True,
        )
        print(f'✅ Created demo bus: {bus.bus_number}')
    else:
        print(f'ℹ️  Using existing bus: {bus.bus_number}')

    # ── Assignment: minder → bus ─────────────────────────────────────────────
    existing = Assignment.get_active_assignments_for(minder, 'minder_to_bus').first()
    if not existing:
        Assignment.objects.create(
            assignment_type='minder_to_bus',
            assignee_content_type=ContentType.objects.get_for_model(minder),
            assignee_object_id=minder.pk,
            assigned_to_content_type=ContentType.objects.get_for_model(bus),
            assigned_to_object_id=bus.pk,
            status='active',
        )
        print(f'✅ Assigned minder to bus {bus.bus_number}')
    else:
        print(f'ℹ️  Minder already assigned to a bus')

    print()
    print('=' * 50)
    print('REVIEWER BUSMINDER LOGIN CREDENTIALS')
    print('=' * 50)
    print(f'Email:    {REVIEWER_EMAIL}')
    print(f'Password: {REVIEWER_PASSWORD}')
    print('=' * 50)


if __name__ == '__main__':
    run()
