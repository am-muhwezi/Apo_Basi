from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import Trip, Stop
from .serializers import TripSerializer, TripCreateSerializer, StopSerializer, StopCreateSerializer


class TripListCreateView(generics.ListCreateAPIView):
    """
    GET /api/trips/ - List all trips
    POST /api/trips/ - Create new trip
    """
    permission_classes = [AllowAny]
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
    permission_classes = [AllowAny]
    queryset = Trip.objects.select_related('bus', 'driver', 'bus_minder').prefetch_related('children', 'stops').all()

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return TripCreateSerializer
        return TripSerializer


class TripStartView(APIView):
    """
    POST /api/trips/{id}/start/ - Start a trip
    """
    permission_classes = [AllowAny]

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

        serializer = TripSerializer(trip)
        return Response(serializer.data)


class TripCompleteView(APIView):
    """
    POST /api/trips/{id}/complete/ - Complete a trip
    """
    permission_classes = [AllowAny]

    def post(self, request, pk):
        trip = get_object_or_404(Trip, pk=pk)

        if trip.status != 'in-progress':
            return Response(
                {"error": "Only in-progress trips can be completed"},
                status=status.HTTP_400_BAD_REQUEST
            )

        trip.status = 'completed'
        trip.end_time = timezone.now()
        trip.save()

        serializer = TripSerializer(trip)
        return Response(serializer.data)


class TripCancelView(APIView):
    """
    POST /api/trips/{id}/cancel/ - Cancel a trip
    """
    permission_classes = [AllowAny]

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
    Body: { "latitude": 40.7128, "longitude": -74.0060 }
    """
    permission_classes = [AllowAny]

    def post(self, request, pk):
        trip = get_object_or_404(Trip, pk=pk)

        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')

        if latitude is None or longitude is None:
            return Response(
                {"error": "latitude and longitude are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        trip.current_latitude = latitude
        trip.current_longitude = longitude
        trip.location_timestamp = timezone.now()
        trip.save()

        serializer = TripSerializer(trip)
        return Response(serializer.data)


class StopListCreateView(generics.ListCreateAPIView):
    """
    GET /api/trips/{trip_id}/stops/ - List stops for a trip
    POST /api/trips/{trip_id}/stops/ - Create a stop for a trip
    """
    permission_classes = [AllowAny]

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
    permission_classes = [AllowAny]
    queryset = Stop.objects.prefetch_related('children').all()

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return StopCreateSerializer
        return StopSerializer


class StopCompleteView(APIView):
    """
    POST /api/stops/{id}/complete/ - Mark stop as completed
    """
    permission_classes = [AllowAny]

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
    permission_classes = [AllowAny]

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
