from django.contrib import admin
from .models import Parent


@admin.register(Parent)
class ParentAdmin(admin.ModelAdmin):
    list_display = ('user', 'contact_number', 'status')
    list_filter = ('status',)
    search_fields = ('user__username', 'user__email', 'contact_number')
    fieldsets = (
        ('User Information', {
            'fields': ('user',)
        }),
        ('Contact Information', {
            'fields': ('contact_number', 'address', 'emergency_contact')
        }),
        ('Status', {
            'fields': ('status',)
        }),
    )
