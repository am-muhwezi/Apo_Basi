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
from django.http import StreamingHttpResponse
from django.views.decorators.cache import never_cache
from django.utils.decorators import method_decorator
import json
import time

from .models import Bus
from .serializers import BusSerializer, BusCreateSerializer
from .permissions import IsAdminOrReadOnly, CanManageBusAssignments
from children.models import Child
from assignments.models import Assignment
from drivers.models import Driver
from busminders.models import BusMinder

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
    # Note: Assignments are now handled via Assignment model, not direct ForeignKeys
    queryset = Bus.objects.all()

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
        Assign a driver to a bus using Assignment API.

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
            # Get Driver instance (not User)
            driver = Driver.objects.select_related('user').get(user_id=driver_id)

            # Use Assignment API to create assignment
            from assignments.services import AssignmentService
            assignment = AssignmentService.create_assignment(
                assignment_type='driver_to_bus',
                assignee=driver,
                assigned_to=bus,
                assigned_by=request.user,
                reason=f"Assigned via bus management",
                auto_cancel_conflicting=True  # Auto-cancel existing assignments
            )

            return Response(
                {
                    "success": True,
                    "message": f"Driver {driver.user.get_full_name()} assigned to bus {bus.bus_number}",
                    "bus": BusSerializer(bus).data,
                    "assignment_id": assignment.id
                },
                status=status.HTTP_200_OK
            )

        except Driver.DoesNotExist:
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
        except Exception as e:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": str(e),
                        "field": "driver_id"
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
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
        Assign a bus minder to a bus using Assignment API.

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
            # Get BusMinder instance (not User)
            busminder = BusMinder.objects.select_related('user').get(user_id=minder_id)

            # Use Assignment API to create assignment
            from assignments.services import AssignmentService
            assignment = AssignmentService.create_assignment(
                assignment_type='minder_to_bus',
                assignee=busminder,
                assigned_to=bus,
                assigned_by=request.user,
                reason=f"Assigned via bus management",
                auto_cancel_conflicting=True  # Auto-cancel existing assignments
            )

            return Response(
                {
                    "success": True,
                    "message": f"Bus minder {busminder.user.get_full_name()} assigned to bus {bus.bus_number}",
                    "bus": BusSerializer(bus).data,
                    "assignment_id": assignment.id
                },
                status=status.HTTP_200_OK
            )

        except BusMinder.DoesNotExist:
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
        except Exception as e:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": str(e),
                        "field": "minder_id"
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
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
        Bulk assign children to a bus using Assignment API.

        POST /api/buses/:id/assign-children/
        Body: {"children_ids": [1, 2, 3]}

        Business Logic:
            - Validates that children count doesn't exceed bus capacity
            - Uses Assignment API bulk operation
            - Auto-cancels previous assignments

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

        try:
            # Use Assignment API bulk assignment method
            from assignments.services import AssignmentService
            assignments = AssignmentService.bulk_assign_children_to_bus(
                bus=bus,
                children_ids=children_ids,
                assigned_by=request.user
            )

            return Response(
                {
                    "success": True,
                    "message": f"{len(assignments)} children assigned to bus {bus.bus_number}",
                    "bus": BusSerializer(bus).data,
                    "assignments_count": len(assignments)
                },
                status=status.HTTP_200_OK
            )

        except Exception as e:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": str(e),
                        "field": "children_ids"
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(
        detail=True,
        methods=['get'],
        permission_classes=[IsAuthenticated],
        url_path='children'
    )
    def children(self, request, pk=None):
        """
        Get all children assigned to a bus using Assignment API.

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

        # Get children using Assignment API
        child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')

        children_data = [
            {
                "id": ca.assignee.id,
                "firstName": ca.assignee.first_name,
                "lastName": ca.assignee.last_name,
                "grade": ca.assignee.class_grade,
                "parentName": ca.assignee.parent.user.get_full_name() if ca.assignee.parent else None,
                "address": getattr(ca.assignee, 'address', None),
            }
            for ca in child_assignments
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

    @action(
        detail=True,
        methods=['get'],
        permission_classes=[IsAuthenticated],
        url_path='location-stream'
    )
    @method_decorator(never_cache)
    def location_stream(self, request, pk=None):
        """
        Server-Sent Events (SSE) endpoint for real-time bus location updates.

        GET /api/buses/:id/location-stream/

        How SSE Works:
        1. Client opens connection: GET /api/buses/1/location-stream/
        2. Server keeps connection open
        3. Server pushes updates as they happen
        4. Each update format: "data: {json}\n\n"

        Connection stays open until:
        - Client disconnects
        - Server stops
        - Network error

        Example usage in JavaScript:
            const eventSource = new EventSource('/api/buses/1/location-stream/');
            eventSource.onmessage = (event) => {
                const location = JSON.parse(event.data);
                console.log(location); // {latitude, longitude, speed, ...}
            };

        Returns:
            StreamingHttpResponse with Content-Type: text/event-stream
        """
        bus = self.get_object()

        def event_stream():
            """
            Generator function that yields SSE-formatted messages.

            SSE Message Format:
                data: {json data}\n\n

            The double newline (\n\n) signals end of message.
            """
            # Send initial location immediately
            yield self._format_sse_message({
                "busId": bus.id,
                "busNumber": bus.bus_number,
                "latitude": str(bus.latitude) if bus.latitude else None,
                "longitude": str(bus.longitude) if bus.longitude else None,
                "speed": bus.speed,
                "heading": bus.heading,
                "isActive": bus.is_active,
                "lastUpdated": bus.last_updated.isoformat() if bus.last_updated else None,
            })

            # Keep connection alive and check for updates every 2 seconds
            # In production, this will be replaced with Redis pub/sub
            last_update = bus.last_updated

            while True:
                try:
                    time.sleep(2)  # Poll every 2 seconds

                    # Refresh bus data from database
                    bus.refresh_from_db()

                    # Check if location was updated
                    if bus.last_updated != last_update:
                        last_update = bus.last_updated

                        # Send updated location
                        yield self._format_sse_message({
                            "busId": bus.id,
                            "busNumber": bus.bus_number,
                            "latitude": str(bus.latitude) if bus.latitude else None,
                            "longitude": str(bus.longitude) if bus.longitude else None,
                            "speed": bus.speed,
                            "heading": bus.heading,
                            "isActive": bus.is_active,
                            "lastUpdated": bus.last_updated.isoformat(),
                        })

                    # Send heartbeat to keep connection alive
                    yield ": heartbeat\n\n"

                except Exception as e:
                    # Client disconnected or error occurred
                    break

        response = StreamingHttpResponse(
            event_stream(),
            content_type='text/event-stream'
        )

        # SSE-specific headers
        response['Cache-Control'] = 'no-cache'  # Prevent caching
        response['X-Accel-Buffering'] = 'no'    # Disable nginx buffering

        return response

    def _format_sse_message(self, data):
        """
        Format data as SSE message.

        SSE Format:
            data: {json}\n\n

        Args:
            data: Dictionary to send as JSON

        Returns:
            Formatted SSE message string
        """
        return f"data: {json.dumps(data)}\n\n"

    @action(
        detail=True,
        methods=['post'],
        permission_classes=[IsAuthenticated],
        url_path='update-location'
    )
    def update_location(self, request, pk=None):
        """
        Update bus location in real-time (called by Driver/Minder app).

        POST /api/buses/:id/update-location/

        Request Body (Google Maps compatible format):
        {
            "latitude": 9.0820,      // Required: GPS latitude
            "longitude": 7.5340,     // Required: GPS longitude
            "speed": 45.5,           // Optional: Speed in km/h
            "heading": 180.0,        // Optional: Direction (0-360 degrees)
            "isActive": true         // Optional: Is bus currently active
        }

        How to use from Flutter/React Native:
        ```dart
        // Flutter example
        Position position = await Geolocator.getCurrentPosition();

        final response = await http.post(
          Uri.parse('$baseUrl/api/buses/1/update-location/'),
          headers: {'Authorization': 'Bearer $token'},
          body: json.encode({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'speed': position.speed,
            'heading': position.heading,
            'isActive': true,
          }),
        );
        ```

        Business Logic:
        - Only authenticated users can update
        - Location saved to database
        - SSE clients get notified via last_updated timestamp change
        - Drivers should call this every 5-10 seconds while active

        Returns:
            200: Location updated successfully
            400: Invalid data
            403: User not authorized to update this bus
            404: Bus not found
        """
        bus = self.get_object()

        # Verify user is authorized (driver or minder of this bus) using Assignment API
        user = request.user

        # Check if user is admin
        if user.is_staff or user.is_superuser:
            # Admins can update any bus
            pass
        else:
            # Check if user is a driver assigned to this bus
            is_authorized = False

            if hasattr(user, 'driver'):
                driver_assignment = Assignment.get_active_assignments_for(user.driver, 'driver_to_bus').filter(
                    assigned_to_object_id=bus.id
                ).first()
                if driver_assignment:
                    is_authorized = True

            # Check if user is a minder assigned to this bus
            if not is_authorized and hasattr(user, 'busminder'):
                minder_assignment = Assignment.get_active_assignments_for(user.busminder, 'minder_to_bus').filter(
                    assigned_to_object_id=bus.id
                ).first()
                if minder_assignment:
                    is_authorized = True

            if not is_authorized:
                return Response(
                    {
                        "success": False,
                        "error": {
                            "message": "You are not assigned to this bus",
                            "code": "NOT_ASSIGNED"
                        }
                    },
                    status=status.HTTP_403_FORBIDDEN
                )

        # Extract location data
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        speed = request.data.get('speed')
        heading = request.data.get('heading')
        is_active = request.data.get('isActive')

        # Validate required fields
        if latitude is None or longitude is None:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": "latitude and longitude are required",
                        "code": "MISSING_COORDINATES"
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate coordinate ranges (Google Maps format)
        try:
            lat = float(latitude)
            lng = float(longitude)

            if not (-90 <= lat <= 90):
                raise ValueError("Latitude must be between -90 and 90")
            if not (-180 <= lng <= 180):
                raise ValueError("Longitude must be between -180 and 180")

        except (ValueError, TypeError) as e:
            return Response(
                {
                    "success": False,
                    "error": {
                        "message": f"Invalid coordinates: {str(e)}",
                        "code": "INVALID_COORDINATES"
                    }
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Update bus location
        bus.latitude = lat
        bus.longitude = lng

        if speed is not None:
            bus.speed = float(speed)
        if heading is not None:
            bus.heading = float(heading)
        if is_active is not None:
            bus.is_active = bool(is_active)

        # Save to database (this updates last_updated automatically)
        bus.save()

        return Response(
            {
                "success": True,
                "message": "Location updated successfully",
                "data": {
                    "busId": bus.id,
                    "busNumber": bus.bus_number,
                    "latitude": str(bus.latitude),
                    "longitude": str(bus.longitude),
                    "speed": bus.speed,
                    "heading": bus.heading,
                    "isActive": bus.is_active,
                    "lastUpdated": bus.last_updated.isoformat()
                }
            },
            status=status.HTTP_200_OK
        )
