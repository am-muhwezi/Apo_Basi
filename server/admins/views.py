from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from users.models import User
from users.serializers import UserSerializer
from parents.models import Parent
from busminders.models import BusMinder
from .models import Admin
from .serializers import AdminSerializer, AdminCreateSerializer, AdminRegistrationSerializer

import uuid
from children.models import Child


@api_view(['POST'])
@permission_classes([AllowAny])
def admin_register(request):
    """Admin registration endpoint that returns JWT tokens"""
    serializer = AdminRegistrationSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.save()

    # Generate JWT tokens
    refresh = RefreshToken.for_user(user)

    return Response({
        'user': UserSerializer(user).data,
        'tokens': {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        },
        'message': 'Admin registered successfully'
    }, status=status.HTTP_201_CREATED)


# Admin CRUD Views
class AdminListCreateView(generics.ListCreateAPIView):
    """
    GET /api/admins/ - List all admins
    POST /api/admins/ - Create new admin
    """
    permission_classes = [permissions.IsAuthenticated]
    queryset = Admin.objects.select_related('user').all()

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return AdminCreateSerializer
        return AdminSerializer


class AdminDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/admins/{id}/ - Get admin details
    PUT /api/admins/{id}/ - Update admin
    PATCH /api/admins/{id}/ - Partial update admin
    DELETE /api/admins/{id}/ - Delete admin
    """
    permission_classes = [permissions.IsAuthenticated]
    queryset = Admin.objects.select_related('user').all()
    lookup_field = 'user_id'

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return AdminCreateSerializer
        return AdminSerializer


# Bus creation moved to /api/buses/ endpoint
# Use BusListCreateView from buses app instead


class AdminAddParentView(generics.CreateAPIView):
    permission_classes = [permissions.IsAuthenticated]  # Secured: requires authentication
    queryset = User.objects.all()

    def post(self, request, *args, **kwargs):
        """
        Business Logic: AdminAddParentView

        Purpose:
        - Allows an admin to create a new parent and their children in a single request.
        - Minimizes required fields for parent creation (first_name, last_name).
        - Accepts a list of children (each with first_name, last_name, class_grade).
        - Automatically generates a username and password for the parent for secure onboarding.
        - Returns the created parent credentials and children details for admin reference.

        Flow:
        1. Extract parent details and children list from request data.
        2. Parse children data if sent as a JSON string.
        3. Generate a unique username and secure password for the parent.
        4. Create the User and Parent profile in the database.
        5. For each child, create a Child record linked to the parent profile.
        6. Return a response containing parent credentials and children info.

        Business Value:
        - Streamlines onboarding for parents and their children by admins.
        - Ensures secure credential generation and association of children to parents.
        - Reduces manual steps and errors in bulk parent/child registration.
        """
        # Only require: first_name, last_name, children (list of {first_name, last_name, class_grade})
        parent_first = request.data.get("first_name")
        parent_last = request.data.get("last_name")
        children_data = request.data.get("children", [])
        if isinstance(children_data, str):
            import json

            children_data = json.loads(children_data)
        # Auto-generate username and password for parent
        username = f"parent_{uuid.uuid4().hex[:8]}"
        import secrets
        import string

        password = "".join(
            secrets.choice(string.ascii_letters + string.digits) for _ in range(12)
        )
        # Create User and Parent profile
        user = User.objects.create_user(
            username=username,
            password=password,
            first_name=parent_first,
            last_name=parent_last,
            user_type="parent",
        )
        parent_profile = Parent.objects.create(user=user)
        created_children = []
        # Create each child and link to parent
        for child in children_data:
            c = Child.objects.create(
                first_name=child.get("first_name"),
                last_name=child.get("last_name"),
                class_grade=child.get("class_grade"),
                parent=parent_profile,
            )
            created_children.append(
                {
                    "id": c.id,
                    "name": f"{c.first_name} {c.last_name}",
                    "class_grade": c.class_grade,
                }
            )
        # Return parent credentials and children info for admin onboarding
        return Response(
            {
                "parent": {
                    "id": user.id,
                    "name": f"{user.first_name} {user.last_name}",
                    "username": user.username,
                    "password": password,
                },
                "children": created_children,
                "message": "Parent and children added",
            },
            status=status.HTTP_201_CREATED,
        )


import uuid
from drivers.models import Driver


class AdminAddDriverView(generics.CreateAPIView):
    permission_classes = [permissions.IsAuthenticated]  # Secured: requires authentication
    queryset = User.objects.all()

    def post(self, request, *args, **kwargs):
        """
        Business Logic: AdminAddDriverView

        Purpose:
        - Allows an admin to create a new bus driver with minimal required fields.
        - Automatically generates a username and password for secure onboarding.
        - Returns driver credentials and details for admin reference.

        Flow:
        1. Extract driver details from request data.
        2. Generate a unique username and secure password for the driver.
        3. Create the User and Driver profile in the database.
        4. Return a response containing driver credentials and info.

        Business Value:
        - Streamlines driver onboarding and credential management.
        - Ensures secure credential generation and reduces manual errors.
        """
        # Only require: first_name, last_name, license_number, phone_number
        first_name = request.data.get("first_name")
        last_name = request.data.get("last_name")
        license_number = request.data.get("license_number")
        phone_number = request.data.get("phone_number")
        username = f"driver_{uuid.uuid4().hex[:8]}"
        import secrets
        import string

        password = "".join(
            secrets.choice(string.ascii_letters + string.digits) for _ in range(12)
        )
        user = User.objects.create_user(
            username=username,
            password=password,
            first_name=first_name,
            last_name=last_name,
            user_type="driver",
        )
        driver = Driver.objects.create(
            user=user, license_number=license_number, phone_number=phone_number
        )
        return Response(
            {
                "driver": {
                    "id": user.id,
                    "name": f"{user.first_name} {user.last_name}",
                    "license_number": driver.license_number,
                    "phone_number": driver.phone_number,
                    "username": user.username,
                    "password": password,
                },
                "message": "Driver added",
            },
            status=status.HTTP_201_CREATED,
        )


class AdminAddBusminderView(generics.CreateAPIView):
    permission_classes = [permissions.IsAuthenticated]  # Secured: requires authentication
    queryset = User.objects.all()

    def post(self, request, *args, **kwargs):
        """
        Business Logic: AdminAddBusminderView

        Purpose:
        - Allows an admin to create a new bus minder with minimal required fields.
        - Automatically generates a username and password for secure onboarding.
        - Returns bus minder credentials and details for admin reference.

        Flow:
        1. Extract bus minder details from request data.
        2. Generate a unique username and secure password for the bus minder.
        3. Create the User and BusMinder profile in the database.
        4. Return a response containing bus minder credentials and info.

        Business Value:
        - Streamlines bus minder onboarding and credential management.
        - Ensures secure credential generation and reduces manual errors.
        """
        # Only require: first_name, last_name, phone_number, email, id_number
        first_name = request.data.get("first_name")
        last_name = request.data.get("last_name")
        phone_number = request.data.get("phone_number")
        email = request.data.get("email")
        id_number = request.data.get("id_number")
        username = f"busminder_{uuid.uuid4().hex[:8]}"
        import secrets
        import string

        password = "".join(
            secrets.choice(string.ascii_letters + string.digits) for _ in range(12)
        )
        user = User.objects.create_user(
            username=username,
            password=password,
            first_name=first_name,
            last_name=last_name,
            user_type="busminder",
            email=email,
        )
        # Store id_number in BusMinder if you add the field, else ignore
        busminder = BusMinder.objects.create(user=user)
        # Optionally, save id_number and phone_number to user or busminder if you add those fields
        user.phone_number = phone_number
        user.save()
        return Response(
            {
                "busminder": {
                    "id": user.id,
                    "name": f"{user.first_name} {user.last_name}",
                    "phone_number": user.phone_number,
                    "email": user.email,
                    "id_number": id_number,
                    "username": user.username,
                    "password": password,
                },
                "message": "Busminder added",
            },
            status=status.HTTP_201_CREATED,
        )


from buses.models import Bus
from rest_framework.views import APIView
from django.db.models import Count, Q
from datetime import datetime, timedelta


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def dashboard_stats(request):
    """
    Dashboard statistics endpoint for admin panel.

    Returns comprehensive stats for:
    - Buses (total, active, maintenance, inactive)
    - Children (total, active, assigned to buses)
    - Users (parents, drivers, minders)
    - Recent activity
    """
    # Bus statistics
    total_buses = Bus.objects.count()
    active_buses = Bus.objects.filter(is_active=True).count()
    maintenance_buses = Bus.objects.filter(
        last_maintenance__isnull=False,
        is_active=False
    ).count()
    inactive_buses = total_buses - active_buses - maintenance_buses

    # Children statistics
    total_children = Child.objects.count()
    active_children = Child.objects.filter(status='active').count()
    children_with_bus = Child.objects.filter(assigned_bus__isnull=False).count()

    # User statistics
    total_parents = Parent.objects.count()
    total_drivers = User.objects.filter(user_type='driver').count()
    total_minders = User.objects.filter(user_type='busminder').count()
    total_admins = Admin.objects.count()

    # Calculate total capacity
    total_capacity = Bus.objects.aggregate(
        total=Count('id') * 40  # Default capacity approximation
    )['total'] or 0

    # Recent activity
    recent_activity = []

    # Get recent children (last 5)
    recent_children = Child.objects.order_by('-id')[:5]
    for child in recent_children:
        recent_activity.append({
            'id': f'child-{child.id}',
            'action': f'{child.first_name} {child.last_name} enrolled',
            'time': 'Recently',
            'type': 'info'
        })

    # Add active bus info
    active_buses_list = Bus.objects.filter(is_active=True).order_by('-last_updated')[:3]
    for bus in active_buses_list:
        recent_activity.append({
            'id': f'bus-{bus.id}',
            'action': f'Bus {bus.bus_number} is active on route',
            'time': bus.last_updated.strftime('%I:%M %p') if bus.last_updated else 'N/A',
            'type': 'success'
        })

    return Response({
        'buses': {
            'total': total_buses,
            'active': active_buses,
            'maintenance': maintenance_buses,
            'inactive': inactive_buses,
        },
        'children': {
            'total': total_children,
            'active': active_children,
            'with_bus': children_with_bus,
            'checked_in': active_children,  # Simplified for now
        },
        'users': {
            'parents': total_parents,
            'drivers': total_drivers,
            'minders': total_minders,
            'admins': total_admins,
        },
        'capacity': {
            'total': total_capacity,
            'students_onboard': children_with_bus,
        },
        'recent_activity': recent_activity[:5],
        'fleet_status': [
            {'status': 'Active', 'count': active_buses, 'color': 'green'},
            {'status': 'Maintenance', 'count': maintenance_buses, 'color': 'yellow'},
            {'status': 'Inactive', 'count': inactive_buses, 'color': 'gray'},
        ]
    })


class AdminAssignDriverToBusView(APIView):
    """
    Allows admin to assign a driver to a specific bus.

    Endpoint: POST /api/admin/assign-driver-to-bus/
    Body: {"driver_id": 1, "bus_id": 2}

    This is essential for managing which driver operates which bus.
    """

    permission_classes = [permissions.IsAuthenticated]  # Secured: requires authentication

    def post(self, request):
        """
        Business Logic: AdminAssignDriverToBusView

        Purpose:
        - Allows an admin to assign a driver to a specific bus.
        - Ensures only valid driver and bus IDs are used.
        - Updates the bus record to link the driver.

        Flow:
        1. Extract driver_id and bus_id from request data.
        2. Validate both IDs and fetch corresponding records.
        3. Assign the driver to the bus and save.
        4. Return a response confirming the assignment.

        Business Value:
        - Centralizes driver-bus assignment for operational management.
        - Prevents errors by validating IDs and existence.
        """
        driver_id = request.data.get("driver_id")
        bus_id = request.data.get("bus_id")

        if not driver_id or not bus_id:
            return Response(
                {"error": "driver_id and bus_id are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            driver_user = User.objects.get(id=driver_id, user_type="driver")
            bus = Bus.objects.get(id=bus_id)
        except User.DoesNotExist:
            return Response(
                {"error": "Driver not found"}, status=status.HTTP_404_NOT_FOUND
            )
        except Bus.DoesNotExist:
            return Response(
                {"error": "Bus not found"}, status=status.HTTP_404_NOT_FOUND
            )

        bus.driver = driver_user
        bus.save()

        return Response(
            {
                "message": f"Driver {driver_user.get_full_name()} assigned to bus {bus.number_plate}",
                "bus": {"id": bus.id, "number_plate": bus.number_plate},
                "driver": {
                    "id": driver_user.id,
                    "name": driver_user.get_full_name(),
                },
            },
            status=status.HTTP_200_OK,
        )


class AdminAssignBusMinderToBusView(APIView):
    """
    Allows admin to assign a bus minder to a specific bus.

    Endpoint: POST /api/admin/assign-busminder-to-bus/
    Body: {"busminder_id": 1, "bus_id": 2}

    Bus minders are responsible for marking attendance for children on their assigned bus.
    """

    permission_classes = [permissions.IsAuthenticated]  # Secured: requires authentication

    def post(self, request):
        """
        Business Logic: AdminAssignBusMinderToBusView

        Purpose:
        - Allows an admin to assign a bus minder to a specific bus.
        - Ensures only valid bus minder and bus IDs are used.
        - Updates the bus record to link the bus minder.

        Flow:
        1. Extract busminder_id and bus_id from request data.
        2. Validate both IDs and fetch corresponding records.
        3. Assign the bus minder to the bus and save.
        4. Return a response confirming the assignment.

        Business Value:
        - Centralizes bus minder-bus assignment for operational management.
        - Prevents errors by validating IDs and existence.
        """
        busminder_id = request.data.get("busminder_id")
        bus_id = request.data.get("bus_id")

        if not busminder_id or not bus_id:
            return Response(
                {"error": "busminder_id and bus_id are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            busminder_user = User.objects.get(id=busminder_id, user_type="busminder")
            bus = Bus.objects.get(id=bus_id)
        except User.DoesNotExist:
            return Response(
                {"error": "Bus Minder not found"}, status=status.HTTP_404_NOT_FOUND
            )
        except Bus.DoesNotExist:
            return Response(
                {"error": "Bus not found"}, status=status.HTTP_404_NOT_FOUND
            )

        bus.bus_minder = busminder_user
        bus.save()

        return Response(
            {
                "message": f"Bus Minder {busminder_user.get_full_name()} assigned to bus {bus.number_plate}",
                "bus": {"id": bus.id, "number_plate": bus.number_plate},
                "busminder": {
                    "id": busminder_user.id,
                    "name": busminder_user.get_full_name(),
                },
            },
            status=status.HTTP_200_OK,
        )


class AdminAssignChildToBusView(APIView):
    """
    Allows admin to assign a child to a specific bus.

    Endpoint: POST /api/admin/assign-child-to-bus/
    Body: {"child_id": 1, "bus_id": 2}

    This determines which bus a child rides and enables attendance tracking
    for that child on the assigned bus.
    """

    permission_classes = [permissions.IsAuthenticated]  # Secured: requires authentication

    def post(self, request):
        """
        Business Logic: AdminAssignChildToBusView

        Purpose:
        - Allows an admin to assign a child to a specific bus.
        - Ensures only valid child and bus IDs are used.
        - Updates the child record to link the assigned bus.

        Flow:
        1. Extract child_id and bus_id from request data.
        2. Validate both IDs and fetch corresponding records.
        3. Assign the bus to the child and save.
        4. Return a response confirming the assignment.

        Business Value:
        - Centralizes child-bus assignment for operational management and attendance tracking.
        - Prevents errors by validating IDs and existence.
        """
        child_id = request.data.get("child_id")
        bus_id = request.data.get("bus_id")

        if not child_id or not bus_id:
            return Response(
                {"error": "child_id and bus_id are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            child = Child.objects.get(id=child_id)
            bus = Bus.objects.get(id=bus_id)
        except Child.DoesNotExist:
            return Response(
                {"error": "Child not found"}, status=status.HTTP_404_NOT_FOUND
            )
        except Bus.DoesNotExist:
            return Response(
                {"error": "Bus not found"}, status=status.HTTP_404_NOT_FOUND
            )

        child.assigned_bus = bus
        child.save()

        return Response(
            {
                "message": f"Child {child.first_name} {child.last_name} assigned to bus {bus.number_plate}",
                "child": {
                    "id": child.id,
                    "name": f"{child.first_name} {child.last_name}",
                    "class_grade": child.class_grade,
                },
                "bus": {"id": bus.id, "number_plate": bus.number_plate},
            },
            status=status.HTTP_200_OK,
        )
