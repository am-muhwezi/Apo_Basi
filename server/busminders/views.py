from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.tokens import RefreshToken
from users.serializers import BusMinderRegistrationSerializer, UserSerializer
from .models import BusMinder
from .serializers import BusMinderSerializer, BusMinderCreateSerializer


class BusMinderListCreateView(generics.ListCreateAPIView):
    """
    GET /api/busminders/ - List all bus minders
    POST /api/busminders/ - Create new bus minder
    """
    permission_classes = [AllowAny]
    queryset = BusMinder.objects.select_related('user').prefetch_related('user__managed_buses').all()

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return BusMinderCreateSerializer
        return BusMinderSerializer


class BusMinderDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/busminders/{id}/ - Get bus minder details
    PUT /api/busminders/{id}/ - Update bus minder
    PATCH /api/busminders/{id}/ - Partial update bus minder
    DELETE /api/busminders/{id}/ - Delete bus minder
    """
    permission_classes = [AllowAny]
    queryset = BusMinder.objects.select_related('user').prefetch_related('user__managed_buses').all()
    lookup_field = 'user_id'

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return BusMinderCreateSerializer
        return BusMinderSerializer


class BusMinderRegistrationView(generics.CreateAPIView):
    serializer_class = BusMinderRegistrationSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Generate JWT tokens for the user
        refresh = RefreshToken.for_user(user)

        return Response(
            {
                "user": UserSerializer(user).data,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                },
                "message": "BusMinder registered successfully",
            },
            status=status.HTTP_201_CREATED,
        )


from users.permissions import IsBusMinder
from rest_framework.permissions import IsAuthenticated
from buses.models import Bus
from children.models import Child
from attendance.models import Attendance
from datetime import date
from django.shortcuts import get_object_or_404


class MyBusesView(APIView):
    """
    Allows a bus minder to view all buses assigned to them.

    Endpoint: GET /api/busminders/my-buses/
    Returns: List of buses assigned to this bus minder

    For junior devs:
    - Bus minders can only see buses they are assigned to
    - Includes list of children on each bus
    - Shows current location of each bus
    """
    permission_classes = [IsAuthenticated, IsBusMinder]

    def get(self, request):
        # Get all buses assigned to this bus minder
        buses = Bus.objects.filter(bus_minder=request.user).prefetch_related('children')

        buses_data = []
        for bus in buses:
            # Get children assigned to this bus
            children = bus.children.all()
            children_data = [{
                "id": child.id,
                "name": f"{child.first_name} {child.last_name}",
                "class_grade": child.class_grade,
            } for child in children]

            buses_data.append({
                "id": bus.id,
                "number_plate": bus.number_plate,
                "is_active": bus.is_active,
                "current_location": bus.current_location,
                "latitude": str(bus.latitude) if bus.latitude else None,
                "longitude": str(bus.longitude) if bus.longitude else None,
                "children_count": children.count(),
                "children": children_data,
            })

        return Response({
            "buses": buses_data,
            "count": len(buses_data)
        })


class BusChildrenView(APIView):
    """
    Allows a bus minder to view all children assigned to a specific bus.

    Endpoint: GET /api/busminders/buses/{bus_id}/children/
    Returns: List of children with their today's attendance status

    Security:
    - Bus minders can only view children for buses they manage
    """
    permission_classes = [IsAuthenticated, IsBusMinder]

    def get(self, request, bus_id):
        # Get the bus and verify it's assigned to this bus minder
        bus = get_object_or_404(Bus, id=bus_id)

        if bus.bus_minder != request.user:
            return Response(
                {"error": "You can only view children for buses you manage"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get all children assigned to this bus
        children = Child.objects.filter(assigned_bus=bus).select_related('parent', 'parent__user')

        # Get today's date
        today = date.today()

        children_data = []
        for child in children:
            # Get today's attendance if it exists
            try:
                attendance = Attendance.objects.get(child=child, date=today)
                attendance_status = attendance.status
                attendance_status_display = attendance.get_status_display()
            except Attendance.DoesNotExist:
                attendance_status = None
                attendance_status_display = "Not marked"

            children_data.append({
                "id": child.id,
                "first_name": child.first_name,
                "last_name": child.last_name,
                "class_grade": child.class_grade,
                "parent_name": child.parent.user.get_full_name() if child.parent else "N/A",
                "parent_phone": child.parent.contact_number if child.parent else "N/A",
                "attendance_status": attendance_status,
                "attendance_status_display": attendance_status_display,
            })

        return Response({
            "bus": {
                "id": bus.id,
                "number_plate": bus.number_plate,
            },
            "children": children_data,
            "total_children": len(children_data)
        })


class MarkAttendanceView(APIView):
    """
    Allows a bus minder to mark attendance for a child.

    Endpoint: POST /api/busminders/mark-attendance/
    Body: {
        "child_id": 1,
        "status": "on_bus",  # Options: not_on_bus, on_bus, at_school, on_way_home, dropped_off, absent
        "notes": "Optional notes"
    }

    For junior devs:
    - Creates or updates today's attendance record for a child
    - Only bus minders assigned to the child's bus can mark attendance
    - Automatically records who marked the attendance and when
    """
    permission_classes = [IsAuthenticated, IsBusMinder]

    def post(self, request):
        child_id = request.data.get('child_id')
        new_status = request.data.get('status')
        notes = request.data.get('notes', '')

        if not child_id or not new_status:
            return Response(
                {"error": "child_id and status are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate status
        valid_statuses = ['not_on_bus', 'on_bus', 'at_school', 'on_way_home', 'dropped_off', 'absent']
        if new_status not in valid_statuses:
            return Response(
                {"error": f"Invalid status. Must be one of: {', '.join(valid_statuses)}"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get the child
        child = get_object_or_404(Child, id=child_id)

        # Verify the child has a bus assigned
        if not child.assigned_bus:
            return Response(
                {"error": "This child is not assigned to any bus"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Verify the bus minder is assigned to this child's bus
        if child.assigned_bus.bus_minder != request.user:
            return Response(
                {"error": "You can only mark attendance for children on buses you manage"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get or create today's attendance record
        today = date.today()
        attendance, created = Attendance.objects.get_or_create(
            child=child,
            date=today,
            defaults={
                'bus': child.assigned_bus,
                'status': new_status,
                'marked_by': request.user,
                'notes': notes,
            }
        )

        # If attendance already exists, update it
        if not created:
            attendance.status = new_status
            attendance.marked_by = request.user
            attendance.notes = notes
            attendance.save()

        return Response({
            "message": f"Attendance marked as {attendance.get_status_display()}",
            "attendance": {
                "id": attendance.id,
                "child": f"{child.first_name} {child.last_name}",
                "status": attendance.get_status_display(),
                "date": attendance.date,
                "timestamp": attendance.timestamp,
                "notes": attendance.notes,
            }
        }, status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
def busminder_phone_login(request):
    """
    Simple phone-based login for bus minders (passwordless).
    Bus minder must be created by admin first.

    POST /api/busminders/phone-login/
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

    # Find bus minder by phone number
    try:
        busminder = BusMinder.objects.select_related('user').get(phone_number=phone_number.strip())
        user = busminder.user

        # Generate tokens
        refresh = RefreshToken.for_user(user)

        return Response({
            "user_id": user.id,
            "name": user.get_full_name() or "Bus Minder",
            "phone": phone_number,
            "tokens": {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            }
        })

    except BusMinder.DoesNotExist:
        return Response({"error": "Phone number not registered"}, status=404)
