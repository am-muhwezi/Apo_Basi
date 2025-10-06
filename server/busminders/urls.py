from django.urls import path
from .views import (
    BusMinderListCreateView,
    BusMinderDetailView,
    BusMinderRegistrationView,
    MyBusesView,
    BusChildrenView,
    MarkAttendanceView,
)

urlpatterns = [
    # RESTful CRUD endpoints
    path("", BusMinderListCreateView.as_view(), name="busminder-list-create"),
    path("<int:user_id>/", BusMinderDetailView.as_view(), name="busminder-detail"),

    # BusMinder-specific endpoints
    path("register/", BusMinderRegistrationView.as_view(), name="bus-minder-register"),
    path("my-buses/", MyBusesView.as_view(), name="my-buses"),
    path("buses/<int:bus_id>/children/", BusChildrenView.as_view(), name="bus-children"),
    path("mark-attendance/", MarkAttendanceView.as_view(), name="mark-attendance"),
]
