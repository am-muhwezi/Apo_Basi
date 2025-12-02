# Socket.IO Server for Real-Time Bus Tracking

This Node.js server handles real-time communication between drivers and parents for live bus tracking and notifications.

## Quick Start

```bash
# Install dependencies
npm install

# Start server
npm start

# Development with auto-reload
npm run dev
```

Server runs on `http://localhost:3000`

## Configuration

Edit `.env` file:
```env
SOCKET_PORT=3000
DJANGO_API_URL=http://localhost:8000
JWT_SECRET=your-django-secret-key
```

## Features

- **JWT Authentication**: Secure connections for parents and drivers
- **Room-Based Messaging**: Parents subscribe to specific bus rooms
- **Real-Time Location**: Broadcast GPS updates from drivers to parents
- **Trip Notifications**: Instant alerts when trips start/complete

## API Endpoints

### REST Endpoints

**POST /api/notify/trip-start**
```json
{
  "busId": 11,
  "tripType": "pickup",
  "tripId": 123,
  "driverUserId": 5
}
```

**POST /api/notify/location-update**
```json
{
  "busId": 11,
  "latitude": 0.3476,
  "longitude": 32.5825,
  "speed": 40,
  "heading": 90
}
```

**GET /health**
Returns connection statistics

### Socket.IO Events

#### From Client

- `subscribe_to_bus` - Parent subscribes to bus updates
- `start_trip` - Driver starts a trip
- `location_update` - Driver sends GPS location
- `complete_trip` - Driver completes trip

#### To Client

- `trip_started` - Broadcast to parents when trip starts
- `bus_location_update` - Real-time GPS updates
- `trip_completed` - Trip completion notification
- `subscribed_to_bus` - Subscription confirmation

## Testing

### Test Connection
```bash
curl http://localhost:3000/health
```

### Monitor Logs
```bash
npm start
# Watch console for connection events
```

## Deployment

### Using PM2 (Recommended)
```bash
npm install -g pm2
pm2 start server.js --name socketio-server
pm2 save
pm2 startup
```

### Using Docker
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## Architecture

```
Django Backend → Socket.IO Server → Mobile Clients
     ↓                  ↓                ↓
  REST API         WebSocket      Parents & Drivers
```

## For More Information

See the main project documentation:
- `/home/m/work/Apo_Basi/REALTIME_TRACKING_GUIDE.md` - Complete implementation guide
- Server code: `server.js`
- Environment: `.env`
