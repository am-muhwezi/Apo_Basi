from django.urls import path
from .views import (
    ParentNotificationsView,
    MarkNotificationsAsReadView,
    NotificationDetailView,
)

urlpatterns = [
    path('', ParentNotificationsView.as_view(), name='parent-notifications'),
    path('mark-as-read/', MarkNotificationsAsReadView.as_view(), name='mark-notifications-read'),
    path('<int:notification_id>/', NotificationDetailView.as_view(), name='notification-detail'),
]
