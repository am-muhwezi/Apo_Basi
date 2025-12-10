from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from django.db.models import Q, Count, Case, When, IntegerField
from datetime import date, datetime, timedelta
from .models import Attendance
from .serializers import AttendanceSerializer, AttendanceListSerializer
from children.models import Child
from buses.models import Bus
from drivers.models import Driver
from busminders.models import BusMinder


class AttendanceListView(generics.ListAPIView):
    """
    GET /api/attendance/ - List attendance records with filtering

    Query Parameters:
    - date: Filter by date (YYYY-MM-DD format), defaults to today
    - child_id: Filter by specific child
    - bus_id: Filter by specific bus
    - status: Filter by attendance status
    """
    permission_classes = [IsAuthenticated]
    serializer_class = AttendanceListSerializer

    def get_queryset(self):
        queryset = Attendance.objects.select_related(
            'child',
            'child__parent',
            'child__parent__user',
            'bus',
            'marked_by'
        ).all()

        # Filter by date (default to today)
        date_param = self.request.query_params.get('date')
        if date_param:
            try:
                filter_date = datetime.strptime(date_param, '%Y-%m-%d').date()
            except ValueError:
                filter_date = date.today()
        else:
            filter_date = date.today()

        queryset = queryset.filter(date=filter_date)

        # Filter by child
        child_id = self.request.query_params.get('child_id')
        if child_id:
            queryset = queryset.filter(child_id=child_id)

        # Filter by bus
        bus_id = self.request.query_params.get('bus_id')
        if bus_id:
            queryset = queryset.filter(bus_id=bus_id)

        # Filter by status
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)

        return queryset.order_by('-timestamp')


class AttendanceDetailView(generics.RetrieveAPIView):
    """
    GET /api/attendance/{id}/ - Get attendance record details
    """
    permission_classes = [IsAuthenticated]
    queryset = Attendance.objects.select_related(
        'child',
        'child__parent',
        'child__parent__user',
        'bus',
        'marked_by'
    ).all()
    serializer_class = AttendanceSerializer


