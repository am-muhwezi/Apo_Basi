from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.conf import settings
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
import requests
import threading
from .models import Trip, Stop
from .serializers import TripSerializer, TripCreateSerializer, StopSerializer, StopCreateSerializer


# ---------------------------------------------------------------------------
# School info endpoint
# ---------------------------------------------------------------------------

class SchoolInfoView(APIView):
    """
    GET /api/school/info/ — Return school GPS coordinates (from settings/env).
    Used by the Flutter clients to anchor Mapbox route optimisation.
    No authentication required so the optimisation can run pre-login if needed.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({
            'schoolLatitude':  getattr(settings, 'SCHOOL_LATITUDE',  -1.2864),
            'schoolLongitude': getattr(settings, 'SCHOOL_LONGITUDE', 36.8172),
            'schoolName':      getattr(settings, 'SCHOOL_NAME',      'School'),
        })


# ---------------------------------------------------------------------------
# Server-side Mapbox optimisation helper (called from TripStartView)
# ---------------------------------------------------------------------------

def _optimize_trip_stops_background(trip_id: int) -> None:
    """
    Runs in a daemon thread after a trip starts.

    1. Calls Mapbox Optimized Trips API (driving-traffic profile).
    2. Extracts the optimised home-stop order.
    3. Updates each Stop.order field in the DB atomically.

    This is the single source of truth for stop ordering.
    All clients subsequently read `order_by('order')` from the DB
    and never need to re-derive the sequence themselves.
    """
    try:
        school_lat = getattr(settings, 'SCHOOL_LATITUDE', None)
        school_lng = getattr(settings, 'SCHOOL_LONGITUDE', None)
        mapbox_token = getattr(settings, 'MAPBOX_ACCESS_TOKEN', '')

        if not school_lat or not school_lng or not mapbox_token:
            print(f"⚠️  Trip {trip_id}: skipping optimisation — "
                  "SCHOOL_LATITUDE / SCHOOL_LONGITUDE / MAPBOX_ACCESS_TOKEN not set")
            return

        trip = Trip.objects.prefetch_related('stops').get(id=trip_id)
        stops = list(trip.stops.all())
        valid = [s for s in stops if s.latitude and s.longitude]

        if len(valid) < 2:
            return  # nothing to optimise

        school_coord = f"{float(school_lng)},{float(school_lat)}"
        home_coords  = [f"{float(s.longitude)},{float(s.latitude)}" for s in valid]
        n_homes = len(home_coords)

        # ── Pickup: [school_start, home_1..N, school_end]  source=first  destination=last
        # ── Dropoff: [school, home_1..N]                   source=first  destination=any
        if trip.trip_type == 'pickup':
            # School is both the conceptual starting point (bus depot proxy)
            # AND the locked final destination — Mapbox can never reorder it.
            coords_str = ';'.join([school_coord] + home_coords + [school_coord])
            params = {
                'source':      'first',
                'destination': 'last',    # school is ALWAYS last — guaranteed
                'roundtrip':   'false',
            }
        else:  # dropoff
            coords_str = ';'.join([school_coord] + home_coords)
            params = {
                'source':      'first',
                'destination': 'any',
                'roundtrip':   'false',
            }

        params['geometries']    = 'geojson'
        params['access_token']  = mapbox_token

        resp = requests.get(
            f"https://api.mapbox.com/optimized-trips/v1/mapbox/driving-traffic/{coords_str}",
            params=params,
            timeout=12,
        )

        if resp.status_code != 200:
            print(f"⚠️  Mapbox optimisation failed for trip {trip_id}: "
                  f"HTTP {resp.status_code}")
            return

        data = resp.json()
        waypoints = sorted(
            data.get('waypoints', []),
            key=lambda w: w['waypoint_index'],
        )

        # Extract ordered stop IDs — skip school coordinate(s)
        ordered_stop_ids = []
        for wp in waypoints:
            orig_idx = wp['original_index']
            if trip.trip_type == 'pickup':
                # orig_idx 0 = school start  |  1..N = homes  |  N+1 = school end
                if orig_idx == 0 or orig_idx == n_homes + 1:
                    continue
                ordered_stop_ids.append(valid[orig_idx - 1].id)
            else:
                # orig_idx 0 = school  |  1..N = homes
                if orig_idx == 0:
                    continue
                ordered_stop_ids.append(valid[orig_idx - 1].id)

        # Persist the optimised order — single atomic write per stop
        for new_order, stop_id in enumerate(ordered_stop_ids):
            Stop.objects.filter(id=stop_id).update(order=new_order)

        print(f"✅ Trip {trip_id}: optimised {len(ordered_stop_ids)} stops "
              f"({trip.trip_type})")

    except Exception as exc:
        print(f"⚠️  _optimize_trip_stops_background trip={trip_id}: {exc}")


class TripListCreateView(generics.ListCreateAPIView):
    """
    GET /api/trips/ - List all trips
    POST /api/trips/ - Create new trip
    """
    permission_classes = [IsAuthenticated]
    queryset = Trip.objects.select_related('bus', 'driver', 'bus_minder').prefetch_related('children', 'stops').order_by('-id')

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
    queryset = Trip.objects.select_related('bus', 'driver', 'bus_minder').prefetch_related('children', 'stops').order_by('-id')

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
        # Block parents from starting trips
        if request.user.user_type == 'parent':
            return Response({"error": "Parents cannot start trips."}, status=status.HTTP_403_FORBIDDEN)

        trip = get_object_or_404(Trip, pk=pk)

        if trip.status != 'scheduled':
            return Response(
                {"error": "Only scheduled trips can be started"},
                status=status.HTTP_400_BAD_REQUEST
            )

        trip.status = 'in-progress'
        trip.start_time = timezone.now()
        trip.save()

        # Update children location_status when dropoff trip starts
        if trip.trip_type == 'dropoff':
            # Mark all children on this dropoff trip as 'on-bus'
            trip.children.update(location_status='on-bus')

        # Push a trip_started event to all parents currently watching this bus.
        # Parents receive this on the existing bus WebSocket and immediately
        # re-initialise route optimisation — no polling required.
        if trip.bus_id:
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f"bus_{trip.bus_id}",
                {
                    "type": "bus.trip_event",
                    "event_type": "trip_started",
                    "trip_id": trip.id,
                    "trip_type": trip.trip_type,
                    "scheduled_time": (
                        trip.scheduled_time.isoformat()
                        if trip.scheduled_time else None
                    ),
                }
            )

        print(f"\u2705 Trip started: {trip.id} for bus {trip.bus.bus_number}")

        # Optimise stop order in the background so the HTTP response is not
        # delayed. The daemon thread writes Stop.order fields; all subsequent
        # reads via `order_by('order')` will reflect the Mapbox-optimised order.
        threading.Thread(
            target=_optimize_trip_stops_background,
            args=(trip.id,),
            daemon=True,
        ).start()

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

        # Update children location_status when pickup trip ends
        if trip.trip_type == 'pickup':
            # Mark all children on this pickup trip as 'at-school'
            trip.children.update(location_status='at-school')

        # Push trip_ended so parent apps can hide the bus marker / show arrived.
        if trip.bus_id:
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f"bus_{trip.bus_id}",
                {
                    "type": "bus.trip_event",
                    "event_type": "trip_ended",
                    "trip_id": trip.id,
                    "trip_type": trip.trip_type,
                    "scheduled_time": None,
                }
            )

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

        # Broadcast location update via Django Channels WebSocket
        if trip.bus_id:
            channel_layer = get_channel_layer()
            group_name = f"bus_{trip.bus_id}"
            
            async_to_sync(channel_layer.group_send)(
                group_name,
                {
                    "type": "bus.location",
                    "bus_id": trip.bus_id,
                    "latitude": float(latitude),
                    "longitude": float(longitude),
                    "speed": float(speed),
                    "heading": float(heading),
                    "timestamp": trip.location_timestamp.isoformat(),
                }
            )

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


class TripReorderStopsView(APIView):
    """
    POST /api/trips/{id}/reorder-stops/

    Client fallback: persist a client-computed stop order to the DB so all
    other clients immediately read the same sequence.

    Accepts TWO formats (first non-empty one wins):

      Format A — by stop ID:
        { "stops": [{"id": 3, "order": 0}, {"id": 7, "order": 1}, ...] }

      Format B — by child ID (used when client only knows childId, not stopId):
        { "children": [{"childId": 5, "order": 0}, {"childId": 9, "order": 1}, ...] }

    Only pending stops on this trip can be reordered; completed/skipped stops
    are ignored so we never disturb a trip that is already underway.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        trip = get_object_or_404(Trip, pk=pk)
        updated = 0

        # ── Format A: explicit stop IDs ─────────────────────────────────────
        stops_data = request.data.get('stops') or []
        for item in stops_data:
            stop_id = item.get('id')
            order   = item.get('order')
            if stop_id is not None and order is not None:
                rows = Stop.objects.filter(
                    id=stop_id, trip=trip, status='pending'
                ).update(order=order)
                updated += rows

        # ── Format B: child IDs ──────────────────────────────────────────────
        children_data = request.data.get('children') or []
        for item in children_data:
            child_id = item.get('childId')
            order    = item.get('order')
            if child_id is not None and order is not None:
                # Find the pending stop on this trip that contains this child
                stop = (
                    Stop.objects
                    .filter(trip=trip, status='pending', children__id=child_id)
                    .first()
                )
                if stop:
                    stop.order = order
                    stop.save(update_fields=['order'])
                    updated += 1

        return Response({'status': 'ok', 'updated': updated})
