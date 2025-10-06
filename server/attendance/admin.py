from django.contrib import admin
from .models import Attendance


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ['child', 'bus', 'status', 'date', 'marked_by', 'timestamp']
    list_filter = ['status', 'date', 'bus']
    search_fields = ['child__first_name', 'child__last_name']
    readonly_fields = ['date', 'timestamp']
