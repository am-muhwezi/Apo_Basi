import logging
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework.exceptions import ValidationError
from django.contrib.contenttypes.models import ContentType

from .models import Assignment, BusRoute, AssignmentHistory

logger = logging.getLogger(__name__)
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
from buses.serializers import BusSerializer
from drivers.models import Driver
from busminders.models import BusMinder
from children.models import Child
from children.serializers import ChildSerializer
from parents.models import Parent


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

    queryset = BusRoute.objects.order_by('id')
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

    queryset = Assignment.objects.order_by('-id')
    permission_classes = [IsAuthenticated]  # Secured: requires authentication

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return AssignmentCreateSerializer
        return AssignmentSerializer

    def get_queryset(self):
        """Filter assignments based on query parameters"""
        queryset = Assignment.objects.order_by('-id')

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

        logger.info(f"Bulk assign request: bus_id={bus_id}, children_count={len(children_ids)}, user={request.user}")

        if not bus_id:
            logger.warning("Bulk assign failed: busId not provided")
            return Response(
                {'error': 'busId is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not children_ids:
            logger.warning("Bulk assign failed: childrenIds not provided")
            return Response(
                {'error': 'childrenIds is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            bus = Bus.objects.get(pk=bus_id)
            logger.debug(f"Found bus: {bus.bus_number}")
        except Bus.DoesNotExist:
            logger.warning(f"Bulk assign failed: Bus {bus_id} not found")
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

            logger.info(f"Successfully bulk assigned {len(assignments)} children to bus {bus.bus_number}")
            serializer = AssignmentSerializer(assignments, many=True)
            return Response({
                'message': f'Successfully assigned {len(assignments)} children to bus {bus.bus_number}',
                'assignments': serializer.data
            }, status=status.HTTP_201_CREATED)

        except DjangoValidationError as e:
            logger.error(f"Validation error in bulk_assign_children_to_bus: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f"Unexpected error in bulk_assign_children_to_bus: {str(e)}", exc_info=True)
            return Response(
                {'error': 'Failed to assign children. Please try again later.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
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
        logger.info(f"Bus utilization request from user: {request.user}")
        try:
            utilization = AssignmentService.get_bus_utilization()
            logger.info(f"Successfully retrieved utilization for {len(utilization)} buses")
            return Response(utilization)
        except DjangoValidationError as e:
            logger.error(f"Validation error in bus_utilization: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f"Unexpected error in bus_utilization: {str(e)}", exc_info=True)
            return Response(
                {'error': 'Failed to retrieve bus utilization. Please try again later.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

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

    queryset = AssignmentHistory.objects.order_by('-id')
    serializer_class = AssignmentHistorySerializer
    permission_classes = [IsAuthenticated]  # Secured: requires authentication

    def get_queryset(self):
        """Filter history based on query parameters"""
        queryset = AssignmentHistory.objects.order_by('-id')

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


# ============================================================================
# CONVENIENCE API VIEWS - Single source of truth for assignment queries
# ============================================================================


class DriverAssignmentsView(APIView):
    """
    Get driver's current assignments.

    Endpoints:
    - GET /api/assignments/driver/<driver_id>/bus/ - Get driver's assigned bus
    - GET /api/assignments/driver/<driver_id>/children/ - Get children on driver's bus
    - GET /api/assignments/driver/<driver_id>/route/ - Get driver's assigned route
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, driver_id, query_type='bus'):
        """Get driver's assignments based on query type"""
        try:
            driver = Driver.objects.get(pk=driver_id)
        except Driver.DoesNotExist:
            return Response(
                {'error': f'Driver with id {driver_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        if query_type == 'bus':
            # Get driver's assigned bus
            assignment = Assignment.get_active_assignments_for(driver, 'driver_to_bus').first()

            if not assignment:
                return Response({
                    'message': 'Driver has no active bus assignment',
                    'bus': None
                })

            bus = assignment.assigned_to
            return Response({
                'bus': BusSerializer(bus).data,
                'assignment': AssignmentSerializer(assignment).data
            })

        elif query_type == 'children':
            # Get children on driver's bus
            assignment = Assignment.get_active_assignments_for(driver, 'driver_to_bus').first()

            if not assignment:
                return Response({
                    'message': 'Driver has no active bus assignment',
                    'children': []
                })

            bus = assignment.assigned_to
            child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')

            children = [ca.assignee for ca in child_assignments]

            return Response({
                'bus': BusSerializer(bus).data,
                'children': ChildSerializer(children, many=True).data,
                'count': len(children)
            })

        elif query_type == 'route':
            # Get driver's assigned route
            assignment = Assignment.get_active_assignments_for(driver, 'driver_to_route').first()

            if not assignment:
                return Response({
                    'message': 'Driver has no active route assignment',
                    'route': None
                })

            route = assignment.assigned_to
            return Response({
                'route': BusRouteSerializer(route).data,
                'assignment': AssignmentSerializer(assignment).data
            })

        else:
            return Response(
                {'error': f'Invalid query type: {query_type}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class BusAssignmentsView(APIView):
    """
    Get bus's current assignments.

    Endpoints:
    - GET /api/assignments/bus/<bus_id>/children/ - Get children on the bus
    - GET /api/assignments/bus/<bus_id>/driver/ - Get bus's driver
    - GET /api/assignments/bus/<bus_id>/minder/ - Get bus's minder
    - GET /api/assignments/bus/<bus_id>/all/ - Get all assignments for the bus
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, bus_id, query_type='all'):
        """Get bus's assignments based on query type"""
        try:
            bus = Bus.objects.get(pk=bus_id)
        except Bus.DoesNotExist:
            return Response(
                {'error': f'Bus with id {bus_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        if query_type == 'children':
            # Get children on this bus
            child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')
            children = [ca.assignee for ca in child_assignments]

            return Response({
                'bus': BusSerializer(bus).data,
                'children': ChildSerializer(children, many=True).data,
                'count': len(children),
                'capacity': bus.capacity,
                'availableSeats': bus.capacity - len(children)
            })

        elif query_type == 'driver':
            # Get bus's driver
            assignment = Assignment.get_assignments_to(bus, 'driver_to_bus').first()

            if not assignment:
                return Response({
                    'message': 'Bus has no active driver assignment',
                    'driver': None
                })

            driver = assignment.assignee
            return Response({
                'driver': {
                    'id': driver.user.id,
                    'firstName': driver.user.first_name,
                    'lastName': driver.user.last_name,
                    'email': driver.user.email,
                    'licenseNumber': driver.license_number,
                    'status': driver.status
                },
                'assignment': AssignmentSerializer(assignment).data
            })

        elif query_type == 'minder':
            # Get bus's minder
            assignment = Assignment.get_assignments_to(bus, 'minder_to_bus').first()

            if not assignment:
                return Response({
                    'message': 'Bus has no active minder assignment',
                    'minder': None
                })

            minder = assignment.assignee
            return Response({
                'minder': {
                    'id': minder.user.id,
                    'firstName': minder.user.first_name,
                    'lastName': minder.user.last_name,
                    'email': minder.user.email,
                    'phoneNumber': minder.phone_number,
                    'status': minder.status
                },
                'assignment': AssignmentSerializer(assignment).data
            })

        elif query_type == 'all':
            # Get all assignments for this bus
            assignments = Assignment.get_assignments_to(bus)

            # Organize by type
            driver_assignment = assignments.filter(assignment_type='driver_to_bus').first()
            minder_assignment = assignments.filter(assignment_type='minder_to_bus').first()
            child_assignments = assignments.filter(assignment_type='child_to_bus')

            driver = driver_assignment.assignee if driver_assignment else None
            minder = minder_assignment.assignee if minder_assignment else None
            children = [ca.assignee for ca in child_assignments]

            return Response({
                'bus': BusSerializer(bus).data,
                'driver': {
                    'id': driver.user.id,
                    'firstName': driver.user.first_name,
                    'lastName': driver.user.last_name,
                    'licenseNumber': driver.license_number,
                    'status': driver.status
                } if driver else None,
                'minder': {
                    'id': minder.user.id,
                    'firstName': minder.user.first_name,
                    'lastName': minder.user.last_name,
                    'phoneNumber': minder.phone_number,
                    'status': minder.status
                } if minder else None,
                'children': ChildSerializer(children, many=True).data,
                'counts': {
                    'children': len(children),
                    'capacity': bus.capacity,
                    'availableSeats': bus.capacity - len(children)
                }
            })

        else:
            return Response(
                {'error': f'Invalid query type: {query_type}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class ChildAssignmentsView(APIView):
    """
    Get child's current assignments.

    Endpoints:
    - GET /api/assignments/child/<child_id>/bus/ - Get child's assigned bus
    - GET /api/assignments/child/<child_id>/route/ - Get child's assigned route
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, child_id, query_type='bus'):
        """Get child's assignments based on query type"""
        try:
            child = Child.objects.get(pk=child_id)
        except Child.DoesNotExist:
            return Response(
                {'error': f'Child with id {child_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        if query_type == 'bus':
            # Get child's assigned bus
            assignment = Assignment.get_active_assignments_for(child, 'child_to_bus').first()

            if not assignment:
                return Response({
                    'message': 'Child has no active bus assignment',
                    'bus': None
                })

            bus = assignment.assigned_to

            # Get driver and minder for the bus
            driver_assignment = Assignment.get_assignments_to(bus, 'driver_to_bus').first()
            minder_assignment = Assignment.get_assignments_to(bus, 'minder_to_bus').first()

            return Response({
                'child': ChildSerializer(child).data,
                'bus': BusSerializer(bus).data,
                'driver': {
                    'id': driver_assignment.assignee.user.id,
                    'firstName': driver_assignment.assignee.user.first_name,
                    'lastName': driver_assignment.assignee.user.last_name,
                } if driver_assignment else None,
                'minder': {
                    'id': minder_assignment.assignee.user.id,
                    'firstName': minder_assignment.assignee.user.first_name,
                    'lastName': minder_assignment.assignee.user.last_name,
                } if minder_assignment else None,
                'assignment': AssignmentSerializer(assignment).data
            })

        elif query_type == 'route':
            # Get child's assigned route
            assignment = Assignment.get_active_assignments_for(child, 'child_to_route').first()

            if not assignment:
                return Response({
                    'message': 'Child has no active route assignment',
                    'route': None
                })

            route = assignment.assigned_to
            return Response({
                'child': ChildSerializer(child).data,
                'route': BusRouteSerializer(route).data,
                'assignment': AssignmentSerializer(assignment).data
            })

        else:
            return Response(
                {'error': f'Invalid query type: {query_type}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class ParentChildrenAssignmentsView(APIView):
    """
    Get parent's children and their bus assignments.

    Endpoints:
    - GET /api/assignments/parent/<parent_id>/children-buses/ - Get all children with their bus assignments
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, parent_id):
        """Get parent's children and their bus assignments"""
        try:
            parent = Parent.objects.get(pk=parent_id)
        except Parent.DoesNotExist:
            return Response(
                {'error': f'Parent with id {parent_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get all children for this parent
        children = Child.objects.filter(parent=parent)

        children_data = []
        for child in children:
            # Get child's bus assignment
            bus_assignment = Assignment.get_active_assignments_for(child, 'child_to_bus').first()

            child_info = ChildSerializer(child).data

            if bus_assignment:
                bus = bus_assignment.assigned_to

                # Get driver and minder
                driver_assignment = Assignment.get_assignments_to(bus, 'driver_to_bus').first()
                minder_assignment = Assignment.get_assignments_to(bus, 'minder_to_bus').first()

                child_info['bus'] = BusSerializer(bus).data
                child_info['driver'] = {
                    'firstName': driver_assignment.assignee.user.first_name,
                    'lastName': driver_assignment.assignee.user.last_name,
                    'phone': driver_assignment.assignee.user.email
                } if driver_assignment else None
                child_info['minder'] = {
                    'firstName': minder_assignment.assignee.user.first_name,
                    'lastName': minder_assignment.assignee.user.last_name,
                    'phone': minder_assignment.assignee.phone_number
                } if minder_assignment else None
                child_info['assignment'] = AssignmentSerializer(bus_assignment).data
            else:
                child_info['bus'] = None
                child_info['driver'] = None
                child_info['minder'] = None
                child_info['assignment'] = None

            children_data.append(child_info)

        return Response({
            'parent': {
                'id': parent.id,
                'firstName': parent.first_name,
                'lastName': parent.last_name,
                'email': parent.email
            },
            'children': children_data,
            'count': len(children_data)
        })


class MinderAssignmentsView(APIView):
    """
    Get minder's current assignments.

    Endpoints:
    - GET /api/assignments/minder/<minder_id>/buses/ - Get minder's assigned buses
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, minder_id):
        """Get minder's assigned buses"""
        try:
            minder = BusMinder.objects.get(pk=minder_id)
        except BusMinder.DoesNotExist:
            return Response(
                {'error': f'BusMinder with id {minder_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get all bus assignments for this minder
        assignments = Assignment.get_active_assignments_for(minder, 'minder_to_bus')

        buses_data = []
        for assignment in assignments:
            bus = assignment.assigned_to

            # Get children on this bus
            child_assignments = Assignment.get_assignments_to(bus, 'child_to_bus')
            children_count = child_assignments.count()

            buses_data.append({
                'bus': BusSerializer(bus).data,
                'childrenCount': children_count,
                'availableSeats': bus.capacity - children_count,
                'assignment': AssignmentSerializer(assignment).data
            })

        return Response({
            'minder': {
                'id': minder.user.id,
                'firstName': minder.user.first_name,
                'lastName': minder.user.last_name,
                'phoneNumber': minder.phone_number,
                'status': minder.status
            },
            'buses': buses_data,
            'count': len(buses_data)
        })


class QuickAssignView(APIView):
    """
    Quick assignment endpoints for common operations.

    Endpoints:
    - POST /api/assignments/quick/assign-driver-to-bus/
    - POST /api/assignments/quick/assign-minder-to-bus/
    - POST /api/assignments/quick/assign-child-to-bus/
    - POST /api/assignments/quick/assign-bus-to-route/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, assignment_type):
        """Quick assignment based on type"""

        type_mapping = {
            'assign-driver-to-bus': ('driver_to_bus', 'driverId', 'busId', Driver, Bus),
            'assign-minder-to-bus': ('minder_to_bus', 'minderId', 'busId', BusMinder, Bus),
            'assign-child-to-bus': ('child_to_bus', 'childId', 'busId', Child, Bus),
            'assign-bus-to-route': ('bus_to_route', 'busId', 'routeId', Bus, BusRoute),
        }

        if assignment_type not in type_mapping:
            return Response(
                {'error': f'Invalid assignment type: {assignment_type}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        assignment_type_code, assignee_key, assigned_to_key, assignee_model, assigned_to_model = type_mapping[assignment_type]

        assignee_id = request.data.get(assignee_key)
        assigned_to_id = request.data.get(assigned_to_key)
        effective_date = request.data.get('effectiveDate')
        expiry_date = request.data.get('expiryDate')
        reason = request.data.get('reason', '')

        if not assignee_id or not assigned_to_id:
            return Response(
                {'error': f'{assignee_key} and {assigned_to_key} are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            assignee = assignee_model.objects.get(pk=assignee_id)
        except assignee_model.DoesNotExist:
            return Response(
                {'error': f'{assignee_model.__name__} with id {assignee_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        try:
            assigned_to = assigned_to_model.objects.get(pk=assigned_to_id)
        except assigned_to_model.DoesNotExist:
            return Response(
                {'error': f'{assigned_to_model.__name__} with id {assigned_to_id} not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        try:
            assignment = AssignmentService.create_assignment(
                assignment_type=assignment_type_code,
                assignee=assignee,
                assigned_to=assigned_to,
                assigned_by=request.user if request.user.is_authenticated else None,
                effective_date=effective_date,
                expiry_date=expiry_date,
                reason=reason,
                auto_cancel_conflicting=True
            )

            return Response({
                'message': f'Successfully assigned {assignee} to {assigned_to}',
                'assignment': AssignmentSerializer(assignment).data
            }, status=status.HTTP_201_CREATED)

        except DjangoValidationError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
