"""
Parent ViewSet for managing parent CRUD operations.

This ViewSet consolidates all parent operations:
- CRUD operations (list, create, retrieve, update, delete)
- Child relationship queries

Architecture Benefits:
- Single ViewSet instead of multiple views
- Automatic URL routing via DRF router
- Built-in pagination (configured globally)
- Built-in authentication (JWT)
"""

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

                child_data["assigned_bus"] = {
                    "id": bus.id,
                    "bus_number": bus.bus_number,
                    "number_plate": bus.number_plate,
                    "driver": {
                        "name": f"{driver_assignment.assignee.user.first_name} {driver_assignment.assignee.user.last_name}",
                        "phone": driver_assignment.assignee.user.phone_number
                    } if driver_assignment else None,
                    "minder": {
                        "name": f"{minder_assignment.assignee.user.first_name} {minder_assignment.assignee.user.last_name}",
                        "phone": minder_assignment.assignee.phone_number
                    } if minder_assignment else None
                }

            children_data.append(child_data)

        return Response({
            "message": "Login successful",
            "tokens": {
                "refresh": str(refresh),
                "access": str(refresh.access_token)
            },
            "parent": {
                "id": parent.user.id,
                "first_name": parent.user.first_name,
                "last_name": parent.user.last_name,
                "email": parent.user.email,
                "phone": parent.contact_number,
            },
            "children": children_data
        }, status=status.HTTP_200_OK)


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
