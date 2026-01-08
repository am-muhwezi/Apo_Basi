const jwt = require('jsonwebtoken');

// Configuration
const JWT_SECRET = process.env.JWT_SECRET || 'django-insecure-q04vc+va)aw09=9&o#)_@zr=bm=6d%xfqee1^x4$+w^x&1w$s$';

/**
 * Socket.IO authentication middleware
 * Verifies JWT tokens from Django backend
 */
function socketAuthMiddleware(socket, next) {
  const token = socket.handshake.auth.token;

  if (!token) {
    return next(new Error('Authentication error: No token provided'));
  }

  try {
    // Verify JWT token (Django uses HS256)
    const decoded = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] });
    socket.userId = decoded.user_id;
    socket.userType = socket.handshake.auth.userType; // 'parent', 'driver', or 'admin'
    next();
  } catch (err) {
    next(new Error('Authentication error: Invalid token'));
  }
}

module.exports = {
  socketAuthMiddleware,
  JWT_SECRET
};
