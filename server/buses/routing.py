from django.urls import path
from .consumers import BusLocationConsumer

websocket_urlpatterns = [
    path("ws/bus/<int:bus_id>/", BusLocationConsumer.as_asgi()),
]
