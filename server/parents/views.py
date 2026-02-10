"""Parent views for CRUD and phone-based login flows."""

import os
import logging
import requests
from jose import jwt, JWTError

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model
from django.db import transaction
from django.conf import settings

from .models import Parent
from .serializers import ParentLoginSerializer, ParentSerializer, ParentCreateSerializer
from children.models import Child
from attendance.models import Attendance
from users.permissions import IsParent
from assignments.models import Assignment
from notifications.models import Notification
from notifications.serializers import NotificationSerializer
from trips.models import Trip
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

    def retrieve(self, request, *args, **kwargs):
        """
        Enhanced retrieve to return parent profile + children + notifications in one call.

        GET /api/parents/:id/

        Returns consolidated dashboard data to reduce multiple API calls.
        """
        parent = self.get_object()

        # Get parent profile data
        parent_data = {
            "id": parent.user.id,
            "firstName": parent.user.first_name,
            "lastName": parent.user.last_name,
            "email": parent.user.email,
            "phone": parent.contact_number,
            "address": parent.address,
            "emergencyContact": parent.emergency_contact,
            "status": parent.status,
        }

        # Get all children for this parent with bus assignments
        children = Child.objects.filter(parent=parent)
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
                "status": child.location_status,  # Use location_status for real-time tracking
                "assignedBus": None,
                "routeName": None,
                "routeCode": None,
            }

            if bus_assignment:
                bus = bus_assignment.assigned_to

                # Get driver name
                from assignments.models import BusRoute
                driver_assignment = Assignment.get_assignments_to(bus, 'driver_to_bus').first()
                driver_name = None
                if driver_assignment and driver_assignment.assignee:
                    driver = driver_assignment.assignee
                    driver_name = f"{driver.user.first_name} {driver.user.last_name}" if hasattr(driver, 'user') else None

                # Get route information from bus assignment
                route_assignment = Assignment.get_active_assignments_for(bus, 'bus_to_route').first()
                route_name = None
                route_code = None
                if route_assignment and hasattr(route_assignment, 'assigned_to'):
                    route = route_assignment.assigned_to
                    if isinstance(route, BusRoute):
                        route_name = route.name
                        route_code = route.route_code
                        child_data["routeName"] = route.name
                        child_data["routeCode"] = route.route_code

                # Get active trip for this bus to show route on parent's map
                active_trip = Trip.objects.filter(
                    bus=bus,
                    status='in-progress'
                ).first()

                trip_data = None
                if active_trip:
                    from trips.serializers import TripSerializer
                    trip_data = TripSerializer(active_trip).data

                child_data["assignedBus"] = {
                    "id": bus.id,
                    "busNumber": bus.bus_number,
                    "licensePlate": bus.number_plate,
                    "driverName": driver_name,
                    "routeName": route_name,
                    "route": route_name,  # Add route field for backward compatibility
                    "activeTrip": trip_data,  # Include active trip with route data for map display
                }

            children_data.append(child_data)

        # Get recent notifications (last 10 unread)
        notifications = Notification.objects.filter(
            parent=parent,
            is_read=False
        ).order_by('-created_at')[:10]

        notifications_data = NotificationSerializer(notifications, many=True).data
        unread_count = Notification.objects.filter(parent=parent, is_read=False).count()

        return Response(
            {
                "success": True,
                "parent": parent_data,
                "children": children_data,
                "totalChildren": len(children_data),
                "notifications": notifications_data,
                "unreadNotificationsCount": unread_count,
            },
            status=status.HTTP_200_OK
        )

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
                "status": child.location_status,  # Use location_status for real-time tracking
                "assignedBus": None,
                "routeName": None,
                "routeCode": None,
            }

            if bus_assignment:
                bus = bus_assignment.assigned_to

                # Get driver name
                from assignments.models import BusRoute
                driver_assignment = Assignment.get_assignments_to(bus, 'driver_to_bus').first()
                driver_name = None
                if driver_assignment and driver_assignment.assignee:
                    driver = driver_assignment.assignee
                    driver_name = f"{driver.user.first_name} {driver.user.last_name}" if hasattr(driver, 'user') else None

                # Get route information from bus assignment
                route_assignment = Assignment.get_active_assignments_for(bus, 'bus_to_route').first()
                route_name = None
                route_code = None
                if route_assignment and hasattr(route_assignment, 'assigned_to'):
                    route = route_assignment.assigned_to
                    if isinstance(route, BusRoute):
                        route_name = route.name
                        route_code = route.route_code
                        child_data["routeName"] = route.name
                        child_data["routeCode"] = route.route_code

                # Get active trip for this bus to show route on parent's map
                active_trip = Trip.objects.filter(
                    bus=bus,
                    status='in-progress'
                ).first()

                trip_data = None
                if active_trip:
                    from trips.serializers import TripSerializer
                    trip_data = TripSerializer(active_trip).data

                child_data["assignedBus"] = {
                    "id": bus.id,
                    "busNumber": bus.bus_number,
                    "licensePlate": bus.number_plate,
                    "driverName": driver_name,
                    "routeName": route_name,
                    "route": route_name,  # Add route field for backward compatibility
                    "activeTrip": trip_data,  # Include active trip with route data for map display
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
                    "status": child.location_status,  # Use location_status for real-time tracking
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


class CheckEmailView(APIView):
    """
    POST /api/parents/auth/check-email/
    Check if an email is registered in the system before sending magic link.

    This prevents Supabase from sending magic links to unregistered users.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')

        if not email:
            return Response(
                {"error": "email is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if parent exists with this email
        try:
            parent = Parent.objects.select_related('user').get(
                user__email__iexact=email,  # Case-insensitive match
                status='active'
            )

            return Response(
                {
                    "registered": True,
                    "message": "Email is registered"
                },
                status=status.HTTP_200_OK
            )
        except Parent.DoesNotExist:
            return Response(
                {
                    "registered": False,
                    "message": "This email is not registered. Please contact your school administrator to set up your account."
                },
                status=status.HTTP_404_NOT_FOUND
            )


class SupabaseMagicLinkAuthView(APIView):
    """
    POST /api/parents/auth/magic-link/
    Exchange Supabase session for Django JWT tokens.

    The magic link flow:
    1. User enters email in Flutter app
    2. Supabase sends magic link email
    3. User clicks link → opens app via deep linking
    4. Flutter extracts Supabase access_token
    5. Flutter sends token to this endpoint
    6. Django verifies token and returns Django JWT tokens
    """
    permission_classes = [AllowAny]

    def post(self, request):
        access_token = request.data.get('access_token')

        if not access_token:
            return Response(
                {"error": "access_token is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Fetch JWKS (JSON Web Key Set) from Supabase
            jwks_response = requests.get(settings.SUPABASE_JWKS_URL, timeout=5)
            jwks_response.raise_for_status()
            jwks = jwks_response.json()

            # Verify and decode the Supabase JWT token
            payload = jwt.decode(
                access_token,
                jwks,
                algorithms=['ES256'],
                options={
                    'verify_aud': False,  # Supabase uses different audience
                    'verify_iss': True,
                }
            )

            email = payload.get('email')
            if not email:
                return Response(
                    {"error": "Email not found in token"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Check if parent exists with this email
            try:
                parent = Parent.objects.select_related('user').get(
                    user__email=email,
                    status='active'
                )
                user = parent.user
            except Parent.DoesNotExist:
                return Response(
                    {
                        "error": "No parent account found",
                        "message": "Your email is not registered. Please contact your school administrator to set up your account."
                    },
                    status=status.HTTP_404_NOT_FOUND
                )

            # Generate Django JWT tokens
            refresh = RefreshToken.for_user(user)

            # Get parent's children with bus assignments
            children = Child.objects.filter(parent=parent)
            children_data = []

            for child in children:
                bus_assignment = Assignment.get_active_assignments_for(child, 'child_to_bus').first()

                child_data = {
                    "id": child.id,
                    "first_name": child.first_name,
                    "last_name": child.last_name,
                    "class_grade": child.class_grade,
                    "status": child.location_status,  # Use location_status for real-time tracking
                    "assigned_bus": None
                }

                if bus_assignment:
                    bus = bus_assignment.assigned_to
                    driver_assignment = Assignment.get_assignments_to(bus, 'driver_to_bus').first()
                    minder_assignment = Assignment.get_assignments_to(bus, 'minder_to_bus').first()

                    driver_info = None
                    if driver_assignment and driver_assignment.assignee:
                        driver_info = {
                            "name": f"{driver_assignment.assignee.user.first_name} {driver_assignment.assignee.user.last_name}",
                            "phone": driver_assignment.assignee.phone_number
                        }

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
                        "id": user.id,
                        "firstName": user.first_name,
                        "lastName": user.last_name,
                        "email": user.email,
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

        except JWTError as e:
            logger.error(f"JWT verification failed: {str(e)}")
            return Response(
                {
                    "error": "Invalid or expired token",
                    "message": "Your session has expired. Please request a new magic link."
                },
                status=status.HTTP_401_UNAUTHORIZED
            )
        except requests.RequestException as e:
            logger.error(f"Failed to fetch JWKS: {str(e)}")
            return Response(
                {"error": "Authentication service unavailable"},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )
        except Exception as e:
            logger.exception("Unexpected error during Supabase magic link auth")
            return Response(
                {
                    "error": "Authentication failed",
                    "message": "Something went wrong. Please try again."
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class DemoLoginView(APIView):
    """
    POST /api/parents/auth/demo-login/
    Demo account login for Apple App Store review process.

    This endpoint allows password-based authentication for a specific
    demo account, bypassing the magic link flow for review purposes.

    Credentials are stored in environment variables:
    - REVIEWER_EMAIL
    - REVIEWER_PASSWORD
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        password = request.data.get('password', '')

        reviewer_email = os.environ.get('REVIEWER_EMAIL', '').strip().lower()
        reviewer_password = os.environ.get('REVIEWER_PASSWORD', '')

        if not reviewer_email or not reviewer_password:
            logger.error("Demo login credentials not configured in environment")
            return Response(
                {"error": "Demo login not available"},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        if email != reviewer_email or password != reviewer_password:
            return Response(
                {"error": "Invalid email or password"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            parent = Parent.objects.select_related('user').get(
                user__email__iexact=email,
                status='active'
            )
            user = parent.user

            refresh = RefreshToken.for_user(user)

            children = Child.objects.filter(parent=parent)
            children_data = []

            for child in children:
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
                    driver_assignment = Assignment.get_assignments_to(bus, 'driver_to_bus').first()
                    minder_assignment = Assignment.get_assignments_to(bus, 'minder_to_bus').first()

                    driver_info = None
                    if driver_assignment and driver_assignment.assignee:
                        driver_info = {
                            "name": f"{driver_assignment.assignee.user.first_name} {driver_assignment.assignee.user.last_name}",
                            "phone": driver_assignment.assignee.phone_number
                        }

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

            logger.info(f"Demo login successful for: {email}")

            return Response(
                {
                    "success": True,
                    "parent": {
                        "id": user.id,
                        "firstName": user.first_name,
                        "lastName": user.last_name,
                        "email": user.email,
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

        except Parent.DoesNotExist:
            logger.error(f"Demo parent account not found for email: {email}")
            return Response(
                {
                    "error": "Demo account not found",
                    "message": "The demo account has not been set up. Please contact support."
                },
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.exception("Unexpected error during demo login")
            return Response(
                {
                    "error": "Login failed",
                    "message": "Something went wrong. Please try again."
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
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
