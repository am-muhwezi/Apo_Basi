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


class DriverListCreateView(generics.ListCreateAPIView):
    """
    GET /api/drivers/ - List all drivers
    POST /api/drivers/ - Create new driver
    """
    permission_classes = [IsAuthenticated]
    queryset = Driver.objects.select_related('user', 'assigned_bus').all()

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
    queryset = Driver.objects.select_related('user', 'assigned_bus').all()
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

        # Find active driver-to-bus assignment using the new assignments system
        bus_content_type = ContentType.objects.get_for_model(Bus)
        driver_content_type = ContentType.objects.get_for_model(Driver)

        assignment = Assignment.objects.filter(
            assignee_content_type=driver_content_type,
            assignee_object_id=driver.user_id,
            assigned_to_content_type=bus_content_type,
            status='active'
        ).first()

        if not assignment:
            return Response({
                "message": "You are not assigned to any bus yet",
                "bus": None
            })

        # Get the assigned bus
        bus = Bus.objects.get(id=assignment.assigned_to_object_id)

        # Get children assigned to this bus using assignments
        child_content_type = ContentType.objects.get_for_model(Child)
        child_assignments = Assignment.objects.filter(
            assigned_to_content_type=bus_content_type,
            assigned_to_object_id=bus.id,
            assignee_content_type=child_content_type,
            status='active'
        )

        # Get today's date for attendance
        today = date.today()

        children_data = []
        for child_assignment in child_assignments:
            child = Child.objects.get(id=child_assignment.assignee_object_id)

            # Get today's attendance status
            try:
                attendance = Attendance.objects.get(child=child, date=today)
                attendance_status = attendance.get_status_display()
            except Attendance.DoesNotExist:
                attendance_status = "Not marked"

            children_data.append({
                "id": child.id,
                "name": f"{child.first_name} {child.last_name}",
                "class_grade": child.class_grade,
                "parent_name": child.parent.user.get_full_name() if child.parent else "N/A",
                "attendance_status": attendance_status,
            })

        bus_data = {
            "id": bus.id,
            "bus_number": bus.bus_number,
            "number_plate": bus.number_plate,
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

        # Find active driver-to-bus assignment
        bus_content_type = ContentType.objects.get_for_model(Bus)
        driver_content_type = ContentType.objects.get_for_model(Driver)

        driver_assignment = Assignment.objects.filter(
            assignee_content_type=driver_content_type,
            assignee_object_id=driver.user_id,
            assigned_to_content_type=bus_content_type,
            status='active'
        ).first()

        if not driver_assignment:
            return Response({
                "error": "You are not assigned to any bus",
            }, status=status.HTTP_404_NOT_FOUND)

        # Get the assigned bus
        bus = Bus.objects.get(id=driver_assignment.assigned_to_object_id)

        # Get all children assigned to this bus
        child_content_type = ContentType.objects.get_for_model(Child)
        child_assignments = Assignment.objects.filter(
            assigned_to_content_type=bus_content_type,
            assigned_to_object_id=bus.id,
            assignee_content_type=child_content_type,
            status='active'
        ).select_related('assignee_content_type')

        # Get today's date
        today = date.today()

        route_data = []
        for child_assignment in child_assignments:
            child = Child.objects.select_related('parent', 'parent__user').get(
                id=child_assignment.assignee_object_id
            )

            # Get today's attendance
            try:
                attendance = Attendance.objects.get(child=child, date=today)
                attendance_status = attendance.get_status_display()
                attendance_timestamp = attendance.timestamp
            except Attendance.DoesNotExist:
                attendance_status = "Not marked"
                attendance_timestamp = None

            route_data.append({
                "id": child.id,
                "first_name": child.first_name,
                "last_name": child.last_name,
                "child_name": f"{child.first_name} {child.last_name}",
                "grade": child.class_grade,
                "class_grade": child.class_grade,
                "address": child.address if hasattr(child, 'address') else "N/A",
                "parent_name": child.parent.user.get_full_name() if child.parent else "N/A",
                "parent_contact": child.parent.contact_number if child.parent else "N/A",
                "emergency_contact": child.parent.emergency_contact if child.parent else "N/A",
                "attendance_status": attendance_status,
                "last_updated": attendance_timestamp,
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
@permission_classes([IsAuthenticated])
def driver_phone_login(request):
    """
    Simple phone-based login for drivers (passwordless).
    Driver must be created by admin first.

    POST /api/drivers/phone-login/
    Body: {"phone_number": "0773882123"}

    Returns:
    {
        "user_id": 5,
        "name": "John Doe",
        "phone": "0773882123",
        "tokens": {"access": "...", "refresh": "..."}
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

        return Response({
            "user_id": user.id,
            "name": user.get_full_name() or "Driver",
            "phone": phone_number,
            "tokens": {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            }
        })

    except Driver.DoesNotExist:
        return Response({"error": "Phone number not registered"}, status=404)
