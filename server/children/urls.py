from django.urls import path
from .views import ChildListCreateView, ChildDetailView

urlpatterns = [
    path("", ChildListCreateView.as_view(), name="child-list-create"),
    path("<int:pk>/", ChildDetailView.as_view(), name="child-detail"),
]
