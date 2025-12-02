from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
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
    permission_classes = [IsAuthenticated]
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
    permission_classes = [IsAuthenticated]
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
from assignments.models import Assignment
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
        # Get bus minder object
        try:
            busminder = BusMinder.objects.get(user=request.user)
        except BusMinder.DoesNotExist:
            return Response({
                "message": "Bus minder profile not found",
                "buses": []
            }, status=status.HTTP_404_NOT_FOUND)

        # Get all buses assigned to this bus minder using Assignment API
        bus_assignments = Assignment.get_active_assignments_for(busminder, 'minder_to_bus')

        buses_data = []
        for bus_assignment in bus_assignments:
            bus = bus_assignment.assigned_to

            # Get children assigned to this bus using Assignment API
            child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')
            children_data = [{
                "id": ca.assignee.id,
                "name": f"{ca.assignee.first_name} {ca.assignee.last_name}",
                "class_grade": ca.assignee.class_grade,
            } for ca in child_assignments]

            buses_data.append({
                "id": bus.id,
                "bus_number": bus.bus_number,
                "number_plate": bus.number_plate,
                "is_active": bus.is_active,
                "current_location": bus.current_location,
                "latitude": str(bus.latitude) if bus.latitude else None,
                "longitude": str(bus.longitude) if bus.longitude else None,
                "children_count": len(children_data),
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
        # Get the bus minder
        try:
            busminder = BusMinder.objects.get(user=request.user)
        except BusMinder.DoesNotExist:
            return Response(
                {"error": "Bus minder profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get the bus
        bus = get_object_or_404(Bus, id=bus_id)

        # Verify this bus minder is assigned to this bus using Assignment API
        minder_assignment = Assignment.get_active_assignments_for(busminder, 'minder_to_bus').filter(
            assigned_to_object_id=bus.id
        ).first()

        if not minder_assignment:
            return Response(
                {"error": "You can only view children for buses you manage"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get all children assigned to this bus using Assignment API
        child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')

        # Get today's date
        today = date.today()

        children_data = []
        for child_assignment in child_assignments:
            child = child_assignment.assignee  # Use assignee from Assignment

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
        trip_type = request.data.get('trip_type')  # 'pickup' or 'dropoff'

        if not child_id or not new_status:
            return Response(
                {"error": "child_id and status are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate status
        valid_statuses = ['pending', 'picked_up', 'dropped_off', 'absent']
        if new_status not in valid_statuses:
            return Response(
                {"error": f"Invalid status. Must be one of: {', '.join(valid_statuses)}"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate trip_type if provided
        if trip_type and trip_type not in ['pickup', 'dropoff']:
            return Response(
                {"error": "trip_type must be either 'pickup' or 'dropoff'"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Auto-detect trip_type from status if not provided
        if not trip_type:
            if new_status == 'picked_up':
                trip_type = 'pickup'
            elif new_status == 'dropped_off':
                trip_type = 'dropoff'

        # Get the child
        child = get_object_or_404(Child, id=child_id)

        # Get bus minder
        try:
            busminder = BusMinder.objects.get(user=request.user)
        except BusMinder.DoesNotExist:
            return Response(
                {"error": "Bus minder profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get child's bus assignment using Assignment API
        child_bus_assignment = Assignment.get_active_assignments_for(child, 'child_to_bus').first()

        if not child_bus_assignment:
            return Response(
                {"error": "This child is not assigned to any bus"},
                status=status.HTTP_400_BAD_REQUEST
            )

        bus = child_bus_assignment.assigned_to

        # Verify the bus minder is assigned to this child's bus using Assignment API
        minder_assignment = Assignment.get_active_assignments_for(busminder, 'minder_to_bus').filter(
            assigned_to_object_id=bus.id
        ).first()

        if not minder_assignment:
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
                'bus': bus,
                'status': new_status,
                'trip_type': trip_type,
                'marked_by': request.user,
                'notes': notes or '',  # Ensure notes is never None
            }
        )

        # If attendance already exists, update it
        if not created:
            attendance.status = new_status
            attendance.trip_type = trip_type
            attendance.marked_by = request.user
            attendance.notes = notes or ''  # Ensure notes is never None
            attendance.save()

        # Create notification for parent when pickup or dropoff is confirmed
        if child.parent and new_status in ['picked_up', 'dropped_off']:
            from notifications.views import create_notification

            # Determine notification type and message
            if new_status == 'picked_up':
                notification_type = 'pickup_confirmed'
                title = f"{child.first_name} Picked Up"
                message = f"Your child {child.first_name} {child.last_name} has been safely picked up by the bus at {attendance.timestamp.strftime('%I:%M %p')}."
            else:  # dropped_off
                notification_type = 'dropoff_complete'
                title = f"{child.first_name} Dropped Off"
                message = f"Your child {child.first_name} {child.last_name} has been safely dropped off at {attendance.timestamp.strftime('%I:%M %p')}."

            # Create the notification
            try:
                create_notification(
                    parent=child.parent,
                    notification_type=notification_type,
                    title=title,
                    message=message,
                    related_object=attendance
                )
            except Exception as e:
                # Log error but don't fail the attendance marking
                print(f"Failed to create notification: {e}")

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
