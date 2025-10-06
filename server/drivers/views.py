from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser, IsAuthenticated, AllowAny
from rest_framework import status, generics
from .models import Driver
from .serializers import DriverSerializer, DriverCreateSerializer
from users.models import User
from users.permissions import IsDriver
from buses.models import Bus
from children.models import Child
from attendance.models import Attendance
from datetime import date


class DriverListCreateView(generics.ListCreateAPIView):
    """
    GET /api/drivers/ - List all drivers
    POST /api/drivers/ - Create new driver
    """
    permission_classes = [AllowAny]
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
    permission_classes = [AllowAny]
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
    - Drivers can only see buses they are assigned to
    - Includes current location and active status
    - Shows list of all children assigned to the bus
    """
    permission_classes = [IsAuthenticated, IsDriver]

    def get(self, request):
        # Get buses where this driver is assigned
        buses = Bus.objects.filter(driver=request.user).prefetch_related('children')

        if not buses.exists():
            return Response({
                "message": "You are not assigned to any bus yet",
                "bus": None
            })

        # Usually a driver is assigned to one bus, but handle multiple
        buses_data = []
        for bus in buses:
            # Get children assigned to this bus
            children = bus.children.all()

            # Get today's date for attendance
            today = date.today()

            children_data = []
            for child in children:
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

            buses_data.append({
                "id": bus.id,
                "number_plate": bus.number_plate,
                "is_active": bus.is_active,
                "current_location": bus.current_location,
                "latitude": str(bus.latitude) if bus.latitude else None,
                "longitude": str(bus.longitude) if bus.longitude else None,
                "speed": bus.speed,
                "heading": bus.heading,
                "last_updated": bus.last_updated,
                "bus_minder": bus.bus_minder.get_full_name() if bus.bus_minder else None,
                "children_count": children.count(),
                "children": children_data,
            })

        return Response({
            "buses": buses_data if len(buses_data) > 1 else buses_data[0] if buses_data else None,
            "count": len(buses_data)
        })


class MyRouteView(APIView):
    """
    Allows a driver to view the route (list of children) on their bus.

    Endpoint: GET /api/drivers/my-route/
    Returns: List of children with pickup/dropoff information

    For junior devs:
    - Shows all children assigned to the driver's bus
    - Includes parent contact information for emergencies
    - Shows today's attendance status for each child
    """
    permission_classes = [IsAuthenticated, IsDriver]

    def get(self, request):
        # Get the driver's assigned bus
        buses = Bus.objects.filter(driver=request.user)

        if not buses.exists():
            return Response({
                "error": "You are not assigned to any bus",
            }, status=status.HTTP_404_NOT_FOUND)

        # Get the first bus (typically drivers are assigned to one bus)
        bus = buses.first()

        # Get all children on this bus
        children = Child.objects.filter(assigned_bus=bus).select_related('parent', 'parent__user')

        # Get today's date
        today = date.today()

        route_data = []
        for child in children:
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
                "child_name": f"{child.first_name} {child.last_name}",
                "class_grade": child.class_grade,
                "parent_name": child.parent.user.get_full_name() if child.parent else "N/A",
                "parent_contact": child.parent.contact_number if child.parent else "N/A",
                "parent_emergency": child.parent.emergency_contact if child.parent else "N/A",
                "attendance_status": attendance_status,
                "last_updated": attendance_timestamp,
            })

        return Response({
            "bus": {
                "id": bus.id,
                "number_plate": bus.number_plate,
                "is_active": bus.is_active,
            },
            "route": route_data,
            "total_children": len(route_data)
        })
