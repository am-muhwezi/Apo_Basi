from django.urls import path
from .views import (
    ParentListCreateView,
    ParentDetailView,
    ParentRegistrationView,
    ParentLoginView,
    MyChildrenView,
    ChildAttendanceHistoryView,
)

urlpatterns = [
    # RESTful CRUD endpoints
    path("", ParentListCreateView.as_view(), name="parent-list-create"),
    path("<int:user_id>/", ParentDetailView.as_view(), name="parent-detail"),

    # Parent-specific endpoints
    path("register/", ParentRegistrationView.as_view(), name="parent-register"),
    path("login/", ParentLoginView.as_view(), name="parent-login"),
    path("my-children/", MyChildrenView.as_view(), name="my-children"),
    path("children/<int:child_id>/attendance/", ChildAttendanceHistoryView.as_view(), name="child-attendance-history"),
]
