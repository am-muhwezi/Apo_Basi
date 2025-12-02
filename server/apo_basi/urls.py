from django.contrib import admin
from django.urls import path
from django.urls import include
from users.views import health_check

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/users/", include("users.urls")),
    path("api/buses/", include("buses.urls")),
    path("api/children/", include("children.urls")),
    path("api/parents/", include("parents.urls")),
    path("api/drivers/", include("drivers.urls")),
    path("api/busminders/", include("busminders.urls")),
    path("api/admins/", include("admins.urls")),
    path("api/trips/", include("trips.urls")),
    path("api/assignments/", include("assignments.urls")),
    path("api/attendance/", include("attendance.urls")),
    path("api/analytics/", include("analytics.urls")),
    path("api/notifications/", include("notifications.urls")),
    path("api/health/", health_check, name="health_check"),  # Health check endpoint
]
