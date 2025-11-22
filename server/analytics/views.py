"""
Analytics views - HTTP layer only.

All business logic and calculations are delegated to services.py.
"""

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .services import AnalyticsService


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def analytics_overview(request):
    """
    GET /api/analytics/

    Returns all analytics data for the dashboard.

    Query params:
        period: 'week', 'month', or 'year' (default: 'month')
    """
    period = request.query_params.get('period', 'month')

    if period not in ['week', 'month', 'year']:
        return Response(
            {'error': 'Invalid period. Must be week, month, or year.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    data = AnalyticsService.get_full_analytics(period)
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def key_metrics(request):
    """
    GET /api/analytics/metrics/

    Returns key metrics (total trips, active users, fleet utilization, avg duration).

    Query params:
        period: 'week', 'month', or 'year' (default: 'month')
    """
    period = request.query_params.get('period', 'month')

    if period not in ['week', 'month', 'year']:
        return Response(
            {'error': 'Invalid period. Must be week, month, or year.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    data = AnalyticsService.get_key_metrics(period)
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def trip_analytics(request):
    """
    GET /api/analytics/trips/

    Returns trip analytics grouped by day of week.

    Query params:
        period: 'week', 'month', or 'year' (default: 'month')
    """
    period = request.query_params.get('period', 'month')

    if period not in ['week', 'month', 'year']:
        return Response(
            {'error': 'Invalid period. Must be week, month, or year.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    data = AnalyticsService.get_trip_analytics(period)
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def bus_performance(request):
    """
    GET /api/analytics/buses/

    Returns top performing buses.

    Query params:
        period: 'week', 'month', or 'year' (default: 'month')
        limit: number of buses to return (default: 5)
    """
    period = request.query_params.get('period', 'month')
    limit = request.query_params.get('limit', 5)

    try:
        limit = int(limit)
    except ValueError:
        limit = 5

    if period not in ['week', 'month', 'year']:
        return Response(
            {'error': 'Invalid period. Must be week, month, or year.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    data = AnalyticsService.get_bus_performance(period, limit)
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def attendance_stats(request):
    """
    GET /api/analytics/attendance/

    Returns attendance statistics.

    Query params:
        period: 'week', 'month', or 'year' (default: 'month')
    """
    period = request.query_params.get('period', 'month')

    if period not in ['week', 'month', 'year']:
        return Response(
            {'error': 'Invalid period. Must be week, month, or year.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    data = AnalyticsService.get_attendance_stats(period)
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def route_efficiency(request):
    """
    GET /api/analytics/routes/

    Returns route efficiency metrics.

    Query params:
        period: 'week', 'month', or 'year' (default: 'month')
    """
    period = request.query_params.get('period', 'month')

    if period not in ['week', 'month', 'year']:
        return Response(
            {'error': 'Invalid period. Must be week, month, or year.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    data = AnalyticsService.get_route_efficiency(period)
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def safety_alerts(request):
    """
    GET /api/analytics/safety/

    Returns safety and alerts statistics.

    Query params:
        period: 'week', 'month', or 'year' (default: 'month')
    """
    period = request.query_params.get('period', 'month')

    if period not in ['week', 'month', 'year']:
        return Response(
            {'error': 'Invalid period. Must be week, month, or year.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    data = AnalyticsService.get_safety_alerts(period)
    return Response(data)
