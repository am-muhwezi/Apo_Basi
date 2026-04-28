import asyncio
import json
import math
import time as _time
import requests as req_lib
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework_simplejwt.exceptions import TokenError


class BusLocationConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time bus location tracking.

    Features:
    - JWT token authentication
    - Role-based authorization (parents only see their children's buses, admins see all)
    - Real-time location updates
    - Automatic subscription management
    """

    async def connect(self):
        """
        Handle WebSocket connection.
        Authenticate user via JWT token and authorize bus access.
        """
        self.bus_id = self.scope["url_route"]["kwargs"]["bus_id"]
        self.group_name = f"bus_{self.bus_id}"
        self.user = None

        # Extract token from query string
        query_string = self.scope.get("query_string", b"").decode()
        token = None

        for param in query_string.split("&"):
            if param.startswith("token="):
                token = param.split("=")[1]
                break

        if not token:
            # Try to get from headers (subprotocol)
            headers = dict(self.scope.get("headers", []))
            auth_header = headers.get(b"authorization", b"").decode()
            if auth_header.startswith("Bearer "):
                token = auth_header[7:]

        if not token:
            await self.close(code=4001)
            return

        # Authenticate user
        try:
            self.user = await self.authenticate_token(token)
            if not self.user:
                await self.close(code=4001)
                return
        except Exception as e:
            print(f"Authentication error: {e}")
            await self.close(code=4001)
            return

        # Authorize bus access
        authorized = await self.authorize_bus_access(self.user, self.bus_id)
        if not authorized:
            await self.close(code=4003)
            return

        # Add to group
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )

        await self.accept()

        # Send initial connection confirmation
        await self.send(text_data=json.dumps({
            "type": "connected",
            "bus_id": self.bus_id,
            "message": "Connected to bus location updates"
        }))

        # Immediately push current trip state so the parent app doesn't need
        # to poll.  The client sets _hasActiveTrip / _tripType from this and
        # calls route optimisation — no HTTP round-trip required.
        trip_state = await self.get_trip_state(self.bus_id)
        # Cache trip-active flag so location broadcasts are gated without an
        # extra DB query on every GPS packet.
        self._trip_active = trip_state.get("has_active_trip", False)
        # State for server-side bearing and throttled ETA computation.
        self._prev_lat = None
        self._prev_lng = None
        self._last_eta_time = None
        await self.send(text_data=json.dumps({
            "type": "trip_state",
            **trip_state,
        }))

    async def disconnect(self, close_code):
        """Handle WebSocket disconnection."""
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        """
        Handle incoming WebSocket messages.
        Drivers can send location updates, others can request current location.
        """
        try:
            data = json.loads(text_data)
            message_type = data.get("type")

            if message_type == "location_update":
                # Only drivers/minders can send location updates
                is_driver = await self.is_driver_or_minder(self.user)
                if not is_driver:
                    await self.send(text_data=json.dumps({
                        "type": "error",
                        "message": "Only drivers can send location updates"
                    }))
                    return

                # Always persist GPS so the next trip_started can seed the map.
                await self.save_location_update(
                    self.bus_id,
                    data.get("latitude"),
                    data.get("longitude"),
                    data.get("speed", 0),
                    data.get("heading", 0)
                )

                # Only broadcast to parents while a trip is active.
                # _trip_active is kept in sync by bus_trip_event so there is
                # no extra DB query per GPS packet.
                if getattr(self, "_trip_active", False):
                    lat = data.get("latitude")
                    lng = data.get("longitude")
                    # Snap once on the server — all connected parents receive
                    # the pre-snapped position so they don't each have to call
                    # the Map Matching API individually.
                    snapped_lat, snapped_lng = await self._snap_to_road(lat, lng)
                    # Compute bearing from consecutive GPS positions — reliable
                    # at all speeds unlike the raw GPS heading sensor.
                    bearing = self._compute_bearing(
                        self._prev_lat, self._prev_lng, lat, lng
                    )
                    self._prev_lat = lat
                    self._prev_lng = lng
                    await self.channel_layer.group_send(
                        self.group_name,
                        {
                            "type": "bus.location",
                            "bus_id": self.bus_id,
                            "latitude": lat,
                            "longitude": lng,
                            "snapped_latitude": snapped_lat,
                            "snapped_longitude": snapped_lng,
                            "speed": data.get("speed", 0),
                            "heading": data.get("heading", 0),
                            "bearing": bearing,
                            "timestamp": data.get("timestamp"),
                        }
                    )
                    # Throttled ETA broadcast — Mapbox Matrix API, at most once per 60 s.
                    now = _time.monotonic()
                    if self._last_eta_time is None or (now - self._last_eta_time) >= 60:
                        self._last_eta_time = now
                        await self._broadcast_etas(self.bus_id, lat, lng)

            elif message_type == "request_current_location":
                # Only respond with a location when a trip is active — driver
                # GPS must not be exposed to parents between trips.
                if not getattr(self, "_trip_active", False):
                    return
                location = await self.get_current_location(self.bus_id)
                if location:
                    await self.send(text_data=json.dumps({
                        "type": "location_update",
                        "bus_id": self.bus_id,
                        **location
                    }))

            elif message_type == "request_trip_state":
                # Return current trip state on demand (used as a heartbeat/sync)
                trip_state = await self.get_trip_state(self.bus_id)
                await self.send(text_data=json.dumps({
                    "type": "trip_state",
                    **trip_state,
                }))

        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                "type": "error",
                "message": "Invalid JSON"
            }))
        except Exception as e:
            await self.send(text_data=json.dumps({
                "type": "error",
                "message": str(e)
            }))

    async def bus_trip_event(self, event):
        """
        Handle trip lifecycle events broadcast to the bus group.
        Forwards trip_started / trip_ended to all connected clients so the
        parent app can react immediately without polling.
        """
        event_type = event.get("event_type", "")
        if event_type == "trip_started":
            self._trip_active = True
        elif event_type == "trip_ended":
            self._trip_active = False

        await self.send(text_data=json.dumps({
            "type": event["event_type"],       # "trip_started" or "trip_ended"
            "trip_id": event.get("trip_id"),
            "trip_type": event.get("trip_type"),
            "scheduled_time": event.get("scheduled_time"),
            # GPS seed — present on trip_started so the parent map marker
            # appears immediately; absent (None) on trip_ended (bus hidden).
            "bus_latitude": event.get("bus_latitude"),
            "bus_longitude": event.get("bus_longitude"),
            "bus_speed": event.get("bus_speed"),
            "bus_heading": event.get("bus_heading"),
        }))

    async def bus_location(self, event):
        """
        Handle location broadcast messages from the group.
        Send location update to the connected client.
        """
        # Get bus details for the update
        bus_details = await self.get_bus_details(event["bus_id"])

        await self.send(text_data=json.dumps({
            "type": "location_update",
            "bus_id": event["bus_id"],
            "bus_number": bus_details.get("bus_number", ""),
            "latitude": event["latitude"],
            "longitude": event["longitude"],
            "snapped_latitude": event.get("snapped_latitude"),
            "snapped_longitude": event.get("snapped_longitude"),
            "speed": event.get("speed", 0),
            "heading": event.get("heading", 0),
            "bearing": event.get("bearing", 0),
            "is_active": True,
            "timestamp": event.get("timestamp"),
        }))

    async def bus_eta(self, event):
        """Forward ETA update to all connected clients in the group."""
        await self.send(text_data=json.dumps({
            "type": "eta_update",
            "etas": event.get("etas", {}),
            # Trip type lets clients display context ("pickup" vs "dropoff").
            "trip_type": event.get("trip_type"),
        }))

    # ── Helpers ───────────────────────────────────────────────────────────────

    @staticmethod
    def _compute_bearing(lat1, lng1, lat2, lng2):
        """
        Compute compass bearing (degrees, 0=North) from point 1 → point 2.
        Returns 0.0 if either position is unavailable (first update, stationary).
        """
        if lat1 is None or lng1 is None or lat2 is None or lng2 is None:
            return 0.0
        lat1_r = math.radians(float(lat1))
        lat2_r = math.radians(float(lat2))
        dlon   = math.radians(float(lng2) - float(lng1))
        x = math.sin(dlon) * math.cos(lat2_r)
        y = (math.cos(lat1_r) * math.sin(lat2_r)
             - math.sin(lat1_r) * math.cos(lat2_r) * math.cos(dlon))
        return (math.degrees(math.atan2(x, y)) + 360) % 360

    async def _broadcast_etas(self, bus_id, bus_lat, bus_lng):
        """
        Compute cumulative, trip-type-aware ETAs using the Mapbox Directions API
        with sequential waypoints: bus → stop1 → stop2 → … → stopN.

        Using the Directions API (not Matrix) means each child's ETA correctly
        includes the time the bus spends visiting all earlier stops first:

          ETA(child at stop_i) = Σ leg_durations[0 … i−1]

        Stop order is driven by the 'order' DB field, which encodes trip intent:
          pickup  — farthest-from-school stop first, nearest-to-school last.
          dropoff — nearest-to-school stop first, farthest last.
        """
        from django.conf import settings
        token = getattr(settings, "MAPBOX_ACCESS_TOKEN", "")
        if not token:
            return

        trip_data = await self._get_trip_remaining_stops(bus_id)
        trip_type = trip_data["trip_type"]
        stops     = trip_data["stops"]
        if not stops:
            return

        # Mapbox Directions allows up to 25 waypoints (bus + 24 stops).
        capped_stops = stops[:24]

        # Waypoints: bus position first, then stops in route order.
        waypoints = [f"{bus_lng},{bus_lat}"] + [
            f"{s['lng']},{s['lat']}" for s in capped_stops
        ]
        coords_str = ";".join(waypoints)
        url = (
            f"https://api.mapbox.com/directions/v5/mapbox/driving/{coords_str}"
            f"?access_token={token}&overview=false"
        )

        def _sync_directions():
            try:
                resp = req_lib.get(url, timeout=8.0)
                if resp.status_code != 200:
                    return {}
                routes = resp.json().get("routes", [])
                if not routes:
                    return {}
                legs = routes[0].get("legs", [])
                etas = {}
                cumulative_secs = 0.0
                for i, stop in enumerate(capped_stops):
                    if i < len(legs):
                        cumulative_secs += legs[i].get("duration", 0)
                    # All children at this stop share the same cumulative ETA.
                    for child_id in stop["child_ids"]:
                        etas[str(child_id)] = int(cumulative_secs)
                return etas
            except Exception:
                return {}

        etas = await asyncio.to_thread(_sync_directions)
        if etas:
            await self.channel_layer.group_send(
                self.group_name,
                {"type": "bus.eta", "etas": etas, "trip_type": trip_type},
            )

    @database_sync_to_async
    def _get_trip_remaining_stops(self, bus_id):
        """
        Return the active trip's type and its remaining (non-completed) stops
        in route order, each annotated with child IDs and GPS coordinates.

        Stop order semantics (set by the trip planner):
          pickup  — ascending 'order' = farthest-from-school first.
          dropoff — ascending 'order' = nearest-to-school first.
        """
        from trips.models import Trip, Stop
        try:
            trip = Trip.objects.filter(bus_id=bus_id, status="in-progress", bus_minder__isnull=True).first()
            if not trip:
                return {"trip_type": None, "stops": []}
            stops = (
                Stop.objects
                .filter(trip=trip)
                .exclude(status="completed")
                .prefetch_related("children")
                .order_by("order")
            )
            result = []
            for stop in stops:
                if stop.latitude and stop.longitude:
                    child_ids = [c.id for c in stop.children.all()]
                    if child_ids:
                        result.append({
                            "child_ids": child_ids,
                            "lat": float(stop.latitude),
                            "lng": float(stop.longitude),
                        })
            return {"trip_type": trip.trip_type, "stops": result}
        except Exception:
            return {"trip_type": None, "stops": []}

    async def _snap_to_road(self, lat, lng):
        """
        Snap a GPS coordinate to the nearest road via Mapbox Map Matching.
        Returns (snapped_lat, snapped_lng) or the original on failure.
        Runs the sync HTTP call in a thread pool to avoid blocking the event loop.
        """
        from django.conf import settings
        token = getattr(settings, "MAPBOX_ACCESS_TOKEN", "")
        if not token or lat is None or lng is None:
            return lat, lng

        def _sync_snap():
            url = (
                f"https://api.mapbox.com/matching/v5/mapbox/driving/"
                f"{lng},{lat}"
                f"?geometries=geojson&radiuses=25&access_token={token}"
            )
            try:
                resp = req_lib.get(url, timeout=2.0)
                if resp.status_code == 200:
                    matchings = resp.json().get("matchings", [])
                    if matchings:
                        coords = matchings[0]["geometry"]["coordinates"]
                        if coords:
                            return coords[0][1], coords[0][0]  # lat, lng
            except Exception:
                pass
            return lat, lng

        return await asyncio.to_thread(_sync_snap)

    @database_sync_to_async
    def authenticate_token(self, token):
        """Authenticate user from JWT token."""
        from django.contrib.auth import get_user_model

        User = get_user_model()

        try:
            access_token = AccessToken(token)
            user_id = access_token.payload.get("user_id")
            user = User.objects.get(id=user_id)
            return user
        except (TokenError, User.DoesNotExist):
            return None

    @database_sync_to_async
    def authorize_bus_access(self, user, bus_id):
        """
        Authorize user access to bus location.
        - Admins can access all buses
        - Drivers/minders can access their assigned buses
        - Parents can only access buses their children are assigned to
        """
        from buses.models import Bus
        from children.models import Child
        from parents.models import Parent
        from assignments.models import Assignment
        from django.contrib.contenttypes.models import ContentType

        try:
            bus = Bus.objects.get(id=bus_id)
        except Bus.DoesNotExist:
            return False

        # Admins have full access
        if user.user_type == "admin":
            return True

        # Drivers can access their assigned buses
        if user.user_type == "driver":
            # Check 1: direct Bus.driver FK (may be set alongside the assignment)
            if bus.driver_id == user.id:
                return True
            # Check 2: Assignment model — Driver.pk == user.id (primary_key=True on user FK)
            from drivers.models import Driver
            driver_ct = ContentType.objects.get_for_model(Driver)
            bus_ct = ContentType.objects.get_for_model(Bus)
            return Assignment.objects.filter(
                assignee_content_type=driver_ct,
                assignee_object_id=user.id,
                assigned_to_content_type=bus_ct,
                assigned_to_object_id=bus_id,
                status='active'
            ).exists()

        # Bus minders can access their assigned buses
        if user.user_type == "busminder":
            if bus.bus_minder_id == user.id:
                return True

        # Parents can only access buses their children are assigned to
        if user.user_type == "parent":
            try:
                parent = Parent.objects.get(user=user)
                children = Child.objects.filter(parent=parent)

                # Check if any of the parent's children are assigned to this bus
                child_content_type = ContentType.objects.get_for_model(Child)
                bus_content_type = ContentType.objects.get_for_model(Bus)

                for child in children:
                    has_assignment = Assignment.objects.filter(
                        assignee_content_type=child_content_type,
                        assignee_object_id=child.id,
                        assigned_to_content_type=bus_content_type,
                        assigned_to_object_id=bus_id,
                        status="active"
                    ).exists()

                    if has_assignment:
                        return True

                return False
            except Parent.DoesNotExist:
                return False

        return False

    @database_sync_to_async
    def is_driver_or_minder(self, user):
        """Check if user is a driver or bus minder."""
        return user.user_type in ["driver", "busminder"]

    @database_sync_to_async
    def save_location_update(self, bus_id, latitude, longitude, speed, heading):
        """Save location update to database."""
        from buses.models import Bus, BusLocationHistory

        try:
            bus = Bus.objects.get(id=bus_id)
            bus.latitude = latitude
            bus.longitude = longitude
            bus.speed = speed
            bus.heading = heading
            bus.is_active = True
            bus.save()

            # Optionally save to location history
            BusLocationHistory.objects.create(
                bus=bus,
                latitude=latitude,
                longitude=longitude,
                speed=speed,
                heading=heading,
                is_active=True
            )
        except Bus.DoesNotExist:
            pass

    @database_sync_to_async
    def get_current_location(self, bus_id):
        """Get current location from database."""
        from buses.models import Bus

        try:
            bus = Bus.objects.get(id=bus_id)
            if bus.latitude and bus.longitude:
                return {
                    "bus_number": bus.bus_number,
                    "latitude": float(bus.latitude),
                    "longitude": float(bus.longitude),
                    "speed": bus.speed or 0,
                    "heading": bus.heading or 0,
                    "is_active": bus.is_active,
                    "timestamp": bus.last_updated.isoformat() if bus.last_updated else None
                }
        except Bus.DoesNotExist:
            pass

    @database_sync_to_async
    def get_trip_state(self, bus_id):
        """
        Return the current trip state for this bus so the parent app can
        restore its UI immediately on (re)connect without polling.
        """
        from trips.models import Trip
        from buses.models import Bus

        result = {
            "has_active_trip": False,
            "trip_id": None,
            "trip_type": None,
            "scheduled_time": None,
            "bus_latitude": None,
            "bus_longitude": None,
            "bus_speed": None,
            "bus_heading": None,
        }

        try:
            trip = Trip.objects.filter(bus_id=bus_id, status="in-progress", bus_minder__isnull=True).first()
            print(f"[get_trip_state] bus_id={bus_id} trip={trip} (status query: in-progress)")
            if trip:
                result["has_active_trip"] = True
                result["trip_id"] = trip.id
                result["trip_type"] = trip.trip_type
                result["scheduled_time"] = (
                    trip.scheduled_time.isoformat() if trip.scheduled_time else None
                )

            # Only attach GPS when a trip is active — never expose driver
            # location to parents between trips.
            if result["has_active_trip"]:
                bus = Bus.objects.get(id=bus_id)
                if bus.latitude and bus.longitude:
                    result["bus_latitude"] = float(bus.latitude)
                    result["bus_longitude"] = float(bus.longitude)
                    result["bus_speed"] = float(bus.speed) if bus.speed else 0.0
                    result["bus_heading"] = float(bus.heading) if bus.heading else 0.0
        except Exception as e:
            print(f"[get_trip_state] ERROR for bus_id={bus_id}: {e}")

        print(f"[get_trip_state] result={result}")
        return result

    @database_sync_to_async
    def get_bus_details(self, bus_id):
        """Get bus details for updates."""
        from buses.models import Bus

        try:
            bus = Bus.objects.get(id=bus_id)
            return {
                "bus_number": bus.bus_number,
                "is_active": bus.is_active
            }
        except Bus.DoesNotExist:
            return {"bus_number": "", "is_active": False}
