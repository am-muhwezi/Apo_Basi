from buses.routing import websocket_urlpatterns as bus_ws
from notifications.routing import websocket_urlpatterns as notification_ws

websocket_urlpatterns = []
websocket_urlpatterns += bus_ws
websocket_urlpatterns += notification_ws
