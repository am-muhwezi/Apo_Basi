from django.urls import path
from .views import (
    ParentNotificationListView,
    mark_notification_read,
    mark_all_notifications_read,
    get_unread_count,
)

urlpatterns = [
    path('', ParentNotificationListView.as_view(), name='notification-list'),
    path('<int:notification_id>/mark-read/', mark_notification_read, name='notification-mark-read'),
    path('mark-all-read/', mark_all_notifications_read, name='notification-mark-all-read'),
    path('unread-count/', get_unread_count, name='notification-unread-count'),
]
