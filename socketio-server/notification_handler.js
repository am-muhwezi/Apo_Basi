/**
 * Notification Handler
 * Handles event-driven notifications for trips and child status
 * - Trip start/end notifications
 * - Child pickup/dropoff status updates
 * - Lower frequency than location updates
 */

/**
 * Setup notification-related socket event handlers
 * @param {Socket} socket - Socket.IO socket instance
 * @param {Server} io - Socket.IO server instance
 */
function setupNotificationHandlers(socket, io) {
  // Only drivers can trigger trip notifications via socket
  if (socket.userType !== 'driver') {
    return;
  }

  // Driver starts a trip
  socket.on('start_trip', async (data) => {
    const { busId, tripType, tripId } = data;
    console.log(`🚌 Driver ${socket.userId} starting ${tripType} trip for bus ${busId}, trip ID: ${tripId}`);

    // Notify all parents subscribed to this bus
    io.to(`bus_${busId}`).emit('trip_started', {
      busId,
      tripType,
      tripId,
      message: `Your child's bus has started the ${tripType} trip`,
      timestamp: new Date().toISOString()
    });

    console.log(`✅ Notified parents on bus ${busId} about trip start`);
    socket.emit('trip_start_confirmed', { success: true, busId, tripType });
  });

  // Driver completes a trip
  socket.on('complete_trip', (data) => {
    const { busId, tripId } = data;
    console.log(`✅ Driver ${socket.userId} completed trip ${tripId} for bus ${busId}`);

    // Notify all parents subscribed to this bus
    io.to(`bus_${busId}`).emit('trip_completed', {
      busId,
      tripId,
      message: 'Trip has been completed',
      timestamp: new Date().toISOString()
    });
  });
}

/**
 * Setup notification-related REST endpoints
 * These allow the Django backend to trigger notifications
 * @param {Express} app - Express app instance
 * @param {Server} io - Socket.IO server instance
 * @param {Map} connections - Active connections map
 */
function setupNotificationEndpoints(app, io, connections) {
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
}

module.exports = {
  setupNotificationHandlers,
  setupNotificationEndpoints
};
