"""
Bus URL Configuration using DRF Router.

DRF Router automatically generates URL patterns for ViewSets.

Generated URLs:
    GET    /api/buses/                      → list
    POST   /api/buses/                      → create
    GET    /api/buses/:id/                  → retrieve
    PUT    /api/buses/:id/                  → update
    PATCH  /api/buses/:id/                  → partial_update
    DELETE /api/buses/:id/                  → destroy
    POST   /api/buses/:id/assign-driver/    → custom action
    POST   /api/buses/:id/assign-minder/    → custom action
    POST   /api/buses/:id/assign-children/  → custom action
    GET    /api/buses/:id/children/         → custom action

Additional endpoints (non-ViewSet):
    POST   /api/buses/push-location/        → push location (drivers)
    GET    /api/buses/:id/current-location/ → get current location (parents/admins)

Benefits over manual URL configuration:
    - Automatic URL generation
    - Consistent naming conventions
    - Less code to maintain
    - Built-in support for API browsability
"""

from django.urls import path
from rest_framework.routers import DefaultRouter
from .views import BusViewSet, push_location, current_location

# Create a router and register the BusViewSet
router = DefaultRouter()
router.register(r'', BusViewSet, basename='bus')

# URL patterns: router + custom location endpoints
urlpatterns = [
    # Real-time location tracking endpoints
    path('push-location/', push_location, name='push-location'),
    path('<int:bus_id>/current-location/', current_location, name='current-location'),
] + router.urls

# The router generates these URLs:
# [
#     url(r'^$', BusViewSet.as_view({'get': 'list', 'post': 'create'}), name='bus-list'),
#     url(r'^(?P<pk>[^/.]+)/$', BusViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='bus-detail'),
#     url(r'^(?P<pk>[^/.]+)/assign-driver/$', BusViewSet.as_view({'post': 'assign_driver'}), name='bus-assign-driver'),
#     url(r'^(?P<pk>[^/.]+)/assign-minder/$', BusViewSet.as_view({'post': 'assign_minder'}), name='bus-assign-minder'),
#     url(r'^(?P<pk>[^/.]+)/assign-children/$', BusViewSet.as_view({'post': 'assign_children'}), name='bus-assign-children'),
#     url(r'^(?P<pk>[^/.]+)/children/$', BusViewSet.as_view({'get': 'children'}), name='bus-children'),
# ]
