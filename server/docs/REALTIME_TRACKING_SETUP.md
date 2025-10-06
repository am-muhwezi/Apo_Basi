# Real-Time Bus Location Tracking - Setup Guide

## 🎯 What We Built

A real-time bus tracking system where:
- **Drivers** send GPS coordinates every 5-10 seconds via REST API
- **Parents** receive instant location updates via WebSocket (no polling!)
- **FastAPI** handles WebSockets efficiently
- **Django** handles authentication, database, and business logic

## 📋 Prerequisites

1. **Install dependencies:**
   ```bash
   cd server
   pip install -r requirements.txt
   ```

2. **Run migrations:**
   ```bash
   python manage.py migrate
   ```

3. **Create test data in Django admin** (`python manage.py createsuperuser` first):
   - Create a Driver user (user_type='driver')
   - Create a Parent user (user_type='parent')
   - Create a Bus
   - Assign driver to bus (via Driver model)
   - Create a Child for the parent
   - Assign child to the bus

## 🚀 Start the Server

**Important:** Use Uvicorn instead of Django's runserver (to support ASGI/WebSockets):

```bash
uvicorn apo_basi.asgi:application --reload --host 0.0.0.0 --port 8000
```

## 🧪 Test the System

### Option 1: Automated Test Script

```bash
# Edit test_realtime_tracking.py to set your test credentials
python test_realtime_tracking.py
```

This will:
- ✓ Verify server is running
- ✓ Test driver authentication
- ✓ Send location updates
- ✓ Connect parent via WebSocket
- ✓ Verify real-time broadcasting

### Option 2: Manual Testing with cURL

```bash
# 1. Login as driver
curl -X POST http://localhost:8000/api/users/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "testdriver", "password": "testpass123"}'

# Copy the access token

# 2. Update bus location
curl -X POST http://localhost:8000/api/realtime/buses/1/location \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "latitude": 37.7749,
    "longitude": -122.4194,
    "speed": 45.5,
    "heading": 180.0
  }'
```

### Option 3: Interactive API Docs

Open in browser:
```
http://localhost:8000/docs
```

FastAPI auto-generates interactive API documentation!

## 📡 API Endpoints

### REST Endpoints (Driver)

**Update Location:**
```
POST /api/realtime/buses/{bus_id}/location
Authorization: Bearer {token}
{
  "latitude": 37.7749,
  "longitude": -122.4194,
  "speed": 45.5,
  "heading": 180.0
}
```

**Get Current Location:**
```
GET /api/realtime/buses/{bus_id}/location
Authorization: Bearer {token}
```

**Health Check:**
```
GET /api/realtime/health
```

### WebSocket Endpoint (Parent)

```
ws://localhost:8000/ws/bus/{bus_id}/location

1. Connect to WebSocket
2. Send authentication: {"token": "your_jwt_token"}
3. Receive real-time updates automatically
4. Send "ping" periodically to keep connection alive
```

## 📱 Mobile App Integration

### Driver App (Send Location)

```typescript
// Every 5 seconds, send GPS coordinates
const tracker = new BusLocationTracker(busId);
await tracker.startTracking();

// Internally does:
setInterval(async () => {
  const location = await Location.getCurrentPositionAsync();
  await api.post(`/api/realtime/buses/${busId}/location`, {
    latitude: location.coords.latitude,
    longitude: location.coords.longitude,
    speed: location.coords.speed || 0,
    heading: location.coords.heading || 0,
  });
}, 5000);
```

### Parent App (Receive Updates)

```typescript
// Connect once, receive updates automatically
const ws = new BusLocationWebSocket(busId, token, (locationData) => {
  // Update map marker
  setMapCenter(locationData.latitude, locationData.longitude);
});

ws.connect();
```

## 🔒 Security

- ✅ JWT authentication on all endpoints
- ✅ Drivers can only update their assigned bus
- ✅ Parents can only watch buses their children are on
- ✅ WebSocket connections require authentication
- ✅ Tokens expire after 60 minutes (configurable in settings.py)

## 🐛 Troubleshooting

### "Cannot connect to server"
- ✅ Make sure server is running with `uvicorn` (not `python manage.py runserver`)
- ✅ Check port 8000 is not blocked by firewall

### "WebSocket connection failed"
- ✅ Verify using `ws://` (not `wss://` in development)
- ✅ Check token is valid and not expired
- ✅ Ensure parent has a child assigned to the bus

### "403 Forbidden"
- ✅ Verify driver is assigned to the bus in database
- ✅ Check JWT token is correct and fresh
- ✅ Ensure user_type is 'driver' for driver endpoints

### "No updates received"
- ✅ Check driver is actually sending updates
- ✅ Verify WebSocket is still connected (send "ping", expect "pong")
- ✅ Check server logs for broadcast messages

## 📊 Monitoring

Check active connections:
```bash
curl http://localhost:8000/api/realtime/health
```

Example response:
```json
{
  "status": "healthy",
  "active_buses_being_tracked": 2,
  "total_websocket_connections": 5,
  "details": {
    "1": 3,  // Bus #1 has 3 parents watching
    "2": 2   // Bus #2 has 2 parents watching
  }
}
```

## 🎓 Understanding the Flow

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│ Driver App  │         │   FastAPI    │         │ Parent App  │
│  (Mobile)   │         │   Server     │         │  (Mobile)   │
└─────────────┘         └──────────────┘         └─────────────┘
       │                       │                        │
       │ 1. POST location      │                        │
       │──────────────────────>│                        │
       │                       │                        │
       │                       │ 2. Save to database    │
       │                       │──────┐                 │
       │                       │      │                 │
       │                       │<─────┘                 │
       │                       │                        │
       │                       │ 3. Broadcast via WS    │
       │                       │───────────────────────>│
       │                       │                        │
       │                       │                  4. Update map
       │                       │                        │
       │ 5. POST location      │                        │
       │──────────────────────>│                        │
       │                       │                        │
       │                       │ 6. Broadcast via WS    │
       │                       │───────────────────────>│
       │                       │                        │
```

## 🚀 Next Steps

1. **Add to Driver App:**
   - Request GPS permissions
   - Send location updates every 5-10 seconds
   - Show "Tracking Active" indicator

2. **Add to Parent App:**
   - Connect WebSocket on app open
   - Display map with bus marker
   - Update marker position on location updates
   - Show bus speed and ETA

3. **Production Enhancements:**
   - Use Redis for connection storage (multi-server scaling)
   - Add location history tracking
   - Implement geofencing for pickup/dropoff zones
   - Add offline support and queue updates
   - Use `wss://` (secure WebSocket) in production

## 📚 Resources

- FastAPI Docs: https://fastapi.tiangolo.com
- WebSockets: https://websockets.readthedocs.io
- Django ASGI: https://docs.djangoproject.com/en/5.2/howto/deployment/asgi/
- React Native Maps: https://github.com/react-native-maps/react-native-maps
- Expo Location: https://docs.expo.dev/versions/latest/sdk/location/

---

**Questions?** Check the inline comments in `buses/realtime.py` - every function is heavily documented!
