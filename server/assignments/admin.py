from django.contrib import admin
from .models import Assignment, BusRoute, AssignmentHistory


@admin.register(BusRoute)
class BusRouteAdmin(admin.ModelAdmin):
    list_display = ['route_code', 'name', 'default_bus', 'default_driver', 'default_minder', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['route_code', 'name', 'description']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'route_code', 'description', 'is_active')
        }),
        ('Default Assignments', {
            'fields': ('default_bus', 'default_driver', 'default_minder')
        }),
        ('Route Details', {
            'fields': ('schedule', 'estimated_duration', 'total_distance')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(Assignment)
class AssignmentAdmin(admin.ModelAdmin):
    list_display = [
        'id', 'assignment_type', 'get_assignee_name', 'get_assigned_to_name',
        'effective_date', 'expiry_date', 'status', 'assigned_at'
    ]
    list_filter = ['assignment_type', 'status', 'effective_date', 'assigned_at']
    search_fields = ['reason', 'notes']
    readonly_fields = ['assigned_at', 'updated_at', 'assignee_content_type', 'assignee_object_id',
                       'assigned_to_content_type', 'assigned_to_object_id']
    date_hierarchy = 'assigned_at'

    fieldsets = (
        ('Assignment Type', {
            'fields': ('assignment_type', 'status')
        }),
        ('Assignee (Who)', {
            'fields': ('assignee_content_type', 'assignee_object_id'),
            'classes': ('collapse',)
        }),
        ('Assigned To (What)', {
            'fields': ('assigned_to_content_type', 'assigned_to_object_id'),
            'classes': ('collapse',)
        }),
        ('Time Period', {
            'fields': ('effective_date', 'expiry_date')
        }),
        ('Audit Trail', {
            'fields': ('assigned_by', 'assigned_at', 'updated_at')
        }),
        ('Additional Information', {
            'fields': ('reason', 'notes', 'metadata'),
            'classes': ('collapse',)
        }),
    )

    def get_assignee_name(self, obj):
        try:
            return str(obj.assignee)
        except:
            return "N/A"
    get_assignee_name.short_description = 'Assignee'

    def get_assigned_to_name(self, obj):
        try:
            return str(obj.assigned_to)
        except:
            return "N/A"
    get_assigned_to_name.short_description = 'Assigned To'


@admin.register(AssignmentHistory)
class AssignmentHistoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'assignment', 'action', 'performed_by', 'performed_at']
    list_filter = ['action', 'performed_at']
    search_fields = ['notes', 'changes']
    readonly_fields = ['assignment', 'action', 'performed_by', 'performed_at', 'changes', 'notes']
    date_hierarchy = 'performed_at'

    def has_add_permission(self, request):
        # History entries should only be created automatically
        return False

    def has_delete_permission(self, request, obj=None):
        # Prevent deletion of audit trail
        return False
