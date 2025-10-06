"""
Custom permission classes for role-based access control.

These permissions ensure that only users with the correct user_type
can access specific endpoints, providing security and proper separation
of concerns across the bus tracking app.

For a junior developer:
- Permissions are checked BEFORE a view is executed
- If permission check fails, Django returns 403 Forbidden
- You can combine multiple permission classes for stricter control
"""

from rest_framework import permissions


class IsParent(permissions.BasePermission):
    """
    Permission class to allow access only to users with user_type='parent'.

    Usage in views:
        permission_classes = [IsAuthenticated, IsParent]

    Parents should only access:
    - Their own children's data
    - Their children's attendance records
    - Bus locations for buses their children are assigned to
    """

    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.user_type == 'parent'


class IsDriver(permissions.BasePermission):
    """
    Permission class to allow access only to users with user_type='driver'.

    Usage in views:
        permission_classes = [IsAuthenticated, IsDriver]

    Drivers should access:
    - Their assigned bus information
    - Children assigned to their bus
    - Route information for their bus
    """

    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.user_type == 'driver'


class IsBusMinder(permissions.BasePermission):
    """
    Permission class to allow access only to users with user_type='busminder'.

    Usage in views:
        permission_classes = [IsAuthenticated, IsBusMinder]

    Bus minders should access:
    - Buses they are assigned to
    - Attendance marking for children on their buses
    - Child lists for their assigned buses
    """

    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.user_type == 'busminder'


class IsAdmin(permissions.BasePermission):
    """
    Permission class to allow access only to users with user_type='admin' or Django superusers.

    Usage in views:
        permission_classes = [IsAuthenticated, IsAdmin]

    Admins have full access to:
    - Create parents, drivers, bus minders
    - Assign drivers, bus minders, and children to buses
    - View all data across the system
    - Manage buses, routes, and system configuration
    """

    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and (
            request.user.user_type == 'admin' or request.user.is_superuser
        )
