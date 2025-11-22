"""
Analytics service layer for business logic and complex calculations.

All analytics computations are performed here, views only handle HTTP responses.
"""

from django.db.models import Count, Avg, Q, F, Sum
from django.db.models.functions import TruncDate, ExtractWeekDay
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal

from trips.models import Trip
from attendance.models import Attendance
from buses.models import Bus
from children.models import Child
from users.models import User
from parents.models import Parent
from assignments.models import Assignment


class AnalyticsService:
    """Service class for analytics calculations"""

    @staticmethod
    def get_date_range(period: str):
        """
        Get date range based on period selection.

        Args:
            period: 'week', 'month', or 'year'

        Returns:
            Tuple of (start_date, end_date)
        """
        today = timezone.now().date()

        if period == 'week':
            start_date = today - timedelta(days=7)
        elif period == 'month':
            start_date = today - timedelta(days=30)
        elif period == 'year':
            start_date = today - timedelta(days=365)
        else:
            start_date = today - timedelta(days=30)  # Default to month

        return start_date, today

    @staticmethod
    def get_previous_period_range(period: str):
        """Get the previous period's date range for comparison."""
        today = timezone.now().date()

        if period == 'week':
            days = 7
        elif period == 'month':
            days = 30
        elif period == 'year':
            days = 365
        else:
            days = 30

        end_date = today - timedelta(days=days)
        start_date = end_date - timedelta(days=days)

        return start_date, end_date

    @staticmethod
    def calculate_percentage_change(current: int, previous: int) -> float:
        """Calculate percentage change between two values."""
        if previous == 0:
            return 100.0 if current > 0 else 0.0
        return round(((current - previous) / previous) * 100, 1)

    @classmethod
    def get_key_metrics(cls, period: str = 'month') -> dict:
        """
        Calculate key metrics for the analytics dashboard.

        Returns metrics for:
        - Total trips
        - Active users (parents with recent activity)
        - Fleet utilization
        - Average trip duration
        """
        start_date, end_date = cls.get_date_range(period)
        prev_start, prev_end = cls.get_previous_period_range(period)

        # Total Trips
        current_trips = Trip.objects.filter(
            scheduled_time__date__gte=start_date,
            scheduled_time__date__lte=end_date
        ).count()

        previous_trips = Trip.objects.filter(
            scheduled_time__date__gte=prev_start,
            scheduled_time__date__lte=prev_end
        ).count()

        trips_change = cls.calculate_percentage_change(current_trips, previous_trips)

        # Active Users (parents who have children with attendance records)
        current_active_users = Parent.objects.filter(
            parent_children__attendance_records__date__gte=start_date,
            parent_children__attendance_records__date__lte=end_date
        ).distinct().count()

        previous_active_users = Parent.objects.filter(
            parent_children__attendance_records__date__gte=prev_start,
            parent_children__attendance_records__date__lte=prev_end
        ).distinct().count()

        users_change = cls.calculate_percentage_change(current_active_users, previous_active_users)

        # Fleet Utilization
        total_buses = Bus.objects.count()
        active_buses = Bus.objects.filter(is_active=True).count()

        # Also consider buses that had trips in the period
        buses_with_trips = Trip.objects.filter(
            scheduled_time__date__gte=start_date,
            scheduled_time__date__lte=end_date
        ).values('bus').distinct().count()

        # Calculate utilization as percentage of buses used
        if total_buses > 0:
            fleet_utilization = round((max(active_buses, buses_with_trips) / total_buses) * 100)
        else:
            fleet_utilization = 0

        # Previous period fleet utilization
        prev_buses_with_trips = Trip.objects.filter(
            scheduled_time__date__gte=prev_start,
            scheduled_time__date__lte=prev_end
        ).values('bus').distinct().count()

        if total_buses > 0:
            prev_fleet_utilization = round((prev_buses_with_trips / total_buses) * 100)
        else:
            prev_fleet_utilization = 0

        fleet_change = cls.calculate_percentage_change(fleet_utilization, prev_fleet_utilization)

        # Average Trip Duration (in minutes)
        completed_trips = Trip.objects.filter(
            scheduled_time__date__gte=start_date,
            scheduled_time__date__lte=end_date,
            status='completed',
            start_time__isnull=False,
            end_time__isnull=False
        )

        total_duration = 0
        trip_count = 0

        for trip in completed_trips:
            if trip.start_time and trip.end_time:
                duration = (trip.end_time - trip.start_time).total_seconds() / 60
                if duration > 0:
                    total_duration += duration
                    trip_count += 1

        avg_duration = round(total_duration / trip_count) if trip_count > 0 else 0

        # Previous period average duration
        prev_completed_trips = Trip.objects.filter(
            scheduled_time__date__gte=prev_start,
            scheduled_time__date__lte=prev_end,
            status='completed',
            start_time__isnull=False,
            end_time__isnull=False
        )

        prev_total_duration = 0
        prev_trip_count = 0

        for trip in prev_completed_trips:
            if trip.start_time and trip.end_time:
                duration = (trip.end_time - trip.start_time).total_seconds() / 60
                if duration > 0:
                    prev_total_duration += duration
                    prev_trip_count += 1

        prev_avg_duration = round(prev_total_duration / prev_trip_count) if prev_trip_count > 0 else 0
        duration_change = cls.calculate_percentage_change(avg_duration, prev_avg_duration)
        # Negative change is good for duration (faster trips)
        duration_change = -duration_change if avg_duration < prev_avg_duration else duration_change

        return {
            'total_trips': {
                'value': current_trips,
                'change': trips_change,
                'change_label': f'vs last {period}'
            },
            'active_users': {
                'value': current_active_users,
                'change': users_change,
                'change_label': f'vs last {period}'
            },
            'fleet_utilization': {
                'value': fleet_utilization,
                'change': fleet_change,
                'change_label': f'vs last {period}'
            },
            'avg_trip_duration': {
                'value': avg_duration,
                'change': duration_change,
                'change_label': f'vs last {period}'
            }
        }

    @classmethod
    def get_trip_analytics(cls, period: str = 'month') -> list:
        """
        Get trip analytics grouped by day of week.

        Returns completed, cancelled, and delayed trip counts per day.
        """
        start_date, end_date = cls.get_date_range(period)

        # Get trips in the period
        trips = Trip.objects.filter(
            scheduled_time__date__gte=start_date,
            scheduled_time__date__lte=end_date
        )

        # Group by day of week
        day_names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        analytics = []

        for day_num, day_name in enumerate(day_names):
            # Django's ExtractWeekDay: 1=Sunday, 2=Monday, ..., 7=Saturday
            # We want: 0=Monday, 1=Tuesday, ..., 6=Sunday
            django_day = (day_num + 2) % 7 or 7  # Convert to Django's weekday numbering

            day_trips = trips.filter(scheduled_time__week_day=django_day)

            completed = day_trips.filter(status='completed').count()
            cancelled = day_trips.filter(status='cancelled').count()

            # Delayed = trips where actual start was > 15 minutes after scheduled
            delayed = 0
            for trip in day_trips.filter(status__in=['completed', 'in-progress']):
                if trip.start_time and trip.scheduled_time:
                    if trip.start_time > trip.scheduled_time + timedelta(minutes=15):
                        delayed += 1

            analytics.append({
                'day': day_name,
                'completed': completed,
                'cancelled': cancelled,
                'delayed': delayed
            })

        return analytics

    @classmethod
    def get_bus_performance(cls, period: str = 'month', limit: int = 5) -> list:
        """
        Get top performing buses based on trip count and on-time percentage.
        """
        start_date, end_date = cls.get_date_range(period)

        buses = Bus.objects.all()
        performance_data = []

        for bus in buses:
            # Get trips for this bus in the period
            bus_trips = Trip.objects.filter(
                bus=bus,
                scheduled_time__date__gte=start_date,
                scheduled_time__date__lte=end_date
            )

            total_trips = bus_trips.count()
            if total_trips == 0:
                continue

            completed_trips = bus_trips.filter(status='completed')
            completed_count = completed_trips.count()

            # Calculate on-time percentage
            on_time_count = 0
            for trip in completed_trips:
                if trip.start_time and trip.scheduled_time:
                    # On time if started within 15 minutes of scheduled
                    if trip.start_time <= trip.scheduled_time + timedelta(minutes=15):
                        on_time_count += 1

            on_time_percent = round((on_time_count / completed_count * 100)) if completed_count > 0 else 0

            # Rating based on on-time performance (simplified)
            if on_time_percent >= 95:
                rating = 4.8
            elif on_time_percent >= 90:
                rating = 4.6
            elif on_time_percent >= 85:
                rating = 4.4
            elif on_time_percent >= 80:
                rating = 4.2
            else:
                rating = 4.0

            performance_data.append({
                'bus_id': bus.id,
                'bus_number': bus.bus_number,
                'trips': total_trips,
                'on_time': on_time_percent,
                'rating': rating
            })

        # Sort by trips (descending) and return top performers
        performance_data.sort(key=lambda x: x['trips'], reverse=True)
        return performance_data[:limit]

    @classmethod
    def get_attendance_stats(cls, period: str = 'month') -> dict:
        """
        Get attendance statistics for the period.
        """
        start_date, end_date = cls.get_date_range(period)
        today = timezone.now().date()

        # Today's attendance
        today_attendance = Attendance.objects.filter(date=today)

        present_today = today_attendance.filter(
            status__in=['picked_up', 'dropped_off', 'on_bus', 'at_school', 'on_way_home']
        ).count()

        absent_today = today_attendance.filter(status='absent').count()

        total_children = Child.objects.filter(status='active').count()

        # Calculate attendance rate
        if total_children > 0:
            # If no attendance records yet today, use period average
            if present_today + absent_today == 0:
                period_attendance = Attendance.objects.filter(
                    date__gte=start_date,
                    date__lte=end_date
                )
                period_present = period_attendance.filter(
                    status__in=['picked_up', 'dropped_off', 'on_bus', 'at_school', 'on_way_home']
                ).count()
                period_total = period_attendance.count()

                attendance_rate = round((period_present / period_total * 100), 1) if period_total > 0 else 0
                present_today = round(total_children * attendance_rate / 100)
                absent_today = total_children - present_today
            else:
                total_today = present_today + absent_today
                attendance_rate = round((present_today / total_today * 100), 1) if total_today > 0 else 0
        else:
            attendance_rate = 0

        return {
            'present_today': present_today,
            'absent_today': absent_today,
            'attendance_rate': attendance_rate
        }

    @classmethod
    def get_route_efficiency(cls, period: str = 'month') -> dict:
        """
        Calculate route efficiency metrics.

        Data sources required:
        - avg_distance: Calculated from Trip.stops GPS coordinates (sum of distances between stops)
        - fuel_efficiency: Requires Bus.fuel_consumption field and trip distance tracking
        - cost_per_trip: Requires a Cost/Expense model linked to trips (fuel, maintenance, driver wages)
        """
        start_date, end_date = cls.get_date_range(period)

        completed_trips = Trip.objects.filter(
            scheduled_time__date__gte=start_date,
            scheduled_time__date__lte=end_date,
            status='completed'
        )

        trip_count = completed_trips.count()

        # TODO: Calculate from Trip.stops GPS coordinates (latitude/longitude)
        # Formula: Sum of haversine distances between consecutive stops
        avg_distance = 0

        # TODO: Requires Bus.fuel_consumption field (L/100km) and tracked distance
        # Formula: total_distance / total_fuel_used
        fuel_efficiency = 0

        # TODO: Requires Cost model with trip_id foreign key
        # Formula: SUM(costs for period) / trip_count
        cost_per_trip = 0

        return {
            'avg_distance': avg_distance,
            'fuel_efficiency': fuel_efficiency,
            'cost_per_trip': cost_per_trip,
            'total_trips': trip_count,
            'data_sources': {
                'avg_distance': 'Trip.stops GPS coordinates',
                'fuel_efficiency': 'Bus.fuel_consumption + trip distance',
                'cost_per_trip': 'Cost model (fuel, maintenance, wages)'
            }
        }

    @classmethod
    def get_safety_alerts(cls, period: str = 'month') -> dict:
        """
        Get safety and alerts statistics.
        """
        start_date, end_date = cls.get_date_range(period)
        today = timezone.now().date()

        # Active alerts - trips that are delayed or have issues
        active_alerts = Trip.objects.filter(
            scheduled_time__date=today,
            status='in-progress'
        ).count()

        # Check for delayed trips today
        delayed_today = 0
        in_progress_trips = Trip.objects.filter(
            scheduled_time__date=today,
            status='in-progress'
        )
        for trip in in_progress_trips:
            if trip.start_time and trip.scheduled_time:
                if trip.start_time > trip.scheduled_time + timedelta(minutes=15):
                    delayed_today += 1

        active_alerts = delayed_today

        # Resolved today - completed trips
        resolved_today = Trip.objects.filter(
            scheduled_time__date=today,
            status='completed'
        ).count()

        # Safety score based on completion rate
        total_today = Trip.objects.filter(scheduled_time__date=today).count()
        cancelled_today = Trip.objects.filter(
            scheduled_time__date=today,
            status='cancelled'
        ).count()

        if total_today > 0:
            safety_score = round(((total_today - cancelled_today - delayed_today) / total_today) * 100, 1)
        else:
            # Use period average if no trips today
            period_trips = Trip.objects.filter(
                scheduled_time__date__gte=start_date,
                scheduled_time__date__lte=end_date
            )
            period_total = period_trips.count()
            period_cancelled = period_trips.filter(status='cancelled').count()

            if period_total > 0:
                safety_score = round(((period_total - period_cancelled) / period_total) * 100, 1)
            else:
                safety_score = 100.0

        return {
            'active_alerts': active_alerts,
            'resolved_today': resolved_today,
            'safety_score': safety_score
        }

    @classmethod
    def get_full_analytics(cls, period: str = 'month') -> dict:
        """
        Get all analytics data in a single call.
        """
        return {
            'metrics': cls.get_key_metrics(period),
            'trip_analytics': cls.get_trip_analytics(period),
            'bus_performance': cls.get_bus_performance(period),
            'attendance': cls.get_attendance_stats(period),
            'route_efficiency': cls.get_route_efficiency(period),
            'safety': cls.get_safety_alerts(period)
        }
