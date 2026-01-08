/**
 * Location Handler
 * Handles real-time location updates for buses
 * - High frequency updates (every 5 seconds)
 * - Broadcasts to subscribed parents and admins
 */

/**
 * Setup location-related socket event handlers
 * @param {Socket} socket - Socket.IO socket instance
 * @param {Server} io - Socket.IO server instance
 */
function setupLocationHandlers(socket, io) {
  // Only drivers can send location updates
  if (socket.userType !== 'driver') {
    return;
  }

  // Driver sends location update
  socket.on('location_update', (data) => {
    const { busId, latitude, longitude, speed, heading } = data;

    // Broadcast location to all parents subscribed to this bus
    io.to(`bus_${busId}`).emit('location_update', {
      busId,
      bus_number: data.bus_number || data.busNumber || `BUS-${busId}`,
      latitude,
      longitude,
      speed: speed || 0,
      heading: heading || 0,
      timestamp: new Date().toISOString()
    });

    // Also broadcast to admins monitoring all buses or this specific bus
    io.to('admin_all_buses').emit('location_update', {
      busId,
      bus_number: data.bus_number || data.busNumber || `BUS-${busId}`,
      latitude,
      longitude,
      speed: speed || 0,
      heading: heading || 0,
      timestamp: new Date().toISOString()
    });

    // Uncomment for verbose logging:
    // console.log(`📍 Location update for bus ${busId}: ${latitude}, ${longitude}`);
  });
}

/**
 * Setup location-related REST endpoints
 * These allow the Django backend to push location updates
 * @param {Express} app - Express app instance
 * @param {Server} io - Socket.IO server instance
 */
function setupLocationEndpoints(app, io) {
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
}

module.exports = {
  setupLocationHandlers,
  setupLocationEndpoints
};
