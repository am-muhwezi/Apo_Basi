from rest_framework import generics
from rest_framework.permissions import AllowAny
from .models import Child
from .serializers import ChildSerializer, ChildCreateSerializer


class ChildListCreateView(generics.ListCreateAPIView):
    """
    GET /api/children/ - List all children
    POST /api/children/ - Create new child
    """
    permission_classes = [AllowAny]
    queryset = Child.objects.select_related('parent__user', 'assigned_bus').all()

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
    permission_classes = [AllowAny]
    queryset = Child.objects.select_related('parent__user', 'assigned_bus').all()

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return ChildCreateSerializer
        return ChildSerializer
