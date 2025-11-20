from django.urls import path
from .views import (
    AttendanceListView,
    AttendanceDetailView,
    AttendanceStatsView,
    DailyAttendanceReportView,
)

urlpatterns = [
    path("", AttendanceListView.as_view(), name="attendance-list"),
    path("<int:pk>/", AttendanceDetailView.as_view(), name="attendance-detail"),
    path("stats/", AttendanceStatsView.as_view(), name="attendance-stats"),
    path("daily-report/", DailyAttendanceReportView.as_view(), name="attendance-daily-report"),
]
