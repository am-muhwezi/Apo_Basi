from django.urls import path
from .views import (
    DriverListCreateView,
    DriverDetailView,
    MyBusView,
    MyRouteView,
    driver_phone_login
)

urlpatterns = [
    # RESTful CRUD endpoints
    path("", DriverListCreateView.as_view(), name="driver-list-create"),
    path("<int:user_id>/", DriverDetailView.as_view(), name="driver-detail"),

    # Authentication
    path("phone-login/", driver_phone_login, name="driver-phone-login"),

    # Driver-specific endpoints
    path("my-bus/", MyBusView.as_view(), name="my-bus"),
    path("my-route/", MyRouteView.as_view(), name="my-route"),
]
