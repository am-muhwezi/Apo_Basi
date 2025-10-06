from django.urls import path
from .views import (
    BusListCreateView,
    BusDetailView,
    BusAssignDriverView,
    BusAssignMinderView,
    BusAssignChildrenView,
    BusChildrenView,
    BusListView,  # Legacy
)

urlpatterns = [
    # Main CRUD endpoints
    path("", BusListCreateView.as_view(), name="bus-list-create"),
    path("<int:pk>/", BusDetailView.as_view(), name="bus-detail"),

    # Assignment endpoints
    path("<int:pk>/assign-driver/", BusAssignDriverView.as_view(), name="bus-assign-driver"),
    path("<int:pk>/assign-minder/", BusAssignMinderView.as_view(), name="bus-assign-minder"),
    path("<int:pk>/assign-children/", BusAssignChildrenView.as_view(), name="bus-assign-children"),

    # Children management
    path("<int:pk>/children/", BusChildrenView.as_view(), name="bus-children"),

    # Legacy endpoint (kept for backward compatibility)
    path("legacy/", BusListView.as_view(), name="bus-list-legacy"),
]
