from django.urls import path
from .views import (
    DriverListCreateView,
    DriverDetailView,
    MyBusView,
    MyRouteView,
    driver_phone_login,
    check_driver_email,
    driver_magic_link_auth,
    start_trip,
    end_trip,
    get_active_trip
)

urlpatterns = [
    # RESTful CRUD endpoints
    path("", DriverListCreateView.as_view(), name="driver-list-create"),
    path("<int:user_id>/", DriverDetailView.as_view(), name="driver-detail"),

    # Authentication
    path("phone-login/", driver_phone_login, name="driver-phone-login"),
    path("auth/check-email/", check_driver_email, name="check-driver-email"),
    path("auth/magic-link/", driver_magic_link_auth, name="driver-magic-link-auth"),

    # Driver-specific endpoints
    path("my-bus/", MyBusView.as_view(), name="my-bus"),
    path("my-route/", MyRouteView.as_view(), name="my-route"),

    # Trip management
    path("start-trip/", start_trip, name="start-trip"),
    path("end-trip/<int:trip_id>/", end_trip, name="end-trip"),
    path("active-trip/", get_active_trip, name="active-trip"),
]
