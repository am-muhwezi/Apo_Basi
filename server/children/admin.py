from django.contrib import admin
from .models import Child


@admin.register(Child)
class ChildAdmin(admin.ModelAdmin):
    list_display = ('first_name', 'last_name', 'parent', 'age', 'class_grade', 'assigned_bus', 'status')
    list_filter = ('status', 'class_grade')
    search_fields = ('first_name', 'last_name', 'parent__user__username')
    list_select_related = ('parent', 'assigned_bus')
    fieldsets = (
        ('Child Information', {
            'fields': ('first_name', 'last_name', 'age')
        }),
        ('School Information', {
            'fields': ('class_grade', 'assigned_bus')
        }),
        ('Parent Information', {
            'fields': ('parent',)
        }),
        ('Status', {
            'fields': ('status',)
        }),
    )
