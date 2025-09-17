from django.urls import path
from .views import BusMinderListView

urlpatterns = [
    path("", BusMinderListView.as_view(), name="bus-minder-list"),
]
