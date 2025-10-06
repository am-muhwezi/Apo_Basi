"""
Real-time Bus Location Tracking with FastAPI

This module provides WebSocket and REST endpoints for real-time bus tracking:
- Drivers POST GPS coordinates every 5-10 seconds
- Parents connect via WebSocket to receive instant location updates
- No polling needed - push-based architecture
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, HTTPException, Header
from typing import Dict, Set, Optional
from pydantic import BaseModel, Field
from datetime import datetime
import json
import os
import django

# Setup Django ORM access
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'apo_basi.settings')
django.setup()

from buses.models import Bus
from users.models import User
from children.models import Child
from rest_framework_simplejwt.tokens import AccessToken
from django.core.exceptions import ObjectDoesNotExist

# Initialize FastAPI app
app = FastAPI(
    title="Bus Tracking Real-Time API",
    description="WebSocket and REST API for real-time bus location tracking",
    version="1.0.0"
)

# ============================================================================
# IN-MEMORY WEBSOCKET CONNECTION MANAGER
# ============================================================================
"""
Why in-memory storage?
- Fast: No database queries for every broadcast
- Simple: Perfect for MVP (we can add Redis later for multi-server scaling)

Structure: {bus_id: {user_id: websocket_connection}}
Example: {1: {42: <WebSocket>, 43: <WebSocket>}, 2: {44: <WebSocket>}}
This means: Bus #1 has 2 parents watching, Bus #2 has 1 parent
"""
active_connections: Dict[int, Dict[int, WebSocket]] = {}


# ============================================================================
# PYDANTIC MODELS (Request/Response Validation)
# ============================================================================
"""
Why Pydantic?
- Automatic validation: FastAPI rejects invalid data before it reaches our code
- Type safety: IDE autocomplete + type checking
- Auto-generated API docs: FastAPI creates interactive docs at /docs
"""

class LocationUpdate(BaseModel):
    """Driver sends this when GPS location changes"""
    latitude: float = Field(..., ge=-90, le=90, description="Latitude (-90 to 90)")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude (-180 to 180)")
    speed: float = Field(default=0.0, ge=0, description="Speed in km/h")
    heading: float = Field(default=0.0, ge=0, lt=360, description="Direction in degrees (0-360)")

    class Config:
        json_schema_extra = {
            "example": {
                "latitude": 37.7749,
                "longitude": -122.4194,
                "speed": 45.5,
                "heading": 180.0
            }
        }


class LocationResponse(BaseModel):
    """Response sent to parents via WebSocket"""
    bus_id: int
    latitude: Optional[float]
    longitude: Optional[float]
    speed: Optional[float]
    heading: Optional[float]
    timestamp: str
    number_plate: str
    is_active: bool


# ============================================================================
# JWT AUTHENTICATION
# ============================================================================
"""
Why reuse Django's JWT?
- Single source of truth: Same tokens work for both Django and FastAPI
- No duplicate login: User logs in once via Django, token works everywhere
- Consistent security: Same encryption, same expiry rules
"""

async def get_current_user(authorization: str = Header(None)) -> User:
    """
    Validates JWT token and returns the authenticated user.

    How it works:
    1. Extract token from "Authorization: Bearer <token>" header
    2. Decode JWT using Django's secret key
    3. Get user_id from token payload
    4. Query database for user
    5. Return user object or raise 401 error
    """
    if not authorization or not authorization.startswith('Bearer '):
        raise HTTPException(
            status_code=401,
            detail="Missing or invalid authorization header. Expected format: 'Bearer <token>'"
        )

    token = authorization.replace('Bearer ', '')

    try:
        # Decode JWT token (Django's library validates expiry, signature, etc.)
        access_token = AccessToken(token)
        user_id = access_token['user_id']

        # Fetch user from database
        user = User.objects.get(id=user_id)
        return user

    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail=f"Invalid or expired token: {str(e)}"
        )


# ============================================================================
# REST ENDPOINT: Driver Updates Location
# ============================================================================
@app.post("/api/realtime/buses/{bus_id}/location", response_model=dict)
async def update_bus_location(
    bus_id: int,
    location: LocationUpdate,
    user: User = Depends(get_current_user)
):
    """
    🚌 Driver posts GPS coordinates to update bus location.

    Called every 5-10 seconds from driver's mobile app.

    Flow:
    1. Driver app gets GPS: latitude=37.7749, longitude=-122.4194
    2. Driver app POSTs to this endpoint with JWT token
    3. We validate: Is this user a driver? Is this their assigned bus?
    4. We save to database: bus.latitude = 37.7749, bus.save()
    5. We broadcast to all parents watching this bus via WebSocket
    6. Parents' maps update instantly!

    Authorization:
    - Only drivers can call this endpoint (user_type='driver')
    - Driver can only update their OWN assigned bus
    - Example: Driver John (user_id=5) is assigned to Bus #3
      → John can update Bus #3 ✅
      → John CANNOT update Bus #7 ❌
    """
    try:
        # Fetch bus from database
        bus = Bus.objects.get(id=bus_id)

        # Authorization check: Only the assigned driver can update this bus
        if user.user_type != 'driver':
            raise HTTPException(
                status_code=403,
                detail=f"Access denied. Only drivers can update bus locations. Your role: {user.user_type}"
            )

        if bus.driver_id != user.id:
            raise HTTPException(
                status_code=403,
                detail=f"Access denied. You are not assigned to this bus. This bus is assigned to driver ID: {bus.driver_id}"
            )

        # Update bus location in database
        bus.latitude = location.latitude
        bus.longitude = location.longitude
        bus.speed = location.speed
        bus.heading = location.heading
        bus.is_active = True  # Mark bus as active when location updates
        bus.save()

        print(f"[LOCATION UPDATE] Bus #{bus_id} ({bus.number_plate}): "
              f"Lat={location.latitude}, Lon={location.longitude}, Speed={location.speed} km/h")

        # Broadcast to all connected parents watching this bus
        broadcast_data = {
            "bus_id": bus_id,
            "latitude": float(location.latitude),
            "longitude": float(location.longitude),
            "speed": location.speed,
            "heading": location.heading,
            "timestamp": datetime.now().isoformat(),
            "number_plate": bus.number_plate,
            "is_active": True
        }

        await broadcast_location_update(bus_id, broadcast_data)

        return {
            "status": "success",
            "message": "Location updated and broadcast to parents",
            "bus_id": bus_id,
            "connected_parents": len(active_connections.get(bus_id, {}))
        }

    except Bus.DoesNotExist:
        raise HTTPException(status_code=404, detail=f"Bus with ID {bus_id} not found")


# ============================================================================
# REST ENDPOINT: Get Current Bus Location
# ============================================================================
@app.get("/api/realtime/buses/{bus_id}/location", response_model=LocationResponse)
async def get_bus_location(
    bus_id: int,
    user: User = Depends(get_current_user)
):
    """
    📍 Get current bus location (fallback for devices that don't support WebSocket).

    Parents can poll this endpoint instead of using WebSocket.
    But WebSocket is preferred because it's more efficient!
    """
    try:
        bus = Bus.objects.get(id=bus_id)

        # Authorization: Only parents with children on this bus can view
        if user.user_type == 'parent':
            parent = user.parent
            has_child_on_bus = parent.children.filter(assigned_bus_id=bus_id).exists()
            if not has_child_on_bus:
                raise HTTPException(
                    status_code=403,
                    detail="You don't have any children assigned to this bus"
                )

        return LocationResponse(
            bus_id=bus.id,
            latitude=float(bus.latitude) if bus.latitude else None,
            longitude=float(bus.longitude) if bus.longitude else None,
            speed=bus.speed,
            heading=bus.heading,
            timestamp=bus.last_updated.isoformat() if bus.last_updated else None,
            number_plate=bus.number_plate,
            is_active=bus.is_active
        )

    except Bus.DoesNotExist:
        raise HTTPException(status_code=404, detail=f"Bus with ID {bus_id} not found")


# ============================================================================
# WEBSOCKET ENDPOINT: Parents Receive Real-Time Updates
# ============================================================================
@app.websocket("/ws/bus/{bus_id}/location")
async def bus_location_websocket(websocket: WebSocket, bus_id: int):
    """
    📡 Parents connect to this WebSocket to receive real-time location updates.

    How WebSocket works:
    1. Parent app connects: ws://server/ws/bus/1/location
    2. Connection stays open (unlike HTTP which closes after response)
    3. Server can PUSH data anytime without parent asking
    4. When driver updates location, server sends to all connected parents instantly
    5. No polling = efficient, real-time, battery-friendly

    Flow:
    1. Parent connects
    2. Parent sends authentication token in first message
    3. We verify: Is this user a parent? Do they have a child on this bus?
    4. We add connection to active_connections dictionary
    5. We send current location immediately
    6. Connection stays open, parent receives updates when driver moves
    7. When parent closes app, connection closes, we remove from active_connections
    """
    await websocket.accept()
    print(f"[WEBSOCKET] New connection attempt for Bus #{bus_id}")

    user = None

    try:
        # Step 1: Authenticate via first message
        auth_message = await websocket.receive_text()
        auth_data = json.loads(auth_message)
        token = auth_data.get('token')

        if not token:
            await websocket.send_json({"error": "Authentication required. Send {\"token\": \"your_jwt_token\"}"})
            await websocket.close()
            return

        # Step 2: Validate JWT token
        try:
            access_token = AccessToken(token)
            user_id = access_token['user_id']
            user = User.objects.get(id=user_id)
            print(f"[WEBSOCKET] Authenticated user: {user.username} (ID: {user_id})")
        except Exception as e:
            await websocket.send_json({"error": f"Invalid token: {str(e)}"})
            await websocket.close()
            return

        # Step 3: Authorization - Only parents with children on this bus
        if user.user_type == 'parent':
            try:
                parent = user.parent
                has_child_on_bus = parent.children.filter(assigned_bus_id=bus_id).exists()

                if not has_child_on_bus:
                    await websocket.send_json({
                        "error": "Access denied. You don't have any children assigned to this bus."
                    })
                    await websocket.close()
                    return

                print(f"[WEBSOCKET] Parent {user.username} authorized for Bus #{bus_id}")
            except ObjectDoesNotExist:
                await websocket.send_json({"error": "Parent profile not found"})
                await websocket.close()
                return
        elif user.user_type == 'busminder':
            # Bus minders can watch all buses
            print(f"[WEBSOCKET] Bus minder {user.username} authorized for Bus #{bus_id}")
        else:
            await websocket.send_json({
                "error": f"Access denied. Only parents and bus minders can track buses. Your role: {user.user_type}"
            })
            await websocket.close()
            return

        # Step 4: Add to active connections
        if bus_id not in active_connections:
            active_connections[bus_id] = {}
        active_connections[bus_id][user.id] = websocket
        print(f"[WEBSOCKET] Added to active connections. Bus #{bus_id} now has {len(active_connections[bus_id])} watchers")

        # Step 5: Send current location immediately
        try:
            bus = Bus.objects.get(id=bus_id)
            initial_data = {
                "bus_id": bus_id,
                "latitude": float(bus.latitude) if bus.latitude else None,
                "longitude": float(bus.longitude) if bus.longitude else None,
                "speed": bus.speed,
                "heading": bus.heading,
                "timestamp": bus.last_updated.isoformat() if bus.last_updated else None,
                "number_plate": bus.number_plate,
                "is_active": bus.is_active
            }
            await websocket.send_json(initial_data)
            print(f"[WEBSOCKET] Sent initial location to {user.username}")
        except Bus.DoesNotExist:
            await websocket.send_json({"error": f"Bus #{bus_id} not found"})
            await websocket.close()
            return

        # Step 6: Keep connection alive (wait for ping/pong or disconnect)
        """
        Why keep connection alive?
        - WebSocket needs to stay open to receive updates
        - We listen for 'ping' messages from client to verify connection is alive
        - If client closes app, we'll get WebSocketDisconnect exception
        """
        while True:
            data = await websocket.receive_text()

            # Heartbeat mechanism
            if data == "ping":
                await websocket.send_text("pong")
                # print(f"[WEBSOCKET] Heartbeat from {user.username}")

    except WebSocketDisconnect:
        # Client disconnected (closed app, lost internet, etc.)
        print(f"[WEBSOCKET] Client disconnected: {user.username if user else 'unknown'}")

        # Remove from active connections
        if user and bus_id in active_connections and user.id in active_connections[bus_id]:
            del active_connections[bus_id][user.id]
            print(f"[WEBSOCKET] Removed from active connections. Bus #{bus_id} now has {len(active_connections.get(bus_id, {}))} watchers")

            # Clean up empty bus entries
            if not active_connections[bus_id]:
                del active_connections[bus_id]

    except Exception as e:
        print(f"[WEBSOCKET ERROR] {e}")
        await websocket.close()


# ============================================================================
# BROADCAST HELPER FUNCTION
# ============================================================================
async def broadcast_location_update(bus_id: int, location_data: dict):
    """
    📢 Broadcast location update to all parents watching this bus.

    Called when driver updates location via POST endpoint.

    How it works:
    1. Driver POSTs new location
    2. We save to database
    3. We call this function
    4. This function finds all WebSocket connections for this bus_id
    5. Sends location_data to each connected parent
    6. If any connection is dead, we remove it

    Example:
    - Bus #1 has 3 parents watching (active_connections[1] = {42: ws1, 43: ws2, 44: ws3})
    - Driver updates location
    - We send location_data to ws1, ws2, and ws3
    - All 3 parents see their maps update instantly!
    """
    if bus_id not in active_connections:
        print(f"[BROADCAST] No active connections for Bus #{bus_id}")
        return

    num_connections = len(active_connections[bus_id])
    print(f"[BROADCAST] Sending location update to {num_connections} parent(s) watching Bus #{bus_id}")

    # Track dead connections to remove
    disconnected_users = []

    # Send to all connected clients for this bus
    for user_id, websocket in active_connections[bus_id].items():
        try:
            await websocket.send_json(location_data)
            # print(f"[BROADCAST] Sent to user ID {user_id}")
        except Exception as e:
            # Connection is dead (client disconnected without proper close)
            print(f"[BROADCAST] Failed to send to user ID {user_id}: {e}")
            disconnected_users.append(user_id)

    # Clean up dead connections
    for user_id in disconnected_users:
        del active_connections[bus_id][user_id]
        print(f"[BROADCAST] Removed dead connection for user ID {user_id}")


# ============================================================================
# HEALTH CHECK & MONITORING
# ============================================================================
@app.get("/api/realtime/health")
async def health_check():
    """
    ❤️ Health check endpoint for monitoring.

    Use this to check if FastAPI server is running and see how many active connections.
    """
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "active_buses_being_tracked": len(active_connections),
        "total_websocket_connections": sum(len(conns) for conns in active_connections.values()),
        "details": {
            bus_id: len(conns)
            for bus_id, conns in active_connections.items()
        }
    }


@app.get("/")
async def root():
    """Welcome message"""
    return {
        "message": "Bus Tracking Real-Time API",
        "docs": "/docs",
        "health": "/api/realtime/health"
    }
