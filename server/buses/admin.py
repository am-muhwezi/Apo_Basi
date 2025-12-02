from django.contrib import admin
from .models import Bus, BusLocationHistory


@admin.register(Bus)
class BusAdmin(admin.ModelAdmin):
    list_display = ['bus_number', 'number_plate', 'capacity', 'is_active', 'last_updated']
    list_filter = ['is_active']
    search_fields = ['bus_number', 'number_plate']


@admin.register(BusLocationHistory)
class BusLocationHistoryAdmin(admin.ModelAdmin):
    list_display = ['bus', 'latitude', 'longitude', 'speed', 'timestamp']
    list_filter = ['bus', 'is_active', 'timestamp']
    readonly_fields = ['timestamp']
    date_hierarchy = 'timestamp'
