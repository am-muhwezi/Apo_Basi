"""Unified authentication views for all user types."""

import logging
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from drivers.models import Driver
from busminders.models import BusMinder
from assignments.models import Assignment
from datetime import date

logger = logging.getLogger(__name__)


@api_view(['POST'])
@permission_classes([AllowAny])
def unified_phone_login(request):
    """
    Unified phone-based login for both drivers and bus minders.
    Automatically detects user type and returns appropriate data.

    POST /api/auth/phone-login/
    Body: {"phone_number": "0773882123"}

    Returns:
    {
        "success": true,
        "user_type": "driver" | "busminder",
        "user_id": 5,
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "0773882123",
        "license_number": "...",
        "license_expiry": "...",
        "tokens": {"access": "...", "refresh": "..."},
        "bus": {...},
        "route": {...}
    }
    """
    phone_number = request.data.get("phone_number")

    if not phone_number:
        return Response({"error": "Phone number required"}, status=400)

    phone_number = phone_number.strip()

    # Try to find driver first
    try:
        driver = Driver.objects.select_related('user').get(phone_number=phone_number)
        user = driver.user

        # Generate tokens
        refresh = RefreshToken.for_user(user)

        # Get bus and route data
        bus_data = None
        route_data = None

        assignment = Assignment.get_active_assignments_for(driver, 'driver_to_bus').first()

        if assignment:
            bus = assignment.assigned_to

            # Get children assigned to this bus
            child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')
            today = date.today()

            children_data = []
            for child_assignment in child_assignments:
                child = child_assignment.assignee
                child_data = {
                    "id": child.id,
                    "name": f"{child.first_name} {child.last_name}",
                    "grade": child.class_grade,
                    "status": child.status,
                }
                children_data.append(child_data)

            bus_data = {
                "id": bus.id,
                "bus_number": bus.bus_number,
                "number_plate": bus.number_plate,
                "capacity": bus.capacity,
                "is_active": bus.is_active,
                "children": children_data,
            }

            # Get route if assigned
            route_assignment = Assignment.get_active_assignments_for(bus, 'bus_to_route').first()
            if route_assignment:
                route = route_assignment.assigned_to
                route_data = {
                    "id": route.id,
                    "name": route.name,
                    "route_code": route.route_code,
                }

        return Response({
            "success": True,
            "user_type": "driver",
            "user_id": user.id,
            "name": user.get_full_name() or "Driver",
            "email": user.email,
            "phone": phone_number,
            "license_number": driver.license_number,
            "license_expiry": driver.license_expiry.isoformat() if driver.license_expiry else None,
            "tokens": {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            "bus": bus_data,
            "route": route_data,
        })

    except Driver.DoesNotExist:
        pass  # Try bus minder next

    # Try to find bus minder
    try:
        busminder = BusMinder.objects.select_related('user').get(phone_number=phone_number)
        user = busminder.user

        # Generate tokens
        refresh = RefreshToken.for_user(user)

        # Get assigned buses and routes
        assignments = Assignment.get_active_assignments_for(busminder, 'minder_to_bus')

        buses_data = []
        routes_data = []

        for assignment in assignments:
            bus = assignment.assigned_to

            # Get children for this bus
            child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')
            children_data = []

            for child_assignment in child_assignments:
                child = child_assignment.assignee
                child_data = {
                    "id": child.id,
                    "name": f"{child.first_name} {child.last_name}",
                    "grade": child.class_grade,
                    "status": child.status,
                }
                children_data.append(child_data)

            bus_data = {
                "id": bus.id,
                "bus_number": bus.bus_number,
                "number_plate": bus.number_plate,
                "capacity": bus.capacity,
                "is_active": bus.is_active,
                "children": children_data,
            }
            buses_data.append(bus_data)

            # Get route for this bus
            route_assignment = Assignment.get_active_assignments_for(bus, 'bus_to_route').first()
            if route_assignment:
                route = route_assignment.assigned_to
                route_data = {
                    "id": route.id,
                    "name": route.name,
                    "route_code": route.route_code,
                    "buses": [{"id": bus.id, "bus_number": bus.bus_number}],
                }
                # Check if route already in list
                if not any(r['id'] == route.id for r in routes_data):
                    routes_data.append(route_data)

        return Response({
            "success": True,
            "user_type": "busminder",
            "user_id": user.id,
            "name": user.get_full_name() or "Bus Minder",
            "email": user.email,
            "phone": phone_number,
            "license_number": None,
            "license_expiry": None,
            "tokens": {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            "buses": buses_data,  # Bus minders can have multiple buses
            "route": routes_data[0] if routes_data else None,  # Primary route
        })

    except BusMinder.DoesNotExist:
        pass  # Not found as either driver or bus minder

    # Not found as either driver or bus minder
    return Response(
        {
            "success": False,
            "error": "No driver or bus minder account found with this phone number. Please contact your administrator."
        },
        status=404
    )
