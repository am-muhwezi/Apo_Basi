from django.urls import path
from .views import (
    admin_register,
    AdminListCreateView,
    AdminDetailView,
    AdminAddParentView,
    AdminAddDriverView,
    AdminAddBusminderView,
    AdminAssignDriverToBusView,
    AdminAssignBusMinderToBusView,
    AdminAssignChildToBusView,
)
from users.serializers import UserRegistrationSerializer

urlpatterns = [
    # Admin registration
    path("register/", admin_register, name="admin-register"),

    # Admin CRUD endpoints
    path("", AdminListCreateView.as_view(), name="admin-list-create"),
    path("<int:user_id>/", AdminDetailView.as_view(), name="admin-detail"),

    # Admin action endpoints
    path(
        "add-parent/",
        AdminAddParentView.as_view(serializer_class=UserRegistrationSerializer),
        name="admin-add-parent",
    ),
    path(
        "add-driver/",
        AdminAddDriverView.as_view(serializer_class=UserRegistrationSerializer),
        name="admin-add-driver",
    ),
    path(
        "add-busminder/",
        AdminAddBusminderView.as_view(serializer_class=UserRegistrationSerializer),
        name="admin-add-busminder",
    ),
    # Assignment endpoints (kept in admins for workflow orchestration)
    path(
        "assign-driver-to-bus/",
        AdminAssignDriverToBusView.as_view(),
        name="admin-assign-driver-to-bus",
    ),
    path(
        "assign-busminder-to-bus/",
        AdminAssignBusMinderToBusView.as_view(),
        name="admin-assign-busminder-to-bus",
    ),
    path(
        "assign-child-to-bus/",
        AdminAssignChildToBusView.as_view(),
        name="admin-assign-child-to-bus",
    ),
]
