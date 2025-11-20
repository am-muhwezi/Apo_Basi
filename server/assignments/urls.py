from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    AssignmentViewSet,
    BusRouteViewSet,
    AssignmentHistoryViewSet,
    DriverAssignmentsView,
    BusAssignmentsView,
    ChildAssignmentsView,
    ParentChildrenAssignmentsView,
    MinderAssignmentsView,
    QuickAssignView
)

# Create router and register viewsets
router = DefaultRouter()
router.register(r'routes', BusRouteViewSet, basename='busroute')
router.register(r'history', AssignmentHistoryViewSet, basename='assignment-history')
router.register(r'list', AssignmentViewSet, basename='assignment')

urlpatterns = [
    # Router-based endpoints
    path('', include(router.urls)),

    # Convenience endpoints - Driver
    path('driver/<int:driver_id>/bus/', DriverAssignmentsView.as_view(), {'query_type': 'bus'}, name='driver-bus'),
    path('driver/<int:driver_id>/children/', DriverAssignmentsView.as_view(), {'query_type': 'children'}, name='driver-children'),
    path('driver/<int:driver_id>/route/', DriverAssignmentsView.as_view(), {'query_type': 'route'}, name='driver-route'),

    # Convenience endpoints - Bus
    path('bus/<int:bus_id>/all/', BusAssignmentsView.as_view(), {'query_type': 'all'}, name='bus-all'),
    path('bus/<int:bus_id>/children/', BusAssignmentsView.as_view(), {'query_type': 'children'}, name='bus-children'),
    path('bus/<int:bus_id>/driver/', BusAssignmentsView.as_view(), {'query_type': 'driver'}, name='bus-driver'),
    path('bus/<int:bus_id>/minder/', BusAssignmentsView.as_view(), {'query_type': 'minder'}, name='bus-minder'),

    # Convenience endpoints - Child
    path('child/<int:child_id>/bus/', ChildAssignmentsView.as_view(), {'query_type': 'bus'}, name='child-bus'),
    path('child/<int:child_id>/route/', ChildAssignmentsView.as_view(), {'query_type': 'route'}, name='child-route'),

    # Convenience endpoints - Parent
    path('parent/<int:parent_id>/children-buses/', ParentChildrenAssignmentsView.as_view(), name='parent-children-buses'),

    # Convenience endpoints - Minder
    path('minder/<int:minder_id>/buses/', MinderAssignmentsView.as_view(), name='minder-buses'),

    # Quick assignment endpoints
    path('quick/<str:assignment_type>/', QuickAssignView.as_view(), name='quick-assign'),
]
