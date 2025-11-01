const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");
const path = require("path");

const app = express();
app.use(cors());
app.use(express.json());

// Serve static files (for test-client.html)
app.use(express.static(path.join(__dirname)));

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: "*", // In production, restrict to your Flutter or web domain
  },
});

// Store active drivers (in-memory)
const activeDrivers = new Map();

// When a parent or driver connects
io.on("connection", (socket) => {
  console.log("✅ User connected:", socket.id);

  // Extract headers if available
  const driverId = socket.handshake.headers['driver_id'];
  const busId = socket.handshake.headers['bus_id'];

  if (driverId && busId) {
    console.log(`🚌 Driver ${driverId} connected for bus ${busId}`);
    socket.driverId = driverId;
    socket.busId = busId;
  }

  // Example: driver sends location updates
  socket.on("driver_location", (data) => {
    console.log("📍 Driver location (broadcast):", data);

    // Store driver's last location
    activeDrivers.set(socket.id, {
      socketId: socket.id,
      ...data,
      lastUpdate: new Date().toISOString(),
    });

    // Broadcast this to all parents subscribed to this bus
    io.emit("bus_update", data);
  });

  // Join a specific room per bus ID
  socket.on("join_bus_room", (busId) => {
    socket.join(`bus_${busId}`);
    console.log(`🚌 Socket ${socket.id} joined bus room: bus_${busId}`);
    socket.busId = busId;
  });

  // Driver sends to specific bus room (recommended approach)
  socket.on("driver_location_room", (payload) => {
    console.log(`📍 Location update for bus ${payload.busId}:`, {
      lat: payload.latitude?.toFixed(4),
      lng: payload.longitude?.toFixed(4),
      speed: payload.speed?.toFixed(1),
      accuracy: `±${Math.round(payload.accuracy)}m`,
    });

    // Store driver's last location
    activeDrivers.set(socket.id, {
      socketId: socket.id,
      driverId: socket.driverId,
      ...payload,
      lastUpdate: new Date().toISOString(),
    });

    // Emit to specific bus room
    io.to(`bus_${payload.busId}`).emit("bus_update", payload);

    // Also emit globally for testing
    io.emit("bus_location_global", payload);
  });

  // Disconnect handler
  socket.on("disconnect", () => {
    console.log("❌ User disconnected:", socket.id);
    if (socket.driverId && socket.busId) {
      console.log(`🚌 Driver ${socket.driverId} (Bus ${socket.busId}) disconnected`);
    }
    activeDrivers.delete(socket.id);
  });
});

// Basic REST route (for testing)
app.get("/", (req, res) => {
  res.json({
    status: "running",
    message: "Socket.IO bus tracking server is running!",
    activeDrivers: activeDrivers.size,
    timestamp: new Date().toISOString(),
  });
});

// Get all active drivers with their locations
app.get("/active-drivers", (req, res) => {
  const drivers = Array.from(activeDrivers.values()).map((driver) => ({
    socketId: driver.socketId,
    busId: driver.busId,
    latitude: driver.latitude,
    longitude: driver.longitude,
    accuracy: driver.accuracy,
    speed: driver.speed,
    lastUpdate: driver.lastUpdate,
  }));

  res.json({
    count: drivers.length,
    drivers: drivers,
  });
});

// Get location for specific bus
app.get("/bus/:busId/location", (req, res) => {
  const { busId } = req.params;
  const driver = Array.from(activeDrivers.values()).find(
    (d) => d.busId === busId
  );

  if (driver) {
    res.json({
      found: true,
      busId: driver.busId,
      latitude: driver.latitude,
      longitude: driver.longitude,
      accuracy: driver.accuracy,
      speed: driver.speed,
      lastUpdate: driver.lastUpdate,
    });
  } else {
    res.status(404).json({
      found: false,
      message: `No active driver found for bus ${busId}`,
    });
  }
});

// Start server
const PORT = process.env.PORT || 4000;
server.listen(PORT, () => console.log(`Realtime server running on port ${PORT}`));
