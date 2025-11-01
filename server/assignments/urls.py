from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AssignmentViewSet, BusRouteViewSet, AssignmentHistoryViewSet

# Create router and register viewsets
router = DefaultRouter()
router.register(r'routes', BusRouteViewSet, basename='busroute')
router.register(r'history', AssignmentHistoryViewSet, basename='assignment-history')
router.register(r'list', AssignmentViewSet, basename='assignment')

urlpatterns = [
    path('', include(router.urls)),
]
