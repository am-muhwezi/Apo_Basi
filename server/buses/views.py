from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from .models import Bus
from .serializers import BusSerializer, BusCreateSerializer
from children.models import Child
from django.contrib.auth import get_user_model

User = get_user_model()


class BusListCreateView(generics.ListCreateAPIView):
    """
    GET: List all buses with full details
    POST: Create a new bus

    Business Logic:
    - Lists all buses with driver, minder, and children count
    - Creates new bus with proper field mapping from frontend
    - Handles status conversion (active/maintenance/inactive → is_active boolean)
    """
    permission_classes = [AllowAny]  # Change to IsAuthenticated in production
    queryset = Bus.objects.select_related('driver', 'bus_minder').prefetch_related('children').all()

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return BusCreateSerializer
        return BusSerializer


class BusDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET: Retrieve bus details
    PUT/PATCH: Update bus
    DELETE: Delete bus

    Business Logic:
    - Retrieves single bus with all relationships
    - Updates bus with proper field validation
    - Deletes bus (children assigned_bus set to NULL via SET_NULL)
    """
    permission_classes = [AllowAny]  # Change to IsAuthenticated in production
    queryset = Bus.objects.select_related('driver', 'bus_minder').prefetch_related('children').all()

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return BusCreateSerializer
        return BusSerializer


class BusAssignDriverView(APIView):
    """
    POST: Assign a driver to a bus

    Endpoint: /api/buses/{bus_id}/assign-driver/
    Body: {"driver_id": 1}
    """
    permission_classes = [AllowAny]

    def post(self, request, pk):
        bus = get_object_or_404(Bus, pk=pk)
        driver_id = request.data.get('driver_id')

        if not driver_id:
            return Response(
                {"error": "driver_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            driver = User.objects.get(id=driver_id, user_type='driver')
            bus.driver = driver
            bus.save()

            return Response({
                "message": f"Driver {driver.get_full_name()} assigned to bus {bus.bus_number}",
                "bus": BusSerializer(bus).data
            }, status=status.HTTP_200_OK)

        except User.DoesNotExist:
            return Response(
                {"error": "Driver not found"},
                status=status.HTTP_404_NOT_FOUND
            )


class BusAssignMinderView(APIView):
    """
    POST: Assign a bus minder to a bus

    Endpoint: /api/buses/{bus_id}/assign-minder/
    Body: {"minder_id": 1}
    """
    permission_classes = [AllowAny]

    def post(self, request, pk):
        bus = get_object_or_404(Bus, pk=pk)
        minder_id = request.data.get('minder_id')

        if not minder_id:
            return Response(
                {"error": "minder_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            minder = User.objects.get(id=minder_id, user_type='busminder')
            bus.bus_minder = minder
            bus.save()

            return Response({
                "message": f"Bus minder {minder.get_full_name()} assigned to bus {bus.bus_number}",
                "bus": BusSerializer(bus).data
            }, status=status.HTTP_200_OK)

        except User.DoesNotExist:
            return Response(
                {"error": "Bus minder not found"},
                status=status.HTTP_404_NOT_FOUND
            )


class BusAssignChildrenView(APIView):
    """
    POST: Bulk assign children to a bus

    Endpoint: /api/buses/{bus_id}/assign-children/
    Body: {"children_ids": [1, 2, 3]}
    """
    permission_classes = [AllowAny]

    def post(self, request, pk):
        bus = get_object_or_404(Bus, pk=pk)
        children_ids = request.data.get('children_ids', [])

        if not children_ids:
            return Response(
                {"error": "children_ids array is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check bus capacity
        if len(children_ids) > bus.capacity:
            return Response(
                {"error": f"Cannot assign {len(children_ids)} children. Bus capacity is {bus.capacity}"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Assign children to bus
        children = Child.objects.filter(id__in=children_ids)
        children.update(assigned_bus=bus)

        return Response({
            "message": f"{children.count()} children assigned to bus {bus.bus_number}",
            "bus": BusSerializer(bus).data
        }, status=status.HTTP_200_OK)


class BusChildrenView(APIView):
    """
    GET: Get all children assigned to a bus

    Endpoint: /api/buses/{bus_id}/children/
    """
    permission_classes = [AllowAny]

    def get(self, request, pk):
        bus = get_object_or_404(Bus, pk=pk)
        children = bus.children.select_related('parent', 'parent__user').all()

        children_data = [
            {
                "id": child.id,
                "first_name": child.first_name,
                "last_name": child.last_name,
                "class_grade": child.class_grade,
                "parent_name": child.parent.user.get_full_name() if child.parent else None,
            }
            for child in children
        ]

        return Response({
            "bus_id": bus.id,
            "bus_number": bus.bus_number,
            "capacity": bus.capacity,
            "assigned_count": len(children_data),
            "available_capacity": bus.capacity - len(children_data),
            "children": children_data
        }, status=status.HTTP_200_OK)


# Legacy view for backward compatibility
class BusListView(APIView):
    """Legacy endpoint - use BusListCreateView instead"""
    permission_classes = [AllowAny]

    def get(self, request):
        buses = Bus.objects.select_related('driver', 'bus_minder').prefetch_related('children').all()
        serializer = BusSerializer(buses, many=True)
        return Response(serializer.data)
