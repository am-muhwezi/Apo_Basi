from django.contrib import admin
from .models import Trip, Stop


class StopInline(admin.TabularInline):
    model = Stop
    extra = 0
    fields = ['address', 'latitude', 'longitude', 'scheduled_time', 'actual_time', 'status', 'order']


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ['id', 'route', 'trip_type', 'status', 'bus', 'driver', 'scheduled_time', 'created_at']
    list_filter = ['status', 'trip_type', 'scheduled_time']
    search_fields = ['route', 'bus__bus_number', 'driver__first_name', 'driver__last_name']
    inlines = [StopInline]
    filter_horizontal = ['children']


@admin.register(Stop)
class StopAdmin(admin.ModelAdmin):
    list_display = ['id', 'address', 'trip', 'status', 'scheduled_time', 'actual_time', 'order']
    list_filter = ['status', 'trip__trip_type']
    search_fields = ['address', 'trip__route']
    filter_horizontal = ['children']
