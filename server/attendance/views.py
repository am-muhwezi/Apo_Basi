from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, Count, Case, When, IntegerField
from datetime import date, datetime, timedelta
from .models import Attendance
from .serializers import AttendanceSerializer, AttendanceListSerializer
from children.models import Child
from buses.models import Bus


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
