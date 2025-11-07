"""
Bus ViewSet for managing bus CRUD operations and assignments.

This ViewSet consolidates all bus operations:
- CRUD operations (list, create, retrieve, update, delete)
- Driver assignment
- Minder assignment
- Children assignment

Architecture Benefits:
- Single ViewSet instead of multiple views
- Automatic URL routing via DRF router
- Built-in pagination (configured globally)
- Built-in authentication (JWT)
- Custom permissions for role-based access
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.contrib.auth import get_user_model

from .models import Bus
from .serializers import BusSerializer, BusCreateSerializer
from .permissions import IsAdminOrReadOnly, CanManageBusAssignments
from children.models import Child

User = get_user_model()


class BusViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Bus operations.

    Endpoints:
        GET    /api/buses/                          → list all buses (paginated)
        POST   /api/buses/                          → create new bus (admin only)
        GET    /api/buses/:id/                      → retrieve single bus
        PUT    /api/buses/:id/                      → full update (admin only)
        PATCH  /api/buses/:id/                      → partial update (admin only)
        DELETE /api/buses/:id/                      → delete bus (admin only)
        POST   /api/buses/:id/assign-driver/        → assign driver (admin only)
        POST   /api/buses/:id/assign-minder/        → assign minder (admin only)
        POST   /api/buses/:id/assign-children/      → assign children (admin only)
        GET    /api/buses/:id/children/             → get assigned children

    Permissions:
        - List/Retrieve: Authenticated users
        - Create/Update/Delete: Admin users only
        - Assignments: Admin users only

    Pagination:
        - Automatically paginated (PAGE_SIZE=20 from settings)
        - Returns: {count, next, previous, results}

    Example Response (GET /api/buses/):
        {
            "count": 50,
            "next": "http://localhost:8000/api/buses/?page=2",
            "previous": null,
            "results": [
                {
                    "id": 1,
                    "busNumber": "BUS-001",
                    "licensePlate": "ABC123",
                    ...
                }
            ]
        }
    """

    # Query optimization: Reduce database queries
    queryset = Bus.objects.select_related(
        'driver',
        'bus_minder'
    ).prefetch_related(
        'children'
    ).all()

    # Permissions
    permission_classes = [IsAdminOrReadOnly]

    # Pagination is handled globally via settings.py
    # No need to specify pagination_class here

    def get_serializer_class(self):
        """
        Use different serializers for read vs write operations.

        - Read (GET): BusSerializer (full details with camelCase)
        - Write (POST/PUT/PATCH): BusCreateSerializer (validation + field mapping)
        """
        if self.action in ['create', 'update', 'partial_update']:
            return BusCreateSerializer
        return BusSerializer

    def get_queryset(self):
        """
        Optionally filter queryset based on user role.

        Future enhancement: Drivers/Minders can only see their assigned buses
        """
        queryset = super().get_queryset()

        # Future: Add filtering logic based on user role
        # if self.request.user.user_type == 'driver':
        #     return queryset.filter(driver=self.request.user)

        return queryset

    # ============================================
    # Custom Actions for Bus Assignments
    # ============================================

    @action(
        detail=True,
        methods=['post'],
        permission_classes=[CanManageBusAssignments],
        url_path='assign-driver'
    )
    @transaction.atomic
    def assign_driver(self, request, pk=None):
        """
        Assign a driver to a bus.

        POST /api/buses/:id/assign-driver/
        Body: {"driver_id": 1}

        Returns:
            200: Driver assigned successfully
            400: Missing driver_id or invalid request
            404: Driver or Bus not found
        """
        bus = self.get_object()
        driver_id = request.data.get('driver_id')

        if not driver_id:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": "driver_id is required",
                        "field": "driver_id"
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            driver = User.objects.get(id=driver_id, user_type='driver')

            # Check if driver is already assigned to another bus
            existing_assignment = Bus.objects.filter(driver=driver).exclude(id=bus.id).first()
            if existing_assignment:
                return Response(
                    {
                        "success": False,
                        "error": {
                            "message": f"Driver {driver.get_full_name()} is already assigned to bus {existing_assignment.bus_number}",
                            "field": "driver_id"
                        }
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            bus.driver = driver
            bus.save()

            return Response(
                {
                    "success": True,
                    "message": f"Driver {driver.get_full_name()} assigned to bus {bus.bus_number}",
                    "bus": BusSerializer(bus).data
                },
                status=status.HTTP_200_OK
            )

        except User.DoesNotExist:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": "Driver not found with the provided ID",
                        "field": "driver_id"
                    }
                },
                status=status.HTTP_404_NOT_FOUND
            )

    @action(
        detail=True,
        methods=['post'],
        permission_classes=[CanManageBusAssignments],
        url_path='assign-minder'
    )
    @transaction.atomic
    def assign_minder(self, request, pk=None):
        """
        Assign a bus minder to a bus.

        POST /api/buses/:id/assign-minder/
        Body: {"minder_id": 1}

        Returns:
            200: Minder assigned successfully
            400: Missing minder_id or invalid request
            404: Minder or Bus not found
        """
        bus = self.get_object()
        minder_id = request.data.get('minder_id')

        if not minder_id:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": "minder_id is required",
                        "field": "minder_id"
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            minder = User.objects.get(id=minder_id, user_type='busminder')

            # Check if minder is already assigned to another bus
            existing_assignment = Bus.objects.filter(bus_minder=minder).exclude(id=bus.id).first()
            if existing_assignment:
                return Response(
                    {
                        "success": False,
                        "error": {
                            "message": f"Minder {minder.get_full_name()} is already assigned to bus {existing_assignment.bus_number}",
                            "field": "minder_id"
                        }
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            bus.bus_minder = minder
            bus.save()

            return Response(
                {
                    "success": True,
                    "message": f"Bus minder {minder.get_full_name()} assigned to bus {bus.bus_number}",
                    "bus": BusSerializer(bus).data
                },
                status=status.HTTP_200_OK
            )

        except User.DoesNotExist:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": "Bus minder not found with the provided ID",
                        "field": "minder_id"
                    }
                },
                status=status.HTTP_404_NOT_FOUND
            )

    @action(
        detail=True,
        methods=['post'],
        permission_classes=[CanManageBusAssignments],
        url_path='assign-children'
    )
    @transaction.atomic
    def assign_children(self, request, pk=None):
        """
        Bulk assign children to a bus.

        POST /api/buses/:id/assign-children/
        Body: {"children_ids": [1, 2, 3]}

        Business Logic:
            - Validates that children count doesn't exceed bus capacity
            - Updates all children in a single transaction
            - Unassigns children from previous buses

        Returns:
            200: Children assigned successfully
            400: Invalid request or capacity exceeded
            404: Bus not found
        """
        bus = self.get_object()
        children_ids = request.data.get('children_ids', [])

        if not isinstance(children_ids, list):
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": "children_ids must be an array",
                        "field": "children_ids"
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if not children_ids:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": "children_ids array cannot be empty",
                        "field": "children_ids"
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check bus capacity
        if len(children_ids) > bus.capacity:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": f"Cannot assign {len(children_ids)} children. Bus capacity is {bus.capacity}",
                        "field": "children_ids",
                        "capacity": bus.capacity,
                        "attempted": len(children_ids)
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Assign children to bus (atomic operation)
        children = Child.objects.filter(id__in=children_ids)
        actual_count = children.count()

        if actual_count != len(children_ids):
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": f"Only {actual_count} out of {len(children_ids)} children found",
                        "field": "children_ids"
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        children.update(assigned_bus=bus)

        return Response(
            {
                "success": True,
                "message": f"{actual_count} children assigned to bus {bus.bus_number}",
                "bus": BusSerializer(bus).data
            },
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
        Get all children assigned to a bus.

        GET /api/buses/:id/children/

        Returns detailed information about assigned children including:
        - Child details
        - Parent information
        - Capacity status

        Returns:
            200: Children data with capacity information
            404: Bus not found
        """
        bus = self.get_object()
        children = bus.children.select_related('parent', 'parent__user').all()

        children_data = [
            {
                "id": child.id,
                "firstName": child.first_name,
                "lastName": child.last_name,
                "grade": child.class_grade,
                "parentName": child.parent.user.get_full_name() if child.parent else None,
                "address": getattr(child, 'address', None),
            }
            for child in children
        ]

        return Response(
            {
                "success": True,
                "busId": bus.id,
                "busNumber": bus.bus_number,
                "capacity": bus.capacity,
                "assignedCount": len(children_data),
                "availableCapacity": bus.capacity - len(children_data),
                "children": children_data
            },
            status=status.HTTP_200_OK
        )
