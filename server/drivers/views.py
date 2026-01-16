import logging

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser, IsAuthenticated, AllowAny
from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Driver
from .serializers import DriverSerializer, DriverCreateSerializer
from users.models import User
from users.permissions import IsDriver
from buses.models import Bus
from children.models import Child
from attendance.models import Attendance
from assignments.models import Assignment
from datetime import date
from django.contrib.contenttypes.models import ContentType


logger = logging.getLogger(__name__)


class DriverListCreateView(generics.ListCreateAPIView):
    """
    GET /api/drivers/ - List all drivers
    POST /api/drivers/ - Create new driver
    """
    permission_classes = [IsAuthenticated]
    queryset = Driver.objects.select_related('user').all()

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

            route_data.append({
                "id": child.id,
                "first_name": child.first_name,
                "last_name": child.last_name,
                "child_name": f"{child.first_name} {child.last_name}",
                "grade": child.class_grade,
                "class_grade": child.class_grade,
                "address": child.address if hasattr(child, 'address') else "N/A",
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
            "route_name": f"Bus {bus.bus_number} Route",
            "estimated_duration": "45 minutes",  # TODO: Calculate from actual route data
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

    # Create new trip
    now = timezone.now()
    trip = Trip.objects.create(
        bus=bus,
        driver=driver.user,  # Trip.driver is a ForeignKey to User, not Driver
        trip_type=trip_type,
        status='in-progress',
        scheduled_time=now,  # For driver-initiated trips, scheduled time = start time
        start_time=now,
        route=f"Bus {bus.bus_number} Route"  # Set route name
    )

    # Add all children from the bus to the trip
    child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')
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
