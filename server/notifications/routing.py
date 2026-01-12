from django.urls import path
from .consumers import ParentNotificationsConsumer

websocket_urlpatterns = [
    # Primary websocket endpoint for parent notifications
    path("ws/notifications/parent/", ParentNotificationsConsumer.as_asgi()),
    # Backwards-compatible alias for clients using `/notifications/parent/`
    path("notifications/parent/", ParentNotificationsConsumer.as_asgi()),
]
