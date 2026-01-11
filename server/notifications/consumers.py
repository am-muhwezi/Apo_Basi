import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework_simplejwt.exceptions import TokenError


class ParentNotificationsConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time parent notifications.

    Features:
    - JWT token authentication
    - Parent-specific notification stream
    - Handles multiple notification types:
      * Trip notifications (start, end, delays)
      * Attendance notifications (pickup, dropoff)
      * Route changes
      * Emergency alerts
      * Bus proximity alerts
    """

    async def connect(self):
        """
        Handle WebSocket connection.
        Authenticate parent user via JWT token.
        """
        print("📥 ParentNotificationsConsumer: Connection attempt")
        self.user = None
        self.parent_id = None
        self.group_name = None

        # Extract token from query string
        query_string = self.scope.get("query_string", b"").decode()
        print(f"🔍 Query string: {query_string}")
        token = None

        for param in query_string.split("&"):
            if param.startswith("token="):
                token = param.split("=")[1]
                break

        if not token:
            # Try to get from headers
            headers = dict(self.scope.get("headers", []))
            auth_header = headers.get(b"authorization", b"").decode()
            if auth_header.startswith("Bearer "):
                token = auth_header[7:]

        if not token:
            print("❌ No token found in request")
            await self.close(code=4001)  # Unauthorized
            return

        print(f"🔑 Token found: {token[:20]}...")

        # Authenticate user
        try:
            print("🔐 Authenticating token...")
            self.user = await self.authenticate_token(token)
            if not self.user:
                print("❌ Token authentication failed")
                await self.close(code=4001)
                return

            print(f"✅ User authenticated: {self.user.email}, type: {self.user.user_type}")

            # Verify user is a parent
            if self.user.user_type != "parent":
                print(f"❌ User is not a parent: {self.user.user_type}")
                await self.close(code=4003)  # Forbidden
                return

            # Get parent_id
            self.parent_id = await self.get_parent_id(self.user)
            if not self.parent_id:
                print("❌ Parent record not found for user")
                await self.close(code=4003)
                return

            print(f"✅ Parent ID: {self.parent_id}")

        except Exception as e:
            print(f"❌ Authentication error: {e}")
            import traceback
            traceback.print_exc()
            await self.close(code=4001)
            return

        # Create unique group name for this parent
        self.group_name = f"parent_notifications_{self.parent_id}"

        # Add to group
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )

        await self.accept()
        print(f"✅ WebSocket accepted for parent {self.parent_id}")

        # Send connection confirmation
        await self.send(text_data=json.dumps({
            "type": "connected",
            "message": "Connected to notification stream",
            "parent_id": self.parent_id
        }))
        print(f"✅ Connection confirmation sent to parent {self.parent_id}")

    async def disconnect(self, close_code):
        """Handle WebSocket disconnection."""
        if hasattr(self, 'group_name') and self.group_name:
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        """
        Handle incoming WebSocket messages from client.
        Clients can request notification preferences or mark notifications as read.
        """
        try:
            data = json.loads(text_data)
            message_type = data.get("type")

            if message_type == "mark_as_read":
                notification_id = data.get("notification_id")
                if notification_id:
                    await self.mark_notification_read(notification_id)
                    await self.send(text_data=json.dumps({
                        "type": "notification_marked_read",
                        "notification_id": notification_id
                    }))

            elif message_type == "get_unread_count":
                count = await self.get_unread_count(self.parent_id)
                await self.send(text_data=json.dumps({
                    "type": "unread_count",
                    "count": count
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

    # Channel layer message handlers
    async def trip_notification(self, event):
        """Handle trip start/end notifications."""
        await self.send(text_data=json.dumps({
            "type": "trip_notification",
            "notification_type": event.get("notification_type"),  # trip_started, trip_ended
            "id": event.get("id"),
            "title": event.get("title"),
            "message": event.get("message"),
            "full_message": event.get("full_message"),
            "timestamp": event.get("timestamp"),
            "trip_id": event.get("trip_id"),
            "bus_id": event.get("bus_id"),
            "bus_number": event.get("bus_number"),
            "trip_type": event.get("trip_type"),  # pickup, dropoff
            "is_read": False
        }))

    async def attendance_notification(self, event):
        """Handle child pickup/dropoff notifications."""
        await self.send(text_data=json.dumps({
            "type": "attendance_notification",
            "notification_type": event.get("notification_type"),  # pickup_confirmed, dropoff_complete
            "id": event.get("id"),
            "title": event.get("title"),
            "message": event.get("message"),
            "full_message": event.get("full_message"),
            "timestamp": event.get("timestamp"),
            "child_id": event.get("child_id"),
            "child_name": event.get("child_name"),
            "bus_id": event.get("bus_id"),
            "bus_number": event.get("bus_number"),
            "status": event.get("status"),  # picked_up, dropped_off
            "location": event.get("location"),
            "is_read": False
        }))

    async def route_change_notification(self, event):
        """Handle route change notifications."""
        await self.send(text_data=json.dumps({
            "type": "route_change_notification",
            "notification_type": "route_change",
            "id": event.get("id"),
            "title": event.get("title"),
            "message": event.get("message"),
            "full_message": event.get("full_message"),
            "timestamp": event.get("timestamp"),
            "route_id": event.get("route_id"),
            "bus_id": event.get("bus_id"),
            "bus_number": event.get("bus_number"),
            "change_details": event.get("change_details"),
            "is_read": False
        }))

    async def emergency_notification(self, event):
        """Handle emergency alerts."""
        await self.send(text_data=json.dumps({
            "type": "emergency_notification",
            "notification_type": "emergency",
            "id": event.get("id"),
            "title": event.get("title"),
            "message": event.get("message"),
            "full_message": event.get("full_message"),
            "timestamp": event.get("timestamp"),
            "bus_id": event.get("bus_id"),
            "bus_number": event.get("bus_number"),
            "severity": event.get("severity"),  # low, medium, high, critical
            "action_required": event.get("action_required"),
            "is_read": False
        }))

    async def delay_notification(self, event):
        """Handle delay notifications."""
        await self.send(text_data=json.dumps({
            "type": "delay_notification",
            "notification_type": "major_delay",
            "id": event.get("id"),
            "title": event.get("title"),
            "message": event.get("message"),
            "full_message": event.get("full_message"),
            "timestamp": event.get("timestamp"),
            "bus_id": event.get("bus_id"),
            "bus_number": event.get("bus_number"),
            "delay_minutes": event.get("delay_minutes"),
            "reason": event.get("reason"),
            "estimated_arrival": event.get("estimated_arrival"),
            "is_read": False
        }))

    async def proximity_notification(self, event):
        """Handle bus proximity alerts."""
        await self.send(text_data=json.dumps({
            "type": "proximity_notification",
            "notification_type": "bus_approaching",
            "id": event.get("id"),
            "title": event.get("title"),
            "message": event.get("message"),
            "full_message": event.get("full_message"),
            "timestamp": event.get("timestamp"),
            "bus_id": event.get("bus_id"),
            "bus_number": event.get("bus_number"),
            "distance_km": event.get("distance_km"),
            "estimated_arrival_minutes": event.get("estimated_arrival_minutes"),
            "is_read": False
        }))

    # Database operations
    @database_sync_to_async
    def authenticate_token(self, token):
        """
        Authenticate user from JWT token using rest_framework_simplejwt.
        This ensures consistent token validation with the REST API.
        """
        from django.contrib.auth import get_user_model

        User = get_user_model()

        try:
            access_token = AccessToken(token)
            user_id = access_token.payload.get("user_id")
            if not user_id:
                print(f"❌ No user_id in token payload")
                return None

            user = User.objects.get(id=user_id)
            print(f"✅ User authenticated: {user.email}")
            return user

        except TokenError as e:
            print(f"❌ JWT token error: {e}")
            return None
        except User.DoesNotExist:
            print(f"❌ User with id {user_id} does not exist")
            return None
        except Exception as e:
            print(f"❌ Unexpected authentication error: {e}")
            return None
        except Exception as e:
            print(f"❌ Unexpected authentication error: {e}")
            import traceback
            traceback.print_exc()
            return None

    @database_sync_to_async
    def get_parent_id(self, user):
        """Get parent ID from user. Since Parent uses user as primary key, return user.id"""
        from parents.models import Parent

        try:
            parent = Parent.objects.get(user=user)
            # Parent model uses user as primary_key, so parent.pk == parent.user_id == user.id
            return parent.user_id
        except Parent.DoesNotExist:
            return None

    @database_sync_to_async
    def mark_notification_read(self, notification_id):
        """Mark notification as read (if you have a Notification model)."""
        # Implement if you create a Notification model
        # from notifications.models import Notification
        # try:
        #     notification = Notification.objects.get(id=notification_id)
        #     notification.is_read = True
        #     notification.save()
        # except Notification.DoesNotExist:
        #     pass
        pass

    @database_sync_to_async
    def get_unread_count(self, parent_id):
        """Get unread notification count."""
        # Implement if you have a Notification model
        # from notifications.models import Notification
        # return Notification.objects.filter(
        #     parent_id=parent_id,
        #     is_read=False
        # ).count()
        return 0
