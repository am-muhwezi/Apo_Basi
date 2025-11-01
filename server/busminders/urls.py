from django.urls import path
from .views import (
    BusMinderListCreateView,
    BusMinderDetailView,
    BusMinderRegistrationView,
    MyBusesView,
    BusChildrenView,
    MarkAttendanceView,
    busminder_phone_login,
)

urlpatterns = [
    # RESTful CRUD endpoints
    path("", BusMinderListCreateView.as_view(), name="busminder-list-create"),
    path("<int:user_id>/", BusMinderDetailView.as_view(), name="busminder-detail"),

    # Authentication
    path("phone-login/", busminder_phone_login, name="busminder-phone-login"),

    # BusMinder-specific endpoints
    path("register/", BusMinderRegistrationView.as_view(), name="bus-minder-register"),
    path("my-buses/", MyBusesView.as_view(), name="my-buses"),
    path("buses/<int:bus_id>/children/", BusChildrenView.as_view(), name="bus-children"),
    path("mark-attendance/", MarkAttendanceView.as_view(), name="mark-attendance"),
]
