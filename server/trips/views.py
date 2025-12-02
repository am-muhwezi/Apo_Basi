from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.conf import settings
import requests
from .models import Trip, Stop
from .serializers import TripSerializer, TripCreateSerializer, StopSerializer, StopCreateSerializer


class TripListCreateView(generics.ListCreateAPIView):
    """
    GET /api/trips/ - List all trips
    POST /api/trips/ - Create new trip
    """
    permission_classes = [IsAuthenticated]
    queryset = Trip.objects.select_related('bus', 'driver', 'bus_minder').prefetch_related('children', 'stops').all()

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return TripCreateSerializer
        return TripSerializer

    def get_queryset(self):
        queryset = super().get_queryset()

        # Filter by status if provided
        status_filter = self.request.query_params.get('status', None)
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # Filter by bus if provided
        bus_id = self.request.query_params.get('bus_id', None)
        if bus_id:
            queryset = queryset.filter(bus_id=bus_id)

        # Filter by driver if provided
        driver_id = self.request.query_params.get('driver_id', None)
        if driver_id:
            queryset = queryset.filter(driver_id=driver_id)

        # Filter by type (pickup/dropoff)
        trip_type = self.request.query_params.get('type', None)
        if trip_type:
            queryset = queryset.filter(trip_type=trip_type)

        return queryset


class TripDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/trips/{id}/ - Get trip details
    PUT /api/trips/{id}/ - Update trip
    PATCH /api/trips/{id}/ - Partial update trip
    DELETE /api/trips/{id}/ - Delete trip
    """
    permission_classes = [IsAuthenticated]
    queryset = Trip.objects.select_related('bus', 'driver', 'bus_minder').prefetch_related('children', 'stops').all()

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return TripCreateSerializer
        return TripSerializer


class TripStartView(APIView):
    """
    POST /api/trips/{id}/start/ - Start a trip
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        trip = get_object_or_404(Trip, pk=pk)

        if trip.status != 'scheduled':
            return Response(
                {"error": "Only scheduled trips can be started"},
                status=status.HTTP_400_BAD_REQUEST
            )

        trip.status = 'in-progress'
        trip.start_time = timezone.now()
        trip.save()

        # Notify Socket.IO server about trip start
        try:
            socketio_url = getattr(settings, 'SOCKETIO_SERVER_URL', 'http://localhost:3000')
            response = requests.post(
                f'{socketio_url}/api/notify/trip-start',
                json={
                    'busId': trip.bus.id,
                    'tripType': trip.trip_type,
                    'tripId': trip.id,
                    'driverUserId': request.user.id
                },
                timeout=2
            )
            print(f"Notified Socket.IO server: {response.status_code}")
        except Exception as e:
            # Don't fail the request if Socket.IO notification fails
            print(f"Failed to notify Socket.IO server: {e}")

        # Create notifications for all parents with children on this bus
        try:
            from notifications.views import create_notification
            from children.models import Child

            # Get all children assigned to this bus
            children = Child.objects.filter(
                trips=trip
            ).select_related('parent').distinct()

            for child in children:
                if child.parent:
                    title = f"Bus {trip.bus.bus_number} Started {trip.get_trip_type_display()} Trip"
                    message = f"Your child's bus has started the {trip.get_trip_type_display().lower()} trip."

                    try:
                        create_notification(
                            parent=child.parent,
                            notification_type='general',
                            title=title,
                            message=message,
                            related_object=trip
                        )
                    except Exception as e:
                        print(f"Failed to create notification for parent {child.parent.user.id}: {e}")
        except Exception as e:
            print(f"Failed to create parent notifications: {e}")

        serializer = TripSerializer(trip)
        return Response(serializer.data)


