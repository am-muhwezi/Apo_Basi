"""
ASGI config for apo_basi project.

This configuration mounts both Django and FastAPI in a single application:
- Django handles: REST API, authentication, admin panel, database models
- FastAPI handles: WebSocket connections, real-time bus tracking
- They share: Database, JWT authentication, same Django models

Why ASGI?
- ASGI = Async Server Gateway Interface (successor to WSGI)
- Supports async/await (needed for WebSockets)
- Can handle both HTTP and WebSocket protocols
- Single server, single port, unified deployment
"""

import os
from django.core.asgi import get_asgi_application

# Set Django settings before importing anything Django-related
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "apo_basi.settings")

# Initialize Django first (this must happen before importing FastAPI app)
django_asgi_app = get_asgi_application()

# Now import FastAPI app (after Django is initialized)
from buses.realtime import app as fastapi_app
from fastapi.middleware.cors import CORSMiddleware

# Add CORS to FastAPI for React Native
fastapi_app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins like ["https://yourapp.com"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


async def application(scope, receive, send):
    """
    Main ASGI application - routes requests to Django or FastAPI.

    How routing works:
    1. Request comes in
    2. Check the path:
       - /api/realtime/* → FastAPI (real-time tracking endpoints)
       - /ws/* → FastAPI (WebSocket connections)
       - Everything else → Django (admin, auth, regular REST API)
    3. Forward to appropriate framework

    Example routing:
    - POST /api/users/login/ → Django (DRF authentication)
    - POST /api/realtime/buses/1/location → FastAPI (driver updates location)
    - ws://server/ws/bus/1/location → FastAPI (parent receives updates)
    - GET /admin/ → Django (admin panel)
    """

    # Handle HTTP requests
    if scope['type'] == 'http':
        path = scope['path']

        # Route real-time API to FastAPI
        if path.startswith('/api/realtime/') or path.startswith('/docs') or path.startswith('/openapi.json'):
            await fastapi_app(scope, receive, send)
        else:
            # Route everything else to Django
            await django_asgi_app(scope, receive, send)

    # Handle WebSocket connections
    elif scope['type'] == 'websocket':
        # All WebSockets go to FastAPI
        await fastapi_app(scope, receive, send)

    # Fallback to Django for other protocols
    else:
        await django_asgi_app(scope, receive, send)