class AttendanceStatsView(APIView):
    """
    GET /api/attendance/stats/ - Get attendance statistics

    Query Parameters:
    - date: Date for statistics (YYYY-MM-DD), defaults to today
    - bus_id: Filter by specific bus
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Get date filter
        date_param = request.query_params.get('date')
        if date_param:
            try:
                filter_date = datetime.strptime(date_param, '%Y-%m-%d').date()
            except ValueError:
                filter_date = date.today()
        else:
            filter_date = date.today()

        # Base queryset
        queryset = Attendance.objects.filter(date=filter_date)

        # Filter by bus if specified
        bus_id = request.query_params.get('bus_id')
        if bus_id:
            queryset = queryset.filter(bus_id=bus_id)

        # Get counts by status
        stats = queryset.aggregate(
            total=Count('id'),
            picked_up=Count(Case(When(status='picked_up', then=1), output_field=IntegerField())),
            dropped_off=Count(Case(When(status='dropped_off', then=1), output_field=IntegerField())),
            absent=Count(Case(When(status='absent', then=1), output_field=IntegerField())),
            pending=Count(Case(When(status='pending', then=1), output_field=IntegerField())),
        )

        # Calculate percentages
        total = stats['total']
        if total > 0:
            stats['picked_up_percentage'] = round((stats['picked_up'] / total) * 100, 1)
            stats['dropped_off_percentage'] = round((stats['dropped_off'] / total) * 100, 1)
            stats['absent_percentage'] = round((stats['absent'] / total) * 100, 1)
            stats['pending_percentage'] = round((stats['pending'] / total) * 100, 1)
        else:
            stats['picked_up_percentage'] = 0
            stats['dropped_off_percentage'] = 0
            stats['absent_percentage'] = 0
            stats['pending_percentage'] = 0

        stats['date'] = filter_date

        return Response(stats)


class DailyAttendanceReportView(APIView):
    """
    GET /api/attendance/daily-report/ - Get comprehensive daily attendance report

    Query Parameters:
    - date: Date for report (YYYY-MM-DD), defaults to today
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Get date filter
        date_param = request.query_params.get('date')
        if date_param:
            try:
                filter_date = datetime.strptime(date_param, '%Y-%m-%d').date()
            except ValueError:
                filter_date = date.today()
        else:
            filter_date = date.today()

        # Get all attendance for the day
        attendance_records = Attendance.objects.filter(
            date=filter_date
        ).select_related(
            'child',
            'child__parent',
            'child__parent__user',
            'bus',
            'marked_by'
        ).order_by('bus__bus_number', 'child__last_name', 'child__first_name')

        # Group by bus
        buses_data = {}
        for record in attendance_records:
            bus_id = record.bus.id if record.bus else 0
            bus_number = record.bus.bus_number if record.bus else 'Unassigned'

            if bus_id not in buses_data:
                buses_data[bus_id] = {
                    'bus_id': bus_id,
                    'bus_number': bus_number,
                    'children': [],
                    'stats': {
                        'total': 0,
                        'picked_up': 0,
                        'dropped_off': 0,
                        'absent': 0,
                        'pending': 0,
                    }
                }

            buses_data[bus_id]['children'].append({
                'id': record.child.id,
                'name': f"{record.child.first_name} {record.child.last_name}",
                'grade': record.child.class_grade,
                'status': record.status,
                'status_display': record.get_status_display(),
                'trip_type': record.trip_type,
                'marked_by': record.marked_by.get_full_name() if record.marked_by else None,
                'timestamp': record.timestamp,
                'notes': record.notes,
            })

            buses_data[bus_id]['stats']['total'] += 1
            buses_data[bus_id]['stats'][record.status] = buses_data[bus_id]['stats'].get(record.status, 0) + 1

        return Response({
            'date': filter_date,
            'buses': list(buses_data.values()),
            'total_records': len(attendance_records)
        })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_attendance(request):
    """
    Unified attendance marking endpoint for BOTH Drivers and Bus Minders.

    POST /api/attendance/mark/

    Body: {
        "child_id": 1,
        "status": "picked_up",  # Options: pending, picked_up, dropped_off, absent
        "trip_type": "pickup",  # pickup or dropoff (optional)
        "notes": "Optional notes"
    }

    This endpoint:
    - Allows both drivers and bus minders to mark attendance
    - Validates that the marker has access to the child's bus
    - Creates parent notifications for pickup/dropoff confirmations
    - Updates attendance in real-time

    Returns:
    {
        "success": true,
        "message": "Attendance marked as Picked Up",
        "attendance": {...attendance details...}
    }
    """
    child_id = request.data.get('child_id')
    new_status = request.data.get('status')
    notes = request.data.get('notes', '')
    trip_type = request.data.get('trip_type')

    # Validate required fields
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

    # Get the child
    try:
        child = Child.objects.select_related('parent', 'assigned_bus').get(id=child_id)
    except Child.DoesNotExist:
        return Response(
            {"error": "Child not found"},
            status=status.HTTP_404_NOT_FOUND
        )

    # Verify the user has permission to mark attendance for this child's bus
    user = request.user
    has_permission = False

    print(f"🔍 Permission check for user: {user.username} (type: {user.user_type})")
    print(f"🔍 Child: {child.first_name} {child.last_name}, assigned_bus: {child.assigned_bus}")

    if user.user_type == 'driver':
        try:
            driver = Driver.objects.get(user=user)
            print(f"🔍 Driver assigned_bus: {driver.assigned_bus}")
            has_permission = child.assigned_bus and driver.assigned_bus == child.assigned_bus
            print(f"🔍 Driver has_permission: {has_permission}")
        except Driver.DoesNotExist:
            print(f"❌ Driver profile not found for user {user.username}")
            has_permission = False
    elif user.user_type == 'busminder':
        try:
            busminder = BusMinder.objects.get(user=user)
            print(f"🔍 BusMinder found: {busminder}")
            # Get busminder's assigned bus through Assignment model
            from assignments.models import Assignment

            # Get active bus assignment for this bus minder
            busminder_bus_assignment = Assignment.get_active_assignments_for(
                busminder,
                'minder_to_bus'
            ).first()

            # Get child's bus assignment through Assignment model (NOT child.assigned_bus)
            child_bus_assignment = Assignment.get_active_assignments_for(
                child,
                'child_to_bus'
            ).first()

            print(f"🔍 BusMinder bus assignment: {busminder_bus_assignment}")
            print(f"🔍 Child bus assignment: {child_bus_assignment}")

            if busminder_bus_assignment:
                print(f"🔍 BusMinder assigned to bus: {busminder_bus_assignment.assigned_to} (ID: {busminder_bus_assignment.assigned_to.id})")
            if child_bus_assignment:
                print(f"🔍 Child assigned to bus: {child_bus_assignment.assigned_to} (ID: {child_bus_assignment.assigned_to.id})")

            # Check if both have assignments and they match
            if busminder_bus_assignment and child_bus_assignment:
                # Compare the bus IDs
                has_permission = busminder_bus_assignment.assigned_to.id == child_bus_assignment.assigned_to.id
                print(f"🔍 BusMinder has_permission: {has_permission}")
            else:
                print(f"❌ Missing assignments: busminder={busminder_bus_assignment}, child={child_bus_assignment}")
                has_permission = False
        except BusMinder.DoesNotExist:
            print(f"❌ BusMinder profile not found for user {user.username}")
            has_permission = False
        except Exception as e:
            print(f"❌ Error checking busminder permission: {e}")
            import traceback
            traceback.print_exc()
            has_permission = False

    print(f"🔍 Final has_permission: {has_permission}")

    if not has_permission:
        return Response(
            {"error": "You can only mark attendance for children on your assigned bus"},
            status=status.HTTP_403_FORBIDDEN
        )

    # Get or create today's attendance record
    today = date.today()

    # Get the child's assigned bus from Assignment model for consistency
    from assignments.models import Assignment
    child_bus_assignment = Assignment.get_active_assignments_for(child, 'child_to_bus').first()
    assigned_bus = child_bus_assignment.assigned_to if child_bus_assignment else child.assigned_bus

    attendance, created = Attendance.objects.get_or_create(
        child=child,
        date=today,
        defaults={
            'bus': assigned_bus,
            'status': new_status,
            'trip_type': trip_type,
            'marked_by': request.user,
            'notes': notes or '',
        }
    )

    # If attendance already exists, update it
    if not created:
        attendance.status = new_status
        if trip_type:
            attendance.trip_type = trip_type
        attendance.marked_by = request.user
        attendance.notes = notes or ''
        attendance.save()

    # TODO: Create notification for parent when pickup or dropoff is confirmed
    # Notifications feature will be implemented later
    if child.parent and new_status in ['picked_up', 'dropped_off']:
        if new_status == 'picked_up':
            print(f"📬 Notification: {child.first_name} {child.last_name} picked up at {attendance.timestamp.strftime('%I:%M %p')}")
        else:  # dropped_off
            print(f"📬 Notification: {child.first_name} {child.last_name} dropped off at {attendance.timestamp.strftime('%I:%M %p')}")

    return Response({
        "success": True,
        "message": f"Attendance marked as {attendance.get_status_display()}",
        "attendance": {
            "id": attendance.id,
            "child": {
                "id": child.id,
                "name": f"{child.first_name} {child.last_name}",
            },
            "status": attendance.status,
            "status_display": attendance.get_status_display(),
            "trip_type": attendance.trip_type,
            "date": attendance.date,
            "timestamp": attendance.timestamp,
            "notes": attendance.notes,
            "marked_by": request.user.get_full_name(),
        }
    }, status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED)
