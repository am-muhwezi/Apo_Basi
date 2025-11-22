from django.urls import path
from . import views

urlpatterns = [
    path('', views.analytics_overview, name='analytics-overview'),
    path('metrics/', views.key_metrics, name='analytics-metrics'),
    path('trips/', views.trip_analytics, name='analytics-trips'),
    path('buses/', views.bus_performance, name='analytics-buses'),
    path('attendance/', views.attendance_stats, name='analytics-attendance'),
    path('routes/', views.route_efficiency, name='analytics-routes'),
    path('safety/', views.safety_alerts, name='analytics-safety'),
]
