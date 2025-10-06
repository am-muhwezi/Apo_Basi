from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

from rest_framework_simplejwt.tokens import RefreshToken
from django.shortcuts import get_object_or_404
from django.contrib.auth import authenticate
from users.serializers import ParentRegistrationSerializer, UserSerializer
from users.models import User
from children.models import Child
from children.serializers import ChildSerializer
from .models import Parent
from .serializers import ParentSerializer, ParentCreateSerializer


class ParentListCreateView(generics.ListCreateAPIView):
    """
    GET /api/parents/ - List all parents
    POST /api/parents/ - Create new parent
    """
    permission_classes = [AllowAny]
    queryset = Parent.objects.select_related('user').all()

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ParentCreateSerializer
        return ParentSerializer


class ParentDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/parents/{id}/ - Get parent details
    PUT /api/parents/{id}/ - Update parent
    PATCH /api/parents/{id}/ - Partial update parent
    DELETE /api/parents/{id}/ - Delete parent
    """
    permission_classes = [AllowAny]
    queryset = Parent.objects.select_related('user').all()
    lookup_field = 'user_id'

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return ParentCreateSerializer
        return ParentSerializer


class ParentLoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")
        user = authenticate(username=username, password=password)
        if user and hasattr(user, "parent"):
            refresh = RefreshToken.for_user(user)
            # Get children for this parent
            children = Child.objects.filter(parent=user.parent)
            children_data = ChildSerializer(children, many=True).data
            return Response(
                {
                    "user": UserSerializer(user).data,
                    "tokens": {
                        "refresh": str(refresh),
                        "access": str(refresh.access_token),
                    },
                    "children": children_data,
                    "message": "Login successful",
                }
            )
        return Response({"error": "Invalid credentials"}, status=400)


class ParentRegistrationView(generics.CreateAPIView):
    serializer_class = ParentRegistrationSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Generate JWT tokens for the user
        refresh = RefreshToken.for_user(user)

        return Response(
            {
                "user": UserSerializer(user).data,
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                },
                "message": "Parent registered successfully",
            },
            status=status.HTTP_201_CREATED,
        )


from users.permissions import IsParent
from rest_framework.permissions import IsAuthenticated
from attendance.models import Attendance
from datetime import date


class MyChildrenView(APIView):
    """
    Allows a parent to view all their children with current status.

    Endpoint: GET /api/parents/my-children/
    Returns: List of children with their current attendance status

    For junior devs:
    - This view is protected by IsAuthenticated and IsParent permissions
    - It automatically filters children by the logged-in parent's profile
    - Includes today's attendance status for each child
    """
    permission_classes = [IsAuthenticated, IsParent]

    def get(self, request):
        # Get the parent profile for the logged-in user
        try:
            parent = Parent.objects.get(user=request.user)
        except Parent.DoesNotExist:
            return Response(
                {"error": "Parent profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get all children for this parent
        children = Child.objects.filter(parent=parent).select_related('assigned_bus')

        # Get today's attendance for each child
        today = date.today()
        children_data = []

        for child in children:
            # Get today's attendance record if it exists
            try:
                attendance = Attendance.objects.get(child=child, date=today)
                attendance_status = attendance.get_status_display()
                attendance_time = attendance.timestamp
            except Attendance.DoesNotExist:
                attendance_status = "No record today"
                attendance_time = None

            children_data.append({
                "id": child.id,
                "first_name": child.first_name,
                "last_name": child.last_name,
                "class_grade": child.class_grade,
                "assigned_bus": {
                    "id": child.assigned_bus.id,
                    "number_plate": child.assigned_bus.number_plate,
                } if child.assigned_bus else None,
                "current_status": attendance_status,
                "last_updated": attendance_time,
            })

        return Response({
            "children": children_data,
            "count": len(children_data)
        })


class ChildAttendanceHistoryView(APIView):
    """
    Allows a parent to view attendance history for a specific child.

    Endpoint: GET /api/parents/children/{child_id}/attendance/
    Returns: List of attendance records for the child

    Security:
    - Parents can only view attendance for their own children
    - Returns 403 if trying to access another parent's child
    """
    permission_classes = [IsAuthenticated, IsParent]

    def get(self, request, child_id):
        # Get the parent profile for the logged-in user
        try:
            parent = Parent.objects.get(user=request.user)
        except Parent.DoesNotExist:
            return Response(
                {"error": "Parent profile not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get the child and verify it belongs to this parent
        child = get_object_or_404(Child, id=child_id)

        if child.parent != parent:
            return Response(
                {"error": "You can only view attendance for your own children"},
                status=status.HTTP_403_FORBIDDEN
            )

        # Get attendance records for this child, ordered by date (most recent first)
        attendance_records = Attendance.objects.filter(child=child).select_related('bus', 'marked_by').order_by('-date')

        attendance_data = [{
            "id": record.id,
            "date": record.date,
            "status": record.get_status_display(),
            "bus": {
                "id": record.bus.id,
                "number_plate": record.bus.number_plate,
            } if record.bus else None,
            "marked_by": record.marked_by.get_full_name() if record.marked_by else None,
            "timestamp": record.timestamp,
            "notes": record.notes,
        } for record in attendance_records]

        return Response({
            "child": {
                "id": child.id,
                "name": f"{child.first_name} {child.last_name}",
                "class_grade": child.class_grade,
            },
            "attendance_history": attendance_data,
            "total_records": len(attendance_data)
        })
