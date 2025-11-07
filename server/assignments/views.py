from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework.exceptions import ValidationError

from .models import Assignment, BusRoute, AssignmentHistory
from .serializers import (
    AssignmentSerializer,
    AssignmentCreateSerializer,
    BusRouteSerializer,
    BusRouteCreateSerializer,
    AssignmentHistorySerializer
)
from .services import AssignmentService
from .validators import AssignmentValidator
from buses.models import Bus
from drivers.models import Driver
from busminders.models import BusMinder
from children.models import Child


class BusRouteViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing bus routes.

    Endpoints:
    - GET /api/assignments/routes/ - List all routes
    - POST /api/assignments/routes/ - Create new route
    - GET /api/assignments/routes/{id}/ - Get route details
    - PUT/PATCH /api/assignments/routes/{id}/ - Update route
    - DELETE /api/assignments/routes/{id}/ - Delete route
    - GET /api/assignments/routes/{id}/assignments/ - Get route assignments
    - GET /api/assignments/routes/{id}/statistics/ - Get route statistics
    """

    queryset = BusRoute.objects.all()
    permission_classes = [IsAuthenticated]  # Secured: requires authentication

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return BusRouteCreateSerializer
        return BusRouteSerializer

    @action(detail=True, methods=['get'])
    def assignments(self, request, pk=None):
        """Get all active assignments for this route"""
        route = self.get_object()
        assignments = route.get_active_assignments()
        serializer = AssignmentSerializer(assignments, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def statistics(self, request, pk=None):
        """Get statistics for this route"""
        route = self.get_object()
        stats = AssignmentService.get_route_statistics(route)
        return Response(stats)


class AssignmentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing assignments.

    Endpoints:
    - GET /api/assignments/ - List all assignments (with filters)
    - POST /api/assignments/ - Create new assignment
    - GET /api/assignments/{id}/ - Get assignment details
    - PUT/PATCH /api/assignments/{id}/ - Update assignment
    - DELETE /api/assignments/{id}/ - Delete assignment
    - POST /api/assignments/{id}/cancel/ - Cancel assignment
    - GET /api/assignments/{id}/history/ - Get assignment history
    - POST /api/assignments/bulk-assign-children-to-bus/ - Bulk assign children
    - POST /api/assignments/bulk-assign-children-to-route/ - Bulk assign to route
    - GET /api/assignments/bus-utilization/ - Get bus utilization stats
    """

    queryset = Assignment.objects.all()
    permission_classes = [IsAuthenticated]  # Secured: requires authentication

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return AssignmentCreateSerializer
        return AssignmentSerializer

    def get_queryset(self):
        """Filter assignments based on query parameters"""
        queryset = Assignment.objects.all()

        # Filter by assignment type
        assignment_type = self.request.query_params.get('assignmentType')
        if assignment_type:
            queryset = queryset.filter(assignment_type=assignment_type)

        # Filter by status
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)

        # Filter by assignee ID and type
        assignee_id = self.request.query_params.get('assigneeId')
        assignee_type = self.request.query_params.get('assigneeType')
        if assignee_id and assignee_type:
            from django.contrib.contenttypes.models import ContentType
            try:
                ct = ContentType.objects.get(model=assignee_type.lower())
                queryset = queryset.filter(
                    assignee_content_type=ct,
                    assignee_object_id=assignee_id
                )
            except ContentType.DoesNotExist:
                pass

        # Filter by assigned_to ID and type
        assigned_to_id = self.request.query_params.get('assignedToId')
        assigned_to_type = self.request.query_params.get('assignedToType')
        if assigned_to_id and assigned_to_type:
            from django.contrib.contenttypes.models import ContentType
            try:
                ct = ContentType.objects.get(model=assigned_to_type.lower())
                queryset = queryset.filter(
                    assigned_to_content_type=ct,
                    assigned_to_object_id=assigned_to_id
                )
            except ContentType.DoesNotExist:
                pass

        # Filter by active status (currently active based on dates)
        only_active = self.request.query_params.get('onlyActive')
        if only_active and only_active.lower() == 'true':
            from django.utils import timezone
            from django.db.models import Q
            today = timezone.now().date()
            queryset = queryset.filter(
                status='active',
                effective_date__lte=today
            ).filter(
                Q(expiry_date__isnull=True) |
                Q(expiry_date__gte=today)
            )

        return queryset

    def create(self, request, *args, **kwargs):
        """Create a new assignment with validation"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)

        try:
            assignment = serializer.save()
            response_serializer = AssignmentSerializer(assignment)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        except DjangoValidationError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel an assignment"""
        assignment = self.get_object()
        reason = request.data.get('reason', '')

        assignment.cancel(
            cancelled_by=request.user if request.user.is_authenticated else None,
            reason=reason
        )

        serializer = AssignmentSerializer(assignment)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def history(self, request, pk=None):
        """Get history for this assignment"""
        assignment = self.get_object()
        history = assignment.history.all()
        serializer = AssignmentHistorySerializer(history, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def bulk_assign_children_to_bus(self, request):
        """
        Bulk assign multiple children to a bus.

        Request body:
        {
            "busId": 1,
            "childrenIds": [1, 2, 3],
            "effectiveDate": "2025-01-01" (optional)
        }
        """
        bus_id = request.data.get('busId')
        children_ids = request.data.get('childrenIds', [])
        effective_date = request.data.get('effectiveDate')

        if not bus_id:
            return Response(
                {'error': 'busId is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not children_ids:
            return Response(
                {'error': 'childrenIds is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            bus = Bus.objects.get(pk=bus_id)
        except Bus.DoesNotExist:
            return Response(
                {'error': f'Bus with id {bus_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        try:
            assignments = AssignmentService.bulk_assign_children_to_bus(
                bus=bus,
                children_ids=children_ids,
                assigned_by=request.user if request.user.is_authenticated else None,
                effective_date=effective_date
            )

            serializer = AssignmentSerializer(assignments, many=True)
            return Response({
                'message': f'Successfully assigned {len(assignments)} children to bus {bus.bus_number}',
                'assignments': serializer.data
            }, status=status.HTTP_201_CREATED)

        except DjangoValidationError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['post'])
    def bulk_assign_children_to_route(self, request):
        """
        Bulk assign multiple children to a route.

        Request body:
        {
            "routeId": 1,
            "childrenIds": [1, 2, 3],
            "effectiveDate": "2025-01-01" (optional)
        }
        """
        route_id = request.data.get('routeId')
        children_ids = request.data.get('childrenIds', [])
        effective_date = request.data.get('effectiveDate')

        if not route_id:
            return Response(
                {'error': 'routeId is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not children_ids:
            return Response(
                {'error': 'childrenIds is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            route = BusRoute.objects.get(pk=route_id)
        except BusRoute.DoesNotExist:
            return Response(
                {'error': f'Route with id {route_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        try:
            assignments = AssignmentService.bulk_assign_children_to_route(
                route=route,
                children_ids=children_ids,
                assigned_by=request.user if request.user.is_authenticated else None,
                effective_date=effective_date
            )

            serializer = AssignmentSerializer(assignments, many=True)
            return Response({
                'message': f'Successfully assigned {len(assignments)} children to route {route.route_code}',
                'assignments': serializer.data
            }, status=status.HTTP_201_CREATED)

        except DjangoValidationError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['get'])
    def bus_utilization(self, request):
        """Get utilization statistics for all buses"""
        utilization = AssignmentService.get_bus_utilization()
        return Response(utilization)

    @action(detail=False, methods=['post'])
    def transfer(self, request):
        """
        Transfer an assignment to a new entity.

        Request body:
        {
            "assignmentId": 1,
            "newAssignedToId": 2,
            "newAssignedToType": "bus",
            "reason": "Bus change requested by parent"
        }
        """
        assignment_id = request.data.get('assignmentId')
        new_assigned_to_id = request.data.get('newAssignedToId')
        new_assigned_to_type = request.data.get('newAssignedToType', '').lower()
        reason = request.data.get('reason', '')

        if not assignment_id or not new_assigned_to_id or not new_assigned_to_type:
            return Response(
                {'error': 'assignmentId, newAssignedToId, and newAssignedToType are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            assignment = Assignment.objects.get(pk=assignment_id)
        except Assignment.DoesNotExist:
            return Response(
                {'error': f'Assignment with id {assignment_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get the new entity based on type
        model_mapping = {
            'bus': Bus,
            'route': BusRoute,
            'busroute': BusRoute,
        }

        if new_assigned_to_type not in model_mapping:
            return Response(
                {'error': f'Invalid newAssignedToType: {new_assigned_to_type}. Must be one of: {list(model_mapping.keys())}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            model = model_mapping[new_assigned_to_type]
            new_assigned_to = model.objects.get(pk=new_assigned_to_id)
        except model.DoesNotExist:
            return Response(
                {'error': f'{model.__name__} with id {new_assigned_to_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        try:
            new_assignment = AssignmentService.transfer_assignment(
                assignment=assignment,
                new_assigned_to=new_assigned_to,
                assigned_by=request.user if request.user.is_authenticated else None,
                reason=reason
            )

            serializer = AssignmentSerializer(new_assignment)
            return Response({
                'message': 'Assignment transferred successfully',
                'assignment': serializer.data
            })

        except DjangoValidationError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class AssignmentHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing assignment history (read-only).

    Endpoints:
    - GET /api/assignments/history/ - List all history entries
    - GET /api/assignments/history/{id}/ - Get specific history entry
    """

    queryset = AssignmentHistory.objects.all()
    serializer_class = AssignmentHistorySerializer
    permission_classes = [IsAuthenticated]  # Secured: requires authentication

    def get_queryset(self):
        """Filter history based on query parameters"""
        queryset = AssignmentHistory.objects.all()

        # Filter by assignment ID
        assignment_id = self.request.query_params.get('assignmentId')
        if assignment_id:
            queryset = queryset.filter(assignment_id=assignment_id)

        # Filter by action
        action = self.request.query_params.get('action')
        if action:
            queryset = queryset.filter(action=action)

        # Filter by performer
        performed_by_id = self.request.query_params.get('performedById')
        if performed_by_id:
            queryset = queryset.filter(performed_by_id=performed_by_id)

        return queryset
