import logging
import requests
from jose import jwt, JWTError

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser, IsAuthenticated, AllowAny
from rest_framework import status, generics, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.tokens import RefreshToken
from django.conf import settings
from .models import Driver
from .serializers import DriverSerializer, DriverCreateSerializer
from users.models import User
from users.permissions import IsDriver
from buses.models import Bus
from children.models import Child
from attendance.models import Attendance
from assignments.models import Assignment, BusRoute
from datetime import date
from django.contrib.contenttypes.models import ContentType


logger = logging.getLogger(__name__)


class DriverListCreateView(generics.ListCreateAPIView):
    """
    GET /api/drivers/ - List all drivers
    POST /api/drivers/ - Create new driver
    """
    permission_classes = [IsAuthenticated]
    queryset = Driver.objects.select_related('user').order_by('user_id')
    filter_backends = [filters.SearchFilter]
    search_fields = ['user__first_name', 'user__last_name', 'user__email', 'phone']

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return DriverCreateSerializer
        return DriverSerializer


class DriverDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/drivers/{id}/ - Get driver details
    PUT /api/drivers/{id}/ - Update driver
    PATCH /api/drivers/{id}/ - Partial update driver
    DELETE /api/drivers/{id}/ - Delete driver
    """
    permission_classes = [IsAuthenticated]
    queryset = Driver.objects.select_related('user').all()
    lookup_field = 'user_id'

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return DriverCreateSerializer
        return DriverSerializer


class MyBusView(APIView):
    """
    Allows a driver to view their assigned bus and children on that bus.

    Endpoint: GET /api/drivers/my-bus/
    Returns: Details of the assigned bus with list of children

    For junior devs:
    - Uses the new assignments system to find driver's bus
    - Includes current location and active status
    - Shows list of all children assigned to the bus
    """
    permission_classes = [IsAuthenticated, IsDriver]

    def get(self, request):
        # Get driver object
        try:
            driver = Driver.objects.get(user=request.user)
        except Driver.DoesNotExist:
            return Response({
                "message": "Driver profile not found",
                "bus": None
            }, status=status.HTTP_404_NOT_FOUND)

        # Find active driver-to-bus assignment using Assignment API
        assignment = Assignment.get_active_assignments_for(driver, 'driver_to_bus').first()

        if not assignment:
            return Response({
                "message": "You are not assigned to any bus yet",
                "bus": None
            })

        # Get the assigned bus
        bus = assignment.assigned_to

        # Get children assigned to this bus using Assignment API
        child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')

        # Get today's date for attendance
        today = date.today()

        children_data = []
        for child_assignment in child_assignments:
            child = child_assignment.assignee  # Use the assignee from Assignment

            # Get today's attendance status for both pickup and dropoff
            pickup_attendance = Attendance.objects.filter(child=child, date=today, trip_type='pickup').first()
            dropoff_attendance = Attendance.objects.filter(child=child, date=today, trip_type='dropoff').first()

            children_data.append({
                "id": child.id,
                "name": f"{child.first_name} {child.last_name}",
                "class_grade": child.class_grade,
                "parent_name": child.parent.user.get_full_name() if child.parent else "N/A",
                "pickup_status": pickup_attendance.status if pickup_attendance else None,
                "pickup_status_display": pickup_attendance.get_status_display() if pickup_attendance else "Not marked",
                "dropoff_status": dropoff_attendance.status if dropoff_attendance else None,
                "dropoff_status_display": dropoff_attendance.get_status_display() if dropoff_attendance else "Not marked",
            })

        bus_data = {
            "id": bus.id,
            "bus_number": bus.bus_number,
            "number_plate": bus.number_plate,
            "capacity": bus.capacity,
            "is_active": bus.is_active,
            "current_location": bus.current_location,
            "latitude": str(bus.latitude) if bus.latitude else None,
            "longitude": str(bus.longitude) if bus.longitude else None,
            "speed": bus.speed,
            "heading": bus.heading,
            "last_updated": bus.last_updated,
            "children_count": len(children_data),
            "children": children_data,
        }

        return Response({
            "buses": bus_data,
            "count": 1
        })


class MyRouteView(APIView):
    """
    Allows a driver to view the route (list of children) on their bus.

    Endpoint: GET /api/drivers/my-route/
    Returns: List of children with pickup/dropoff information

    For junior devs:
    - Uses new assignments system to find driver's bus and children
    - Shows all children assigned to the driver's bus
    - Includes parent contact information for emergencies
    - Shows today's attendance status for each child
    """
    permission_classes = [IsAuthenticated, IsDriver]

    def get(self, request):
        # Get driver object
        try:
            driver = Driver.objects.get(user=request.user)
        except Driver.DoesNotExist:
            return Response({
                "error": "Driver profile not found",
            }, status=status.HTTP_404_NOT_FOUND)

        # Find active driver-to-bus assignment using Assignment API
        driver_assignment = Assignment.get_active_assignments_for(driver, 'driver_to_bus').first()

        if not driver_assignment:
            return Response({
                "error": "You are not assigned to any bus",
            }, status=status.HTTP_404_NOT_FOUND)

        # Get the assigned bus
        bus = driver_assignment.assigned_to

        # Resolve the driver's active route for this bus using BusRoute
        route_name = None
        estimated_duration = None

        # Prefer explicit bus_to_route assignments
        route_assignment = Assignment.get_active_assignments_for(bus, 'bus_to_route').first()
        if route_assignment:
            route_obj = route_assignment.assigned_to
            route_name = getattr(route_obj, 'name', None)
            duration_minutes = getattr(route_obj, 'estimated_duration', None)
            if duration_minutes is not None:
                estimated_duration = f"{duration_minutes} min"

        # Fallback to BusRoute.default_bus in case explicit assignment is missing
        if not route_name:
            fallback_route = BusRoute.objects.filter(default_bus=bus, is_active=True).first()
            if fallback_route:
                route_name = fallback_route.name
                if fallback_route.estimated_duration is not None:
                    estimated_duration = f"{fallback_route.estimated_duration} min"

        # Get all children assigned to this bus using Assignment API
        child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')

        # Get today's date
        today = date.today()

        route_data = []
        for child_assignment in child_assignments:
            child = child_assignment.assignee  # Use the assignee from Assignment

            # Get today's attendance for both pickup and dropoff
            pickup_attendance = Attendance.objects.filter(child=child, date=today, trip_type='pickup').first()
            dropoff_attendance = Attendance.objects.filter(child=child, date=today, trip_type='dropoff').first()

            # Get home address - prefer parent's address over child's optional address field
            home_address = "No address"
            if child.parent and child.parent.address:
                home_address = child.parent.address
            elif child.address:
                home_address = child.address

            route_data.append({
                "id": child.id,
                "first_name": child.first_name,
                "last_name": child.last_name,
                "child_name": f"{child.first_name} {child.last_name}",
                "grade": child.class_grade,
                "class_grade": child.class_grade,
                "address": home_address,
                "parent_name": child.parent.user.get_full_name() if child.parent else "N/A",
                "pickup_status": pickup_attendance.status if pickup_attendance else None,
                "pickup_status_display": pickup_attendance.get_status_display() if pickup_attendance else "Not marked",
                "pickup_timestamp": pickup_attendance.timestamp if pickup_attendance else None,
                "dropoff_status": dropoff_attendance.status if dropoff_attendance else None,
                "dropoff_status_display": dropoff_attendance.get_status_display() if dropoff_attendance else "Not marked",
                "dropoff_timestamp": dropoff_attendance.timestamp if dropoff_attendance else None,
                "parent_contact": child.parent.contact_number if child.parent else "N/A",
                "emergency_contact": child.parent.emergency_contact if child.parent else "N/A",
            })

        return Response({
            "bus_number": bus.bus_number,
            "route_name": route_name,
            "estimated_duration": estimated_duration,
            "bus": {
                "id": bus.id,
                "bus_number": bus.bus_number,
                "number_plate": bus.number_plate,
                "is_active": bus.is_active,
            },
            "children": route_data,
            "route": route_data,  # Keep for backwards compatibility
            "total_children": len(route_data)
        })


@api_view(['POST'])
@permission_classes([AllowAny])
def driver_phone_login(request):
    """
    Unified phone-based login for drivers (passwordless).
    Returns user, tokens, bus assignment, and route in a single response.

    POST /api/drivers/phone-login/
    Body: {"phone_number": "0773882123"}

    Returns:
    {
        "user_id": 5,
        "name": "John Doe",
        "phone": "0773882123",
        "tokens": {"access": "...", "refresh": "..."},
        "bus": {...},
        "route": {...}
    }
    """
    phone_number = request.data.get("phone_number")

    if not phone_number:
        return Response({"error": "Phone number required"}, status=400)

    # Find driver by phone number
    try:
        driver = Driver.objects.select_related('user').get(phone_number=phone_number.strip())
        user = driver.user

        # Generate tokens
        refresh = RefreshToken.for_user(user)

        # Get bus and route data (same logic as MyBusView and MyRouteView)
        bus_data = None
        route_data = None

        # Find active driver-to-bus assignment
        assignment = Assignment.get_active_assignments_for(driver, 'driver_to_bus').first()

        if assignment:
            bus = assignment.assigned_to

            # Resolve the driver's active route for this bus using BusRoute
            route_name = None
            estimated_duration = None

            route_assignment = Assignment.get_active_assignments_for(bus, 'bus_to_route').first()
            if route_assignment:
                route_obj = route_assignment.assigned_to
                route_name = getattr(route_obj, 'name', None)
                duration_minutes = getattr(route_obj, 'estimated_duration', None)
                if duration_minutes is not None:
                    estimated_duration = f"{duration_minutes} min"

            # Fallback to BusRoute.default_bus mapping if explicit assignment missing
            if not route_name:
                fallback_route = BusRoute.objects.filter(default_bus=bus, is_active=True).first()
                if fallback_route:
                    route_name = fallback_route.name
                    if fallback_route.estimated_duration is not None:
                        estimated_duration = f"{fallback_route.estimated_duration} min"

            # Get children assigned to this bus
            child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')

            # Get today's date for attendance
            today = date.today()

            children_data = []
            for child_assignment in child_assignments:
                child = child_assignment.assignee

                # Get today's attendance for both pickup and dropoff
                pickup_attendance = Attendance.objects.filter(child=child, date=today, trip_type='pickup').first()
                dropoff_attendance = Attendance.objects.filter(child=child, date=today, trip_type='dropoff').first()

                children_data.append({
                    "id": child.id,
                    "first_name": child.first_name,
                    "last_name": child.last_name,
                    "child_name": f"{child.first_name} {child.last_name}",
                    "name": f"{child.first_name} {child.last_name}",
                    "grade": child.class_grade,
                    "class_grade": child.class_grade,
                    "address": child.address if hasattr(child, 'address') else "N/A",
                    "parent_name": child.parent.user.get_full_name() if child.parent else "N/A",
                    "parent_contact": child.parent.contact_number if child.parent else "N/A",
                    "emergency_contact": child.parent.emergency_contact if child.parent else "N/A",
                    "pickup_status": pickup_attendance.status if pickup_attendance else None,
                    "pickup_status_display": pickup_attendance.get_status_display() if pickup_attendance else "Not marked",
                    "pickup_timestamp": pickup_attendance.timestamp if pickup_attendance else None,
                    "dropoff_status": dropoff_attendance.status if dropoff_attendance else None,
                    "dropoff_status_display": dropoff_attendance.get_status_display() if dropoff_attendance else "Not marked",
                    "dropoff_timestamp": dropoff_attendance.timestamp if dropoff_attendance else None,
                })

            bus_data = {
                "id": bus.id,
                "bus_number": bus.bus_number,
                "number_plate": bus.number_plate,
                "capacity": bus.capacity,
                "is_active": bus.is_active,
                "current_location": bus.current_location,
                "latitude": str(bus.latitude) if bus.latitude else None,
                "longitude": str(bus.longitude) if bus.longitude else None,
                "speed": bus.speed,
                "heading": bus.heading,
                "last_updated": bus.last_updated,
                "children_count": len(children_data),
                "children": children_data,
            }

            route_data = {
                "bus_number": bus.bus_number,
                "route_name": route_name,
                "estimated_duration": estimated_duration,
                "bus": {
                    "id": bus.id,
                    "bus_number": bus.bus_number,
                    "number_plate": bus.number_plate,
                    "is_active": bus.is_active,
                },
                "children": children_data,
                "route": children_data,
                "total_children": len(children_data)
            }

        return Response({
            "user_id": user.id,
            "name": user.get_full_name() or "Driver",
            "phone": phone_number,
            "email": user.email,
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
        return Response({"error": "Phone number not registered"}, status=404)


@api_view(['POST'])
@permission_classes([AllowAny])
def check_driver_email(request):
    """
    Check if an email is registered as a driver before sending magic link.

    POST /api/drivers/auth/check-email/
    Body: {"email": "driver@example.com"}

    Returns:
    {
        "registered": true/false,
        "message": "..."
    }
    """
    email = request.data.get('email')

    if not email:
        return Response(
            {"error": "email is required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Check if driver exists with this email
    try:
        driver = Driver.objects.select_related('user').get(
            user__email__iexact=email,  # Case-insensitive match
            status='active'
        )

        return Response(
            {
                "registered": True,
                "message": "Email is registered"
            },
            status=status.HTTP_200_OK
        )
    except Driver.DoesNotExist:
        return Response(
            {
                "registered": False,
                "message": "This email is not registered. Please contact your administrator to set up your account."
            },
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
@permission_classes([AllowAny])
def driver_magic_link_auth(request):
    """
    Exchange Supabase magic link session for Django JWT tokens (drivers).

    POST /api/drivers/auth/magic-link/
    Body: {"access_token": "supabase_jwt_token"}

    The magic link flow:
    1. Driver enters email in Flutter app
    2. Supabase sends magic link email
    3. Driver clicks link → opens app via deep linking
    4. Flutter extracts Supabase access_token
    5. Flutter sends token to this endpoint
    6. Django verifies token and returns Django JWT tokens + bus/route data
    """
    access_token = request.data.get('access_token')

    if not access_token:
        return Response(
            {"error": "access_token is required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        # Fetch JWKS (JSON Web Key Set) from Supabase
        jwks_response = requests.get(settings.SUPABASE_JWKS_URL, timeout=5)
        jwks_response.raise_for_status()
        jwks = jwks_response.json()

        # Verify and decode the Supabase JWT token
        payload = jwt.decode(
            access_token,
            jwks,
            algorithms=['ES256'],
            options={
                'verify_aud': False,  # Supabase uses different audience
                'verify_iss': True,
            }
        )

        email = payload.get('email')
        if not email:
            return Response(
                {"error": "Email not found in token"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if driver exists with this email
        try:
            driver = Driver.objects.select_related('user').get(
                user__email=email,
                status='active'
            )
            user = driver.user
        except Driver.DoesNotExist:
            return Response(
                {
                    "error": "No driver account found",
                    "message": "Your email is not registered. Please contact your administrator to set up your account."
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # Generate Django JWT tokens
        refresh = RefreshToken.for_user(user)

        # Get bus and route data (same as phone login)
        bus_data = None
        route_data = None

        # Find active driver-to-bus assignment
        assignment = Assignment.get_active_assignments_for(driver, 'driver_to_bus').first()

        if assignment:
            bus = assignment.assigned_to

            # Get children assigned to this bus
            child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')

            # Get today's date for attendance
            today = date.today()

            children_data = []
            for child_assignment in child_assignments:
                child = child_assignment.assignee

                # Get today's attendance for both pickup and dropoff
                pickup_attendance = Attendance.objects.filter(child=child, date=today, trip_type='pickup').first()
                dropoff_attendance = Attendance.objects.filter(child=child, date=today, trip_type='dropoff').first()

                children_data.append({
                    "id": child.id,
                    "first_name": child.first_name,
                    "last_name": child.last_name,
                    "child_name": f"{child.first_name} {child.last_name}",
                    "name": f"{child.first_name} {child.last_name}",
                    "grade": child.class_grade,
                    "class_grade": child.class_grade,
                    "address": child.address if hasattr(child, 'address') else "N/A",
                    "parent_name": child.parent.user.get_full_name() if child.parent else "N/A",
                    "parent_contact": child.parent.contact_number if child.parent else "N/A",
                    "emergency_contact": child.parent.emergency_contact if child.parent else "N/A",
                    "pickup_status": pickup_attendance.status if pickup_attendance else None,
                    "pickup_status_display": pickup_attendance.get_status_display() if pickup_attendance else "Not marked",
                    "pickup_timestamp": pickup_attendance.timestamp if pickup_attendance else None,
                    "dropoff_status": dropoff_attendance.status if dropoff_attendance else None,
                    "dropoff_status_display": dropoff_attendance.get_status_display() if dropoff_attendance else "Not marked",
                    "dropoff_timestamp": dropoff_attendance.timestamp if dropoff_attendance else None,
                })

            bus_data = {
                "id": bus.id,
                "bus_number": bus.bus_number,
                "number_plate": bus.number_plate,
                "capacity": bus.capacity,
                "is_active": bus.is_active,
                "current_location": bus.current_location,
                "latitude": str(bus.latitude) if bus.latitude else None,
                "longitude": str(bus.longitude) if bus.longitude else None,
                "speed": bus.speed,
                "heading": bus.heading,
                "last_updated": bus.last_updated,
                "children_count": len(children_data),
                "children": children_data,
            }

            route_data = {
                "bus_number": bus.bus_number,
                "route_name": f"Bus {bus.bus_number} Route",
                "estimated_duration": "45 minutes",
                "bus": {
                    "id": bus.id,
                    "bus_number": bus.bus_number,
                    "number_plate": bus.number_plate,
                    "is_active": bus.is_active,
                },
                "children": children_data,
                "route": children_data,
                "total_children": len(children_data)
            }

        return Response({
            "user_id": user.id,
            "name": user.get_full_name() or "Driver",
            "email": user.email,
            "phone": driver.phone_number,
            "license_number": driver.license_number,
            "license_expiry": driver.license_expiry.isoformat() if driver.license_expiry else None,
            "tokens": {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            "bus": bus_data,
            "route": route_data,
        }, status=status.HTTP_200_OK)

    except JWTError as e:
        logger.error(f"JWT verification failed: {str(e)}")
        return Response(
            {
                "error": "Invalid or expired token",
                "message": "Your session has expired. Please request a new magic link."
            },
            status=status.HTTP_401_UNAUTHORIZED
        )
    except requests.RequestException as e:
        logger.error(f"Failed to fetch JWKS: {str(e)}")
        return Response(
            {"error": "Authentication service unavailable"},
            status=status.HTTP_503_SERVICE_UNAVAILABLE
        )
    except Exception as e:
        logger.exception("Unexpected error during driver magic link auth")
        return Response(
            {
                "error": "Authentication failed",
                "message": "Something went wrong. Please try again."
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsDriver])
def start_trip(request):
    """
    Start a new trip for the driver.

    POST /api/drivers/start-trip/
    Body: {
        "trip_type": "pickup" or "dropoff"
    }

    Returns: Trip object with ID
    """
    from trips.models import Trip
    from trips.serializers import TripSerializer
    from django.utils import timezone

    try:
        driver = Driver.objects.get(user=request.user)
    except Driver.DoesNotExist:
        return Response({"error": "Driver profile not found"}, status=status.HTTP_404_NOT_FOUND)

    # Find driver's assigned bus
    assignment = Assignment.get_active_assignments_for(driver, 'driver_to_bus').first()
    if not assignment:
        return Response({"error": "You are not assigned to any bus"}, status=status.HTTP_400_BAD_REQUEST)

    bus = assignment.assigned_to

    # Check if there's already an active trip
    existing_trip = Trip.objects.filter(
        driver=driver.user,  # Trip.driver is a ForeignKey to User, not Driver
        bus=bus,
        status='in-progress'
    ).first()

    if existing_trip:
        return Response({
            "message": "Trip already in progress",
            "trip": TripSerializer(existing_trip).data
        })

    # Get trip type from request
    trip_type = request.data.get('trip_type', 'pickup')

    # Validate driver name
    if not driver.user.first_name or not driver.user.last_name:
        return Response({
            "error": "Driver name is missing",
            "message": "Your profile is incomplete. Please contact the administrator to set your full name."
        }, status=status.HTTP_400_BAD_REQUEST)

    # Get the actual route assignment from the bus
    route_assignment = Assignment.get_active_assignments_for(bus, 'bus_to_route').first()
    route_name = None
    if route_assignment:
        route_obj = route_assignment.assigned_to
        route_name = route_obj.name if hasattr(route_obj, 'name') else None

    # Validate route is assigned
    if not route_name:
        return Response({
            "error": "No route assigned",
            "message": "This bus has no route assigned. Please contact the administrator."
        }, status=status.HTTP_400_BAD_REQUEST)

    # Validate children are assigned to the bus
    child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')
    if not child_assignments.exists():
        return Response({
            "error": "No children assigned",
            "message": "This bus has no children assigned. Please contact the administrator."
        }, status=status.HTTP_400_BAD_REQUEST)

    # Create new trip
    now = timezone.now()
    trip = Trip.objects.create(
        bus=bus,
        driver=driver.user,  # Trip.driver is a ForeignKey to User, not Driver
        trip_type=trip_type,
        status='in-progress',
        scheduled_time=now,  # For driver-initiated trips, scheduled time = start time
        start_time=now,
        route=route_name  # Use actual admin-created route name
    )

    # Add all children from the bus to the trip (already validated above)
    for child_assignment in child_assignments:
        trip.children.add(child_assignment.assignee)

    return Response({
        "message": "Trip started successfully",
        "trip": TripSerializer(trip).data
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsDriver])
def end_trip(request, trip_id):
    """
    End an active trip.

    POST /api/drivers/end-trip/<trip_id>/
    Body: {
        "totalStudents": 10,
        "studentsCompleted": 8,
        "studentsAbsent": 2,
        "studentsPending": 0
    }
    """
    from trips.models import Trip
    from trips.serializers import TripSerializer
    from django.utils import timezone

    try:
        driver = Driver.objects.get(user=request.user)
    except Driver.DoesNotExist:
        return Response({"error": "Driver profile not found"}, status=status.HTTP_404_NOT_FOUND)

    try:
        trip = Trip.objects.get(pk=trip_id, driver=driver.user)  # Trip.driver is a ForeignKey to User
    except Trip.DoesNotExist:
        return Response({"error": "Trip not found"}, status=status.HTTP_404_NOT_FOUND)

    if trip.status != 'in-progress':
        return Response(
            {"error": "Only in-progress trips can be ended"},
            status=status.HTTP_400_BAD_REQUEST
        )

    trip.status = 'completed'
    trip.end_time = timezone.now()

    # Save attendance summary if provided
    if 'totalStudents' in request.data:
        trip.total_students = request.data.get('totalStudents')
    if 'studentsCompleted' in request.data:
        trip.students_completed = request.data.get('studentsCompleted')
    if 'studentsAbsent' in request.data:
        trip.students_absent = request.data.get('studentsAbsent')
    if 'studentsPending' in request.data:
        trip.students_pending = request.data.get('studentsPending')

    trip.save()

    # Update children's location_status for PICKUP trips only
    # Pickup trip ended → children have arrived at school
    # Dropoff status is already handled by bus assistant marking attendance
    if trip.trip_type == 'pickup':
        for child in trip.children.all():
            child.location_status = 'at-school'
            child.save(update_fields=['location_status'])

    return Response({
        "message": "Trip ended successfully",
        "trip": TripSerializer(trip).data
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsDriver])
def get_active_trip(request):
    """
    Get the current active trip for this driver.

    GET /api/drivers/active-trip/

    Returns: Trip object or null if no active trip
    """
    from trips.models import Trip
    from trips.serializers import TripSerializer

    try:
        driver = Driver.objects.get(user=request.user)
    except Driver.DoesNotExist:
        return Response({"error": "Driver profile not found"}, status=status.HTTP_404_NOT_FOUND)

    active_trip = Trip.objects.filter(
        driver=driver.user,  # Trip.driver is a ForeignKey to User
        status='in-progress'
    ).first()

    if active_trip:
        return Response({
            "trip": TripSerializer(active_trip).data
        })
    else:
        return Response({
            "trip": None,
            "message": "No active trip"
        })
