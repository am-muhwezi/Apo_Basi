from django.contrib import admin
from django.urls import path
from django.urls import include
from users.views import health_check, school_info
from users.views_auth import unified_phone_login
from rest_framework_simplejwt.views import TokenRefreshView
from trips.views import StopDetailView, StopCompleteView, StopSkipView

urlpatterns = [
    path("admin/", admin.site.urls),
    # Backwards-compatible alias for JWT refresh token endpoint
    # Primary endpoint lives at /api/users/token/refresh/
    path("api/token/refresh/", TokenRefreshView.as_view(), name="token_refresh_compat"),
    # Unified phone login for drivers and bus minders
    path("api/auth/phone-login/", unified_phone_login, name="unified_phone_login"),
    path("api/users/", include("users.urls")),
    path("api/buses/", include("buses.urls")),
    path("api/children/", include("children.urls")),
    path("api/parents/", include("parents.urls")),
    path("api/drivers/", include("drivers.urls")),
    path("api/busminders/", include("busminders.urls")),
    path("api/admins/", include("admins.urls")),
    path("api/trips/", include("trips.urls")),
    # Expose stop detail/actions at top-level paths for compatibility
    path("api/stops/<int:pk>/", StopDetailView.as_view()),
    path("api/stops/<int:pk>/complete/", StopCompleteView.as_view()),
    path("api/stops/<int:pk>/skip/", StopSkipView.as_view()),
    path("api/assignments/", include("assignments.urls")),
    path("api/attendance/", include("attendance.urls")),
    path("api/analytics/", include("analytics.urls")),
    path("api/notifications/", include("notifications.urls")),
    path("api/health/", health_check, name="health_check"),
    path("api/school/info/", school_info, name="school_info"),
]
