from django.urls import path
from .views import ParentListView

urlpatterns = [
    path("", ParentListView.as_view(), name="parent-list"),
]
