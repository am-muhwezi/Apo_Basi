from django.urls import path
from .views import (
    ParentListCreateView,
    ParentDetailView,
    ParentRegistrationView,
    ParentLoginView,
    ParentDirectPhoneLoginView,
    MyChildrenView,
    ChildAttendanceHistoryView,
    ParentAssignChildrenView,
    ParentChildrenView,
)

urlpatterns = [
    # RESTful CRUD endpoints
    path("", ParentListCreateView.as_view(), name="parent-list-create"),
    path("<int:user_id>/", ParentDetailView.as_view(), name="parent-detail"),

    # Assignment endpoints
    path("<int:user_id>/assign-children/", ParentAssignChildrenView.as_view(), name="parent-assign-children"),
    path("<int:user_id>/children/", ParentChildrenView.as_view(), name="parent-children"),

    # Parent-specific endpoints
    path("register/", ParentRegistrationView.as_view(), name="parent-register"),
    path("login/", ParentLoginView.as_view(), name="parent-login"),
    path("direct-phone-login/", ParentDirectPhoneLoginView.as_view(), name="parent-direct-phone-login"),
    path("my-children/", MyChildrenView.as_view(), name="my-children"),
    path("children/<int:child_id>/attendance/", ChildAttendanceHistoryView.as_view(), name="child-attendance-history"),
]
