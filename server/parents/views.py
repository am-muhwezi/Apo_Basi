"""Parent views for CRUD and phone-based login flows."""

import logging

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model
from django.db import transaction

from .models import Parent
from .serializers import ParentLoginSerializer, ParentSerializer, ParentCreateSerializer
from children.models import Child
from attendance.models import Attendance
from users.permissions import IsParent
from assignments.models import Assignment
from datetime import date

User = get_user_model()
logger = logging.getLogger(__name__)


class ParentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Parent operations.

    Endpoints:
        GET    /api/parents/                    → list all parents (paginated)
        POST   /api/parents/                    → create new parent
        GET    /api/parents/:id/                → retrieve single parent
        PUT    /api/parents/:id/                → full update
        PATCH  /api/parents/:id/                → partial update
        DELETE /api/parents/:id/                → delete parent
        GET    /api/parents/:id/children/       → get parent's children

    Permissions:
        - List/Retrieve: Authenticated users
        - Create/Update/Delete: Admin users only

    Pagination:
        - Automatically paginated (PAGE_SIZE=20 from settings)
        - Returns: {count, next, previous, results}
    """

    queryset = Parent.objects.select_related('user').all()
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        """
        Use different serializers for read vs write operations.

        - Read (GET): ParentSerializer (full details with camelCase)
        - Write (POST/PUT/PATCH): ParentCreateSerializer (validation + field mapping)
        """
        if self.action in ['create', 'update', 'partial_update']:
            return ParentCreateSerializer
        return ParentSerializer

    def destroy(self, request, *args, **kwargs):
        """
        Enhanced delete with children warning and options.

        DELETE /api/parents/{id}/
            - Returns 400 if children exist, requiring explicit action

        DELETE /api/parents/{id}/?action=keep_children
            - Deletes parent only, children will have no parent (SET_NULL)

        DELETE /api/parents/{id}/?action=delete_children
            - Deletes parent AND all their children (CASCADE)

        Returns:
            400: If children exist and no action specified
            204: On successful deletion
        """
        parent = self.get_object()

        # Check if parent has children
        children = Child.objects.filter(parent=parent)
        children_count = children.count()

        if children_count > 0:
            # Check deletion action
            action = request.query_params.get('action', '')

            if action not in ['keep_children', 'delete_children']:
                # Return error with children info for frontend to show options
                return Response(
                    {
                        "error": "Parent has children",
                        "message": f"This parent has {children_count} child(ren). Please choose what to do with the children.",
                        "childrenCount": children_count,
                        "children": [{
                            "id": child.id,
                            "firstName": child.first_name,
                            "lastName": child.last_name,
                            "grade": child.class_grade
                        } for child in children],
                        "requiresConfirmation": True
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            if action == 'delete_children':
                # Delete children first, then parent
                with transaction.atomic():
                    children.delete()
                    parent.delete()
                return Response(
                    {
                        "message": f"Parent and {children_count} child(ren) deleted successfully"
                    },
                    status=status.HTTP_200_OK
                )

            if action == 'keep_children':
                # Delete parent only, children will have parent set to NULL
                parent.delete()
                return Response(
                    {
                        "message": f"Parent deleted. {children_count} child(ren) now have no parent assigned."
                    },
                    status=status.HTTP_200_OK
                )

        # No children, delete normally
        parent.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(
        detail=False,
        methods=['get'],
        permission_classes=[IsAuthenticated],
        url_path='search'
    )
    def search(self, request):
        """
        Search for parents by name, email, or phone.

        GET /api/parents/search/?q=john

        Query Parameters:
            q (str): Search query to filter parents
            limit (int): Maximum results to return (default: 10, max: 50)

        Returns:
            200: List of matching parents with basic info
        """
        query = request.query_params.get('q', '').strip()
        limit = min(int(request.query_params.get('limit', 10)), 50)

        if not query:
            return Response(
                {"results": []},
                status=status.HTTP_200_OK
            )

        # Search by first name, last name, email, or phone
        parents = Parent.objects.filter(
            user__first_name__icontains=query
        ) | Parent.objects.filter(
            user__last_name__icontains=query
        ) | Parent.objects.filter(
            user__email__icontains=query
        ) | Parent.objects.filter(
            contact_number__icontains=query
        )

        parents = parents.select_related('user').distinct()[:limit]

        results = [{
            "id": parent.user.id,
            "firstName": parent.user.first_name,
            "lastName": parent.user.last_name,
            "email": parent.user.email,
            "phone": parent.contact_number,
        } for parent in parents]

        return Response(
            {"results": results},
            status=status.HTTP_200_OK
        )

    @action(
        detail=True,
        methods=['get'],
        permission_classes=[IsAuthenticated],
        url_path='children'
    )
    def children(self, request, pk=None):
        """
        Get all children for a specific parent.

        GET /api/parents/:id/children/

        Returns detailed information about parent's children including:
        - Child details
        - Bus assignment information
        - Status

        Returns:
            200: Children data
            404: Parent not found
        """
        parent = self.get_object()

        # Get all children for this parent
        children = Child.objects.filter(parent=parent)

        # Build children data with bus assignments
        children_data = []
        for child in children:
            # Get child's bus assignment using Assignment API
            bus_assignment = Assignment.get_active_assignments_for(child, 'child_to_bus').first()

            child_data = {
                "id": child.id,
                "firstName": child.first_name,
                "lastName": child.last_name,
                "grade": child.class_grade,
                "age": getattr(child, 'age', None),
                "status": child.status,
                "assignedBus": None
            }

            if bus_assignment:
                bus = bus_assignment.assigned_to
                child_data["assignedBus"] = {
                    "id": bus.id,
                    "busNumber": bus.bus_number,
                    "licensePlate": bus.number_plate,
                }

            children_data.append(child_data)

        return Response(
            {
                "success": True,
                "parent": {
                    "id": parent.user.id,
                    "firstName": parent.user.first_name,
                    "lastName": parent.user.last_name,
                },
                "children": children_data,
                "totalChildren": len(children_data)
            },
            status=status.HTTP_200_OK
        )


class ParentLoginView(APIView):
    """
    POST /api/parents/login/
    Authenticate parent using phone number only.
    School creates parent accounts, so parents just login.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ParentLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        phone_number = serializer.validated_data['phone_number']

        try:
            parent = Parent.objects.select_related('user').get(
                contact_number=phone_number,
                status='active'
            )
        except Parent.DoesNotExist:
            return Response(
                {"error": "No active parent account found with this phone number"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Generate JWT tokens
        try:
            # Generate JWT tokens
            refresh = RefreshToken.for_user(parent.user)

            # Get parent's children
            children = Child.objects.filter(parent=parent)

            # Build children data with bus assignments from Assignment API
            children_data = []
            for child in children:
                # Get child's bus assignment using Assignment API
                bus_assignment = Assignment.get_active_assignments_for(child, 'child_to_bus').first()

                child_data = {
                    "id": child.id,
                    "first_name": child.first_name,
                    "last_name": child.last_name,
                    "class_grade": child.class_grade,
                    "status": child.status,
                    "assigned_bus": None
                }

                if bus_assignment:
                    bus = bus_assignment.assigned_to
                    # Get driver and minder for the bus
                    driver_assignment = Assignment.get_assignments_to(bus, 'driver_to_bus').first()
                    minder_assignment = Assignment.get_assignments_to(bus, 'minder_to_bus').first()

                    # Safely build driver info
                    driver_info = None
                    if driver_assignment and driver_assignment.assignee:
                        driver_info = {
                            "name": f"{driver_assignment.assignee.user.first_name} {driver_assignment.assignee.user.last_name}",
                            "phone": driver_assignment.assignee.phone_number
                        }

                    # Safely build minder info
                    minder_info = None
                    if minder_assignment and minder_assignment.assignee:
                        minder_info = {
                            "name": f"{minder_assignment.assignee.user.first_name} {minder_assignment.assignee.user.last_name}",
                            "phone": minder_assignment.assignee.phone_number
                        }

                    child_data["assigned_bus"] = {
                        "id": bus.id,
                        "bus_number": bus.bus_number,
                        "number_plate": bus.number_plate,
                        "driver": driver_info,
                        "minder": minder_info
                    }

                children_data.append(child_data)

            return Response(
                {
                    "success": True,
                    "parent": {
                        "id": parent.user.id,
                        "firstName": parent.user.first_name,
                        "lastName": parent.user.last_name,
                    },
                    "children": children_data,
                    "totalChildren": len(children_data),
                    "tokens": {
                        "access": str(refresh.access_token),
                        "refresh": str(refresh),
                    },
                },
                status=status.HTTP_200_OK
            )
        except Exception:
            # Log full traceback server-side but return a safe, structured
            # error payload to the mobile apps so they don't crash.
            logger.exception("Unexpected error during parent phone login", extra={"phone_number": phone_number})
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": "Something went wrong while logging you in. Please try again.",
                        "code": "parent_login_error",
                    },
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class ChildAttendanceHistoryView(APIView):
    """
    GET /api/parents/children/<child_id>/attendance/
    Returns attendance history for a specific child.
    Parents can only view their own children's attendance.
    """
    permission_classes = [IsAuthenticated, IsParent]

    def get(self, request, child_id):
        try:
            parent = Parent.objects.get(user=request.user)
        except Parent.DoesNotExist:
            return Response(
                {"error": "Parent profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Verify child belongs to this parent
        child = get_object_or_404(Child, id=child_id)
        if child.parent != parent:
            return Response(
                {"error": "You can only view attendance for your own children"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get attendance records
        attendance_records = Attendance.objects.filter(
            child=child
        ).select_related('bus', 'marked_by').order_by('-date')

        attendance_data = [{
            "id": record.id,
            "date": record.date,
            "status": record.get_status_display(),
            "bus": {
                "id": record.bus.id,
                "number_plate": record.bus.number_plate
            } if record.bus else None,
            "marked_by": record.marked_by.get_full_name() if record.marked_by else None,
            "timestamp": record.timestamp,
            "notes": record.notes
        } for record in attendance_records]

        return Response({
            "child": {
                "id": child.id,
                "name": f"{child.first_name} {child.last_name}",
                "class_grade": child.class_grade
            },
            "attendance_history": attendance_data,
            "total_records": len(attendance_data)
        }, status=status.HTTP_200_OK)
