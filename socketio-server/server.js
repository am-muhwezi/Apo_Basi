const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const axios = require('axios');
require('dotenv').config();

const app = express();
const httpServer = createServer(app);

// CORS configuration
app.use(cors({
  origin: '*',  // Allow all origins for development
  methods: ['GET', 'POST']
}));

app.use(express.json());

// Socket.IO server with CORS
const io = new Server(httpServer, {
  cors: {
    origin: '*',  // Allow all origins for development
    methods: ['GET', 'POST']
  }
});

// Configuration
const PORT = process.env.SOCKET_PORT || 3000;
const DJANGO_API_URL = process.env.DJANGO_API_URL || 'http://localhost:8000';
const JWT_SECRET = process.env.JWT_SECRET || 'django-insecure-q04vc+va)aw09=9&o#)_@zr=bm=6d%xfqee1^x4$+w^x&1w$s$';  // Should match Django SECRET_KEY

// Store active connections
// Format: { userId: socketId, busId: [parentSocketIds], driverSocketId: socketId }
const connections = {
  parents: new Map(),  // Map of parent user_id to socket
  drivers: new Map(),  // Map of driver user_id to socket
  admins: new Map(),   // Map of admin user_id to socket
  buses: new Map(),    // Map of bus_id to array of parent sockets
};

// Middleware for Socket.IO authentication
io.use((socket, next) => {
  const token = socket.handshake.auth.token;

  if (!token) {
    return next(new Error('Authentication error: No token provided'));
  }

  try {
    // Verify JWT token (Django uses HS256)
    const decoded = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] });
    socket.userId = decoded.user_id;
    socket.userType = socket.handshake.auth.userType; // 'parent' or 'driver'
    next();
  } catch (err) {
    next(new Error('Authentication error: Invalid token'));
  }
});

