import json
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

                # Broadcast location update to all subscribers
                await self.channel_layer.group_send(
                    self.group_name,
                    {
                        "type": "bus.location",
                        "bus_id": self.bus_id,
                        "latitude": data.get("latitude"),
                        "longitude": data.get("longitude"),
                        "speed": data.get("speed", 0),
                        "heading": data.get("heading", 0),
                        "timestamp": data.get("timestamp"),
                    }
                )

                # Save to database
                await self.save_location_update(
                    self.bus_id,
                    data.get("latitude"),
                    data.get("longitude"),
                    data.get("speed", 0),
                    data.get("heading", 0)
                )

            elif message_type == "request_current_location":
                # Get current location from database and send it
                location = await self.get_current_location(self.bus_id)
                if location:
                    await self.send(text_data=json.dumps({
                        "type": "location_update",
                        "bus_id": self.bus_id,
                        **location
                    }))
                else:
                    await self.send(text_data=json.dumps({
                        "type": "error",
                        "message": "No location data available"
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
        await self.send(text_data=json.dumps({
            "type": event["event_type"],       # "trip_started" or "trip_ended"
            "trip_id": event.get("trip_id"),
            "trip_type": event.get("trip_type"),
            "scheduled_time": event.get("scheduled_time"),
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
            "speed": event.get("speed", 0),
            "heading": event.get("heading", 0),
            "is_active": True,
            "timestamp": event.get("timestamp"),
        }))

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
