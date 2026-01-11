from django.urls import path
from .consumers import ParentNotificationsConsumer

websocket_urlpatterns = [
    path("ws/notifications/parent/", ParentNotificationsConsumer.as_asgi()),
]