// Socket.IO connection handler
io.on('connection', (socket) => {
  console.log(`Client connected: ${socket.id}, User ID: ${socket.userId}, Type: ${socket.userType}`);

  // Handle parent connection
  if (socket.userType === 'parent') {
    connections.parents.set(socket.userId, socket);

    // Parent subscribes to their child's bus (support both event names)
    const handleSubscribe = async (data) => {
      const busId = data.busId || data;

      // Verify parent has access to this bus (call Django API)
      try {
        const response = await axios.get(`${DJANGO_API_URL}/api/parents/${socket.userId}/children/`, {
          headers: { 'Authorization': `Bearer ${socket.handshake.auth.token}` }
        });

        const children = response.data.children || [];

        // Check both bus_id and assignedBus.id
        const hasAccess = children.some(child => {
          const childBusId = child.bus_id || child.assignedBus?.id;
          return childBusId === parseInt(busId);
        });

        if (hasAccess) {
          socket.join(`bus_${busId}`);

          // Track this parent for this bus
          if (!connections.buses.has(busId)) {
            connections.buses.set(busId, new Set());
          }
          connections.buses.get(busId).add(socket.userId);

          socket.emit('subscribed', { busId, success: true });
          console.log(`✅ Parent ${socket.userId} subscribed to bus ${busId}`);
        } else {
          socket.emit('error', { message: 'Access denied to this bus' });
        }
      } catch (error) {
        console.error('Error verifying bus access:', error.message);
        socket.emit('error', { message: 'Failed to verify bus access' });
      }
    };

    socket.on('subscribe_to_bus', handleSubscribe);
    socket.on('subscribe_bus', handleSubscribe); // Support both event names
  }

  // Handle driver connection
  if (socket.userType === 'driver') {
    connections.drivers.set(socket.userId, socket);

    // Driver starts a trip
    socket.on('start_trip', async (data) => {
      const { busId, tripType, tripId } = data;
      console.log(`Driver ${socket.userId} starting ${tripType} trip for bus ${busId}, trip ID: ${tripId}`);

      // Notify all parents subscribed to this bus
      io.to(`bus_${busId}`).emit('trip_started', {
        busId,
        tripType,
        tripId,
        message: `Your child's bus has started the ${tripType} trip`,
        timestamp: new Date().toISOString()
      });

      console.log(`Notified parents on bus ${busId} about trip start`);
      socket.emit('trip_start_confirmed', { success: true, busId, tripType });
    });

    // Driver sends location update
    socket.on('location_update', (data) => {
      const { busId, latitude, longitude, speed, heading } = data;

      // Broadcast location to all parents subscribed to this bus
      // Use 'location_update' to match Parents app expectations
      io.to(`bus_${busId}`).emit('location_update', {
        busId,
        bus_number: data.bus_number || data.busNumber || `BUS-${busId}`,
        latitude,
        longitude,
        speed: speed || 0,
        heading: heading || 0,
        timestamp: new Date().toISOString()
      });

      // console.log(`Location update for bus ${busId}: ${latitude}, ${longitude}`);
    });

    // Driver completes a trip
    socket.on('complete_trip', (data) => {
      const { busId, tripId } = data;
      console.log(`Driver ${socket.userId} completed trip ${tripId} for bus ${busId}`);

      // Notify all parents subscribed to this bus
      io.to(`bus_${busId}`).emit('trip_completed', {
        busId,
        tripId,
        message: 'Trip has been completed',
        timestamp: new Date().toISOString()
      });
    });
  }

  // Handle admin connection
  if (socket.userType === 'admin') {
    connections.admins.set(socket.userId, socket);

    // Admin subscribes to monitor all buses or specific buses
    socket.on('subscribe_to_bus', (data) => {
      const busId = data.busId || data;

      if (busId === 'all') {
        // Subscribe to all buses
        socket.join('admin_all_buses');
        console.log(`✅ Admin ${socket.userId} subscribed to ALL buses`);
        socket.emit('subscribed', { busId: 'all', success: true });
      } else {
        // Subscribe to specific bus
        socket.join(`bus_${busId}`);
        socket.join(`admin_bus_${busId}`);
        console.log(`✅ Admin ${socket.userId} subscribed to bus ${busId}`);
        socket.emit('subscribed', { busId, success: true });
      }
    });

    // Admin unsubscribes from a bus
    socket.on('unsubscribe_from_bus', (data) => {
      const busId = data.busId || data;

      if (busId === 'all') {
        socket.leave('admin_all_buses');
        console.log(`Admin ${socket.userId} unsubscribed from ALL buses`);
      } else {
        socket.leave(`bus_${busId}`);
        socket.leave(`admin_bus_${busId}`);
        console.log(`Admin ${socket.userId} unsubscribed from bus ${busId}`);
      }

      socket.emit('unsubscribed', { busId, success: true });
    });

    // Admin requests current status of all active trips
    socket.on('request_active_trips', async () => {
      try {
        const response = await axios.get(`${DJANGO_API_URL}/api/trips/?status=in-progress`, {
          headers: { 'Authorization': `Bearer ${socket.handshake.auth.token}` }
        });

        socket.emit('active_trips', {
          trips: response.data.results || response.data || [],
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('Error fetching active trips:', error.message);
        socket.emit('error', { message: 'Failed to fetch active trips' });
      }
    });
  }

  // Handle disconnection
  socket.on('disconnect', () => {
    console.log(`Client disconnected: ${socket.id}, User ID: ${socket.userId}`);

    if (socket.userType === 'parent') {
      connections.parents.delete(socket.userId);

      // Remove from bus subscriptions
      connections.buses.forEach((parents, busId) => {
        parents.delete(socket.userId);
        if (parents.size === 0) {
          connections.buses.delete(busId);
        }
      });
    } else if (socket.userType === 'driver') {
      connections.drivers.delete(socket.userId);
    } else if (socket.userType === 'admin') {
      connections.admins.delete(socket.userId);
    }
  });
});

// REST endpoint for Django backend to trigger trip start notifications
app.post('/api/notify/trip-start', async (req, res) => {
  const { busId, tripType, tripId, driverUserId, busNumber, routeName, estimatedDuration } = req.body;

  if (!busId || !tripType) {
    return res.status(400).json({ error: 'busId and tripType are required' });
  }

  console.log(`📢 Received trip start notification for bus ${busNumber || busId}, type ${tripType}`);

  const tripStartData = {
    busId,
    busNumber,
    tripType,
    tripId,
    routeName,
    title: '🚌 Bus Trip Started',
    message: `Your child's bus (${busNumber || 'Bus ' + busId}) has started the ${tripType} trip${routeName ? ` on route ${routeName}` : ''}`,
    subtitle: estimatedDuration ? `Estimated duration: ${estimatedDuration} minutes` : '',
    timestamp: new Date().toISOString(),
    notificationType: 'trip_start',
    priority: 'high'
  };

  // Emit to all parents subscribed to this bus
  io.to(`bus_${busId}`).emit('trip_started', tripStartData);

  // Also emit to admins monitoring all buses
  io.to('admin_all_buses').emit('trip_started', tripStartData);

  res.json({ success: true, notified: true });
});

// REST endpoint for child pickup/dropoff notifications
app.post('/api/notify/child-status', async (req, res) => {
  const { busId, childId, childName, status, timestamp, parentUserIds, busNumber, location, eta } = req.body;

  if (!busId || !childId || !status) {
    return res.status(400).json({ error: 'busId, childId, and status are required' });
  }

  const statusConfig = {
    'on_bus': {
      emoji: '🚌',
      title: 'Child Picked Up',
      message: `${childName} has boarded the bus and is heading to school`,
      priority: 'high',
      sound: true
    },
    'at_school': {
      emoji: '🏫',
      title: 'Arrived at School',
      message: `${childName} has safely arrived at school`,
      priority: 'normal',
      sound: false
    },
    'on_way_home': {
      emoji: '🏠',
      title: 'Heading Home',
      message: `${childName} is on the bus and heading home`,
      priority: 'high',
      sound: true
    },
    'dropped_off': {
      emoji: '✅',
      title: 'Dropped Off at Home',
      message: `${childName} has been safely dropped off at home`,
      priority: 'high',
      sound: true
    },
    'absent': {
      emoji: '❌',
      title: 'Marked Absent',
      message: `${childName} is marked absent for this trip`,
      priority: 'normal',
      sound: false
    }
  };

  const config = statusConfig[status] || {
    emoji: 'ℹ️',
    title: 'Status Update',
    message: `${childName} status: ${status}`,
    priority: 'normal',
    sound: false
  };

  console.log(`👶 Child ${childName} (ID: ${childId}) status: ${status} on bus ${busNumber || busId}`);

  const notificationData = {
    busId,
    busNumber,
    childId,
    childName,
    status,
    title: `${config.emoji} ${config.title}`,
    message: config.message,
    subtitle: eta ? `ETA: ${eta} minutes` : '',
    location,
    eta,
    timestamp: timestamp || new Date().toISOString(),
    notificationType: 'child_status',
    priority: config.priority,
    playSound: config.sound
  };

  // If specific parent user IDs provided, notify only those parents
  if (parentUserIds && Array.isArray(parentUserIds)) {
    parentUserIds.forEach(parentId => {
      const parentSocket = connections.parents.get(parentId);
      if (parentSocket) {
        parentSocket.emit('child_status_update', notificationData);
      }
    });
  } else {
    // Otherwise, broadcast to all parents on this bus
    io.to(`bus_${busId}`).emit('child_status_update', notificationData);
  }

  res.json({ success: true, notified: true });
});

// REST endpoint for trip completion
app.post('/api/notify/trip-end', async (req, res) => {
  const { busId, tripType, tripId, busNumber, totalStudents, droppedOff, duration } = req.body;

  if (!busId) {
    return res.status(400).json({ error: 'busId is required' });
  }

  console.log(`✅ Trip ended for bus ${busNumber || busId}`);

  const tripEndData = {
    busId,
    busNumber,
    tripType,
    tripId,
    title: '✅ Trip Completed',
    message: `The ${tripType || ''} trip has been completed successfully`,
    subtitle: totalStudents ? `${droppedOff || totalStudents}/${totalStudents} students delivered safely` : '',
    duration,
    totalStudents,
    droppedOff,
    timestamp: new Date().toISOString(),
    notificationType: 'trip_end',
    priority: 'normal'
  };

  io.to(`bus_${busId}`).emit('trip_ended', tripEndData);

  // Also emit to admins monitoring all buses
  io.to('admin_all_buses').emit('trip_ended', tripEndData);

  res.json({ success: true, notified: true });
});

// REST endpoint for Django backend to send location updates
app.post('/api/notify/location-update', (req, res) => {
  const { busId, latitude, longitude, speed, heading, bus_number } = req.body;

  if (!busId || latitude == null || longitude == null) {
    return res.status(400).json({ error: 'busId, latitude, and longitude are required' });
  }

  const locationData = {
    busId,
    bus_number: bus_number || `BUS-${busId}`,
    latitude,
    longitude,
    speed: speed || 0,
    heading: heading || 0,
    timestamp: new Date().toISOString()
  };

  // Emit to parents subscribed to this specific bus
  io.to(`bus_${busId}`).emit('location_update', locationData);

  // Also emit to admins monitoring all buses
  io.to('admin_all_buses').emit('location_update', locationData);

  res.json({ success: true });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    connections: {
      parents: connections.parents.size,
      drivers: connections.drivers.size,
      admins: connections.admins.size,
      buses: connections.buses.size
    }
  });
});

// Start server (listen on all interfaces)
httpServer.listen(PORT, '0.0.0.0', () => {
  console.log(`Socket.IO server running on port ${PORT}`);
  console.log(`Django API URL: ${DJANGO_API_URL}`);
  console.log(`Server accessible at: http://192.168.100.65:${PORT}`);
  console.log(`Waiting for connections...`);
});
