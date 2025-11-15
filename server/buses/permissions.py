"""
Custom permissions for bus operations.

These permissions ensure that:
- Authenticated users can view buses
- Only admins can create, update, or delete buses
- Drivers and bus minders can only view their assigned buses
"""

from rest_framework import permissions


class IsAdminOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow admins to edit buses.
    Other authenticated users can only view.

    Usage:
        class BusViewSet(viewsets.ModelViewSet):
            permission_classes = [IsAdminOrReadOnly]
    """

    def has_permission(self, request, view):
        # Ensure user is authenticated
        if not request.user or not request.user.is_authenticated:
            return False

        # Read permissions are allowed for any authenticated user
        if request.method in permissions.SAFE_METHODS:  # GET, HEAD, OPTIONS
            return True

        # Write permissions only for admins
        return hasattr(request.user, 'user_type') and request.user.user_type == 'admin'


class IsAdminUser(permissions.BasePermission):
    """
    Custom permission to only allow admin users.

    Usage:
        class SensitiveView(APIView):
            permission_classes = [IsAdminUser]
    """

    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            hasattr(request.user, 'user_type') and
            request.user.user_type == 'admin'
        )


class CanManageBusAssignments(permissions.BasePermission):
    """
    Custom permission for bus assignments.
    Only admins can assign drivers, minders, or children to buses.
    """

    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            hasattr(request.user, 'user_type') and
            request.user.user_type == 'admin'
        )


class IsOwnerOrAdmin(permissions.BasePermission):
    """
    Object-level permission to only allow owners or admins to edit.

    For buses: Drivers can view their assigned bus, but only admins can edit.
    """

    def has_object_permission(self, request, view, obj):
        # Read permissions for authenticated users
        if request.method in permissions.SAFE_METHODS:
            # Admins can view all
            if hasattr(request.user, 'user_type') and request.user.user_type == 'admin':
                return True

            # Drivers can view their assigned bus
            if hasattr(obj, 'driver') and obj.driver == request.user:
                return True

            # Bus minders can view their assigned bus
            if hasattr(obj, 'bus_minder') and obj.bus_minder == request.user:
                return True

            return False

        # Write permissions only for admins
        return hasattr(request.user, 'user_type') and request.user.user_type == 'admin'
