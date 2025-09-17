from .views import BusListView
from django.urls import path

urlpatterns = [
    path("", BusListView.as_view(), name="bus-list"),
]
