import os
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "apo_basi.settings")

# Initialize Django ASGI application early to ensure the AppRegistry
# is populated before importing code that may import ORM models.
django_asgi_app = get_asgi_application()


def normalize_http_path_middleware(app):
    """ASGI middleware to normalize HTTP paths.

    This currently collapses multiple leading slashes into a single one so
    that requests like ``//api/buses/push-location/`` are treated the same
    as ``/api/buses/push-location/`` by Django's URL resolver. This helps
    older or misconfigured clients that accidentally send double leading
    slashes.
    """

    async def inner(scope, receive, send):
        if scope.get("type") == "http":
            path = scope.get("path", "")
            # Collapse multiple leading slashes, e.g. "//api" -> "/api"
            if path.startswith("//"):
                idx = 0
                while idx < len(path) and path[idx] == "/":
                    idx += 1
                path = "/" + path[idx:]
                scope = {**scope, "path": path}
        return await app(scope, receive, send)

    return inner


# NOW we can import routing which imports consumers
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
import apo_basi.routing

application = ProtocolTypeRouter({
    "http": normalize_http_path_middleware(django_asgi_app),
    "websocket": AuthMiddlewareStack(
        URLRouter(
            apo_basi.routing.websocket_urlpatterns
        )
    ),
})
