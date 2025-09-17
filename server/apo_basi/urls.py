from django.contrib import admin
from django.urls import path
from django.urls import include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/buses/", include("buses.urls")),
    path("api/parents/", include("parents.urls")),
    path("api/busminders/", include("busminders.urls")),
]
