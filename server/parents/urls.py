"""
Parent URL Configuration using DRF Router.

DRF Router automatically generates URL patterns for ViewSets.

Generated URLs:
    GET    /api/parents/                          → list
    POST   /api/parents/                          → create
    GET    /api/parents/:id/                      → retrieve
    PUT    /api/parents/:id/                      → update
    PATCH  /api/parents/:id/                      → partial_update
    DELETE /api/parents/:id/                      → destroy
    GET    /api/parents/:id/children/             → custom action

Additional endpoints (non-ViewSet):
    POST   /api/parents/login/                    → parent login
    GET    /api/parents/children/<id>/attendance/ → child attendance history
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ParentViewSet,
    ParentLoginView,
    ChildAttendanceHistoryView
)

# Create a router and register the ParentViewSet
router = DefaultRouter()
router.register(r'', ParentViewSet, basename='parent')

urlpatterns = [
    # Authentication - must come before router to avoid conflicts
    path('login/', ParentLoginView.as_view(), name='parent-login'),
    path('children/<int:child_id>/attendance/', ChildAttendanceHistoryView.as_view(), name='child-attendance-history'),

    # Include router URLs
    path('', include(router.urls)),
]
