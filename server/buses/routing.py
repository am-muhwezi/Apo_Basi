from django.urls import path
from .consumers import BusLocationConsumer

websocket_urlpatterns = [
    # Primary, documented websocket endpoint
    path("ws/bus/<int:bus_id>/", BusLocationConsumer.as_asgi()),
    # Backwards-compatible alias to support older clients using `/bus/<id>/`
    path("bus/<int:bus_id>/", BusLocationConsumer.as_asgi()),
]
