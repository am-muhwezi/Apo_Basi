from django.urls import path
from .views import (
    TripListCreateView,
    TripDetailView,
    TripStartView,
    TripCompleteView,
    TripCancelView,
    TripUpdateLocationView,
    StopListCreateView,
    StopDetailView,
    StopCompleteView,
    StopSkipView,
)

urlpatterns = [
    # Trip CRUD endpoints
    path("", TripListCreateView.as_view(), name="trip-list-create"),
    path("<int:pk>/", TripDetailView.as_view(), name="trip-detail"),

    # Trip action endpoints
    path("<int:pk>/start/", TripStartView.as_view(), name="trip-start"),
    path("<int:pk>/complete/", TripCompleteView.as_view(), name="trip-complete"),
    path("<int:pk>/cancel/", TripCancelView.as_view(), name="trip-cancel"),
    path("<int:pk>/update-location/", TripUpdateLocationView.as_view(), name="trip-update-location"),

    # Stop endpoints for a specific trip
    path("<int:trip_id>/stops/", StopListCreateView.as_view(), name="trip-stops"),

    # Stop CRUD endpoints
    path("stops/<int:pk>/", StopDetailView.as_view(), name="stop-detail"),
    path("stops/<int:pk>/complete/", StopCompleteView.as_view(), name="stop-complete"),
    path("stops/<int:pk>/skip/", StopSkipView.as_view(), name="stop-skip"),
]