class TripCompleteView(APIView):
    """
    POST /api/trips/{id}/complete/ - Complete a trip
    Body (optional): {
        "totalStudents": 10,
        "studentsCompleted": 8,
        "studentsAbsent": 2,
        "studentsPending": 0
    }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        trip = get_object_or_404(Trip, pk=pk)

        if trip.status != 'in-progress':
            return Response(
                {"error": "Only in-progress trips can be completed"},
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

        serializer = TripSerializer(trip)
        return Response(serializer.data)


class TripCancelView(APIView):
    """
    POST /api/trips/{id}/cancel/ - Cancel a trip
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        trip = get_object_or_404(Trip, pk=pk)

        if trip.status in ['completed', 'cancelled']:
            return Response(
                {"error": "Cannot cancel completed or already cancelled trips"},
                status=status.HTTP_400_BAD_REQUEST
            )

        trip.status = 'cancelled'
        trip.save()

        serializer = TripSerializer(trip)
        return Response(serializer.data)


class TripUpdateLocationView(APIView):
    """
    POST /api/trips/{id}/update-location/ - Update trip location
    Body: { "latitude": 40.7128, "longitude": -74.0060, "speed": 50, "heading": 90 }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        trip = get_object_or_404(Trip, pk=pk)

        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        speed = request.data.get('speed', 0)
        heading = request.data.get('heading', 0)

        if latitude is None or longitude is None:
            return Response(
                {"error": "latitude and longitude are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        trip.current_latitude = latitude
        trip.current_longitude = longitude
        trip.location_timestamp = timezone.now()
        trip.save()

        # Notify Socket.IO server about location update
        try:
            socketio_url = getattr(settings, 'SOCKETIO_SERVER_URL', 'http://localhost:3000')
            requests.post(
                f'{socketio_url}/api/notify/location-update',
                json={
                    'busId': trip.bus.id,
                    'latitude': float(latitude),
                    'longitude': float(longitude),
                    'speed': speed,
                    'heading': heading
                },
                timeout=1
            )
        except Exception as e:
            # Don't fail the request if Socket.IO notification fails
            print(f"Failed to notify Socket.IO server of location: {e}")

        serializer = TripSerializer(trip)
        return Response(serializer.data)


class StopListCreateView(generics.ListCreateAPIView):
    """
    GET /api/trips/{trip_id}/stops/ - List stops for a trip
    POST /api/trips/{trip_id}/stops/ - Create a stop for a trip
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return StopCreateSerializer
        return StopSerializer

    def get_queryset(self):
        trip_id = self.kwargs.get('trip_id')
        return Stop.objects.filter(trip_id=trip_id).prefetch_related('children')

    def perform_create(self, serializer):
        trip_id = self.kwargs.get('trip_id')
        trip = get_object_or_404(Trip, pk=trip_id)
        serializer.save(trip=trip)


class StopDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/stops/{id}/ - Get stop details
    PUT /api/stops/{id}/ - Update stop
    PATCH /api/stops/{id}/ - Partial update stop
    DELETE /api/stops/{id}/ - Delete stop
    """
    permission_classes = [IsAuthenticated]
    queryset = Stop.objects.prefetch_related('children').all()

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return StopCreateSerializer
        return StopSerializer


class StopCompleteView(APIView):
    """
    POST /api/stops/{id}/complete/ - Mark stop as completed
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        stop = get_object_or_404(Stop, pk=pk)

        if stop.status != 'pending':
            return Response(
                {"error": "Only pending stops can be completed"},
                status=status.HTTP_400_BAD_REQUEST
            )

        stop.status = 'completed'
        stop.actual_time = timezone.now()
        stop.save()

        serializer = StopSerializer(stop)
        return Response(serializer.data)


class StopSkipView(APIView):
    """
    POST /api/stops/{id}/skip/ - Mark stop as skipped
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        stop = get_object_or_404(Stop, pk=pk)

        if stop.status != 'pending':
            return Response(
                {"error": "Only pending stops can be skipped"},
                status=status.HTTP_400_BAD_REQUEST
            )

        stop.status = 'skipped'
        stop.actual_time = timezone.now()
        stop.save()

        serializer = StopSerializer(stop)
        return Response(serializer.data)
