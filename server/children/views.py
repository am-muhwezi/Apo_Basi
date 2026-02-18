from rest_framework import generics, filters
from rest_framework.permissions import IsAuthenticated
from .models import Child
from .serializers import ChildSerializer, ChildCreateSerializer


class ChildListCreateView(generics.ListCreateAPIView):
    """
    GET /api/children/ - List all children
    POST /api/children/ - Create new child
    """
    permission_classes = [IsAuthenticated]
    queryset = Child.objects.select_related('parent__user', 'assigned_bus').order_by('id')
    filter_backends = [filters.SearchFilter]
    search_fields = ['first_name', 'last_name', 'parent__user__first_name', 'parent__user__last_name']

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ChildCreateSerializer
        return ChildSerializer


class ChildDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/children/{id}/ - Get child details
    PUT /api/children/{id}/ - Update child
    PATCH /api/children/{id}/ - Partial update child
    DELETE /api/children/{id}/ - Delete child
    """
    permission_classes = [IsAuthenticated]
    queryset = Child.objects.select_related('parent__user', 'assigned_bus').all()

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return ChildCreateSerializer
        return ChildSerializer
