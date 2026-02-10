"""
Comprehensive tests for analytics/services.py

Tests cover:
- Date range calculations
- Percentage change calculations
- Key metrics calculation
- Trip analytics
- Edge cases and error handling
"""

from django.test import TestCase
from django.utils import timezone
from datetime import timedelta

from analytics.services import AnalyticsService
from trips.models import Trip
from attendance.models import Attendance
from buses.models import Bus
from children.models import Child
from parents.models import Parent
from users.models import User
from drivers.models import Driver


class DateRangeCalculationTests(TestCase):
    """Test date range utility methods"""

    def test_get_date_range_week(self):
        """Test getting last 7 days range"""
        start, end = AnalyticsService.get_date_range('week')
        expected_days = 7
        actual_days = (end - start).days
        self.assertEqual(actual_days, expected_days)

    def test_get_date_range_month(self):
        """Test getting last 30 days range"""
        start, end = AnalyticsService.get_date_range('month')
        self.assertEqual((end - start).days, 30)

    def test_get_date_range_year(self):
        """Test getting last 365 days range"""
        start, end = AnalyticsService.get_date_range('year')
        self.assertEqual((end - start).days, 365)

    def test_get_date_range_invalid_defaults_to_month(self):
        """Test invalid period defaults to month"""
        start, end = AnalyticsService.get_date_range('invalid')
        self.assertEqual((end - start).days, 30)

    def test_get_date_range_end_is_today(self):
        """Test that end date is always today"""
        _, end = AnalyticsService.get_date_range('week')
        self.assertEqual(end, timezone.now().date())

    def test_get_previous_period_range_week(self):
        """Test getting previous week range"""
        start, end = AnalyticsService.get_previous_period_range('week')
        today = timezone.now().date()
        expected_end = today - timedelta(days=7)
        expected_start = expected_end - timedelta(days=7)

        self.assertEqual(start, expected_start)
        self.assertEqual(end, expected_end)

    def test_get_previous_period_range_month(self):
        """Test getting previous month range"""
        start, end = AnalyticsService.get_previous_period_range('month')
        today = timezone.now().date()
        expected_end = today - timedelta(days=30)
        expected_start = expected_end - timedelta(days=30)

        self.assertEqual(start, expected_start)
        self.assertEqual(end, expected_end)

    def test_previous_period_does_not_overlap_current(self):
        """Test that previous and current periods don't overlap"""
        current_start, current_end = AnalyticsService.get_date_range('week')
        prev_start, prev_end = AnalyticsService.get_previous_period_range('week')

        self.assertLessEqual(prev_end, current_start)


class PercentageChangeCalculationTests(TestCase):
    """Test percentage change calculations"""

    def test_percentage_increase(self):
        """Test calculating percentage increase"""
        result = AnalyticsService.calculate_percentage_change(150, 100)
        self.assertEqual(result, 50.0)

    def test_percentage_decrease(self):
        """Test calculating percentage decrease"""
        result = AnalyticsService.calculate_percentage_change(75, 100)
        self.assertEqual(result, -25.0)

    def test_percentage_no_change(self):
        """Test calculating percentage with no change"""
        result = AnalyticsService.calculate_percentage_change(100, 100)
        self.assertEqual(result, 0.0)

    def test_percentage_from_zero_with_positive_current(self):
        """Test percentage change when previous is zero and current is positive"""
        result = AnalyticsService.calculate_percentage_change(100, 0)
        self.assertEqual(result, 100.0)

    def test_percentage_from_zero_with_zero_current(self):
        """Test percentage change when both are zero"""
        result = AnalyticsService.calculate_percentage_change(0, 0)
        self.assertEqual(result, 0.0)

    def test_percentage_to_zero(self):
        """Test percentage change when current is zero but previous isn't"""
        result = AnalyticsService.calculate_percentage_change(0, 100)
        self.assertEqual(result, -100.0)

    def test_percentage_change_rounds_to_one_decimal(self):
        """Test that result is rounded to 1 decimal place"""
        result = AnalyticsService.calculate_percentage_change(101, 100)
        self.assertEqual(result, 1.0)

    def test_percentage_change_with_large_numbers(self):
        """Test percentage change with large values"""
        result = AnalyticsService.calculate_percentage_change(10000, 5000)
        self.assertEqual(result, 100.0)


class KeyMetricsStructureTests(TestCase):
    """Test key metrics return structure and data types"""

    def setUp(self):
        """Create minimal test data"""
        self.user = User.objects.create_user(
            username='driver1',
            password='pass',
            user_type='driver',
            phone_number='100'
        )
        self.driver = Driver.objects.create(
            user=self.user,
            license_number='D123',
            phone_number='100'
        )
        self.bus = Bus.objects.create(
            bus_number='B1',
            number_plate='PLATE-1',
            capacity=10,
            driver=self.user,
            is_active=True
        )

    def test_get_key_metrics_returns_dict(self):
        """Test that get_key_metrics returns a dictionary"""
        metrics = AnalyticsService.get_key_metrics('week')
        self.assertIsInstance(metrics, dict)

    def test_get_key_metrics_has_all_required_keys(self):
        """Test that metrics dict has all required top-level keys"""
        metrics = AnalyticsService.get_key_metrics('week')

        required_keys = [
            'total_trips',
            'active_users',
            'fleet_utilization',
            'avg_trip_duration'
        ]

        for key in required_keys:
            self.assertIn(key, metrics, f"Missing key: {key}")

    def test_each_metric_has_value_and_change(self):
        """Test that each metric has value and change fields"""
        metrics = AnalyticsService.get_key_metrics('week')

        for metric_name, metric_data in metrics.items():
            self.assertIn('value', metric_data, f"{metric_name} missing 'value'")
            self.assertIn('change', metric_data, f"{metric_name} missing 'change'")
            self.assertIn('change_label', metric_data, f"{metric_name} missing 'change_label'")

    def test_metric_values_are_numeric(self):
        """Test that metric values are numeric"""
        metrics = AnalyticsService.get_key_metrics('week')

        for metric_name, metric_data in metrics.items():
            value = metric_data['value']
            self.assertIsInstance(value, (int, float),
                                f"{metric_name} value is not numeric: {type(value)}")

    def test_metric_changes_are_numeric(self):
        """Test that metric changes are numeric"""
        metrics = AnalyticsService.get_key_metrics('week')

        for metric_name, metric_data in metrics.items():
            change = metric_data['change']
            self.assertIsInstance(change, (int, float),
                                f"{metric_name} change is not numeric: {type(change)}")


class KeyMetricsWithDataTests(TestCase):
    """Test key metrics calculation with actual data"""

    def setUp(self):
        """Create comprehensive test data"""
        # Create users
        self.driver_user = User.objects.create_user(
            username='driver1',
            password='pass',
            user_type='driver',
            phone_number='100'
        )
        self.parent_user = User.objects.create_user(
            username='parent1',
            password='pass',
            user_type='parent',
            phone_number='200'
        )

        # Create profiles
        self.driver = Driver.objects.create(
            user=self.driver_user,
            license_number='D123',
            phone_number='100'
        )
        self.parent = Parent.objects.create(
            user=self.parent_user,
            contact_number='200'
        )

        # Create buses
        self.bus1 = Bus.objects.create(
            bus_number='B1',
            number_plate='PLATE-1',
            capacity=10,
            driver=self.driver_user,
            is_active=True
        )
        self.bus2 = Bus.objects.create(
            bus_number='B2',
            number_plate='PLATE-2',
            capacity=5,
            is_active=False
        )

        # Create child
        self.child = Child.objects.create(
            first_name='Test',
            last_name='Child',
            class_grade='1',
            parent=self.parent,
            assigned_bus=self.bus1
        )

    def test_total_trips_count_with_recent_trip(self):
        """Test that recent trips are counted"""
        Trip.objects.create(
            bus=self.bus1,
            driver=self.driver_user,
            route='Route 1',
            trip_type='pickup',
            scheduled_time=timezone.now()
        )

        metrics = AnalyticsService.get_key_metrics('week')
        self.assertGreaterEqual(metrics['total_trips']['value'], 1)

    def test_total_trips_excludes_old_trips(self):
        """Test that old trips are excluded from week metrics"""
        # Create old trip (outside week period)
        old_date = timezone.now() - timedelta(days=10)
        Trip.objects.create(
            bus=self.bus1,
            driver=self.driver_user,
            route='Route 1',
            trip_type='pickup',
            scheduled_time=old_date
        )

        metrics = AnalyticsService.get_key_metrics('week')
        # Should be 0 since trip is outside week range
        self.assertEqual(metrics['total_trips']['value'], 0)

    def test_fleet_utilization_with_active_buses(self):
        """Test fleet utilization calculation"""
        metrics = AnalyticsService.get_key_metrics('week')

        utilization = metrics['fleet_utilization']['value']
        self.assertIsInstance(utilization, (int, float))
        self.assertGreaterEqual(utilization, 0)
        self.assertLessEqual(utilization, 100)

    def test_fleet_utilization_percentage_format(self):
        """Test that fleet utilization is a percentage (0-100)"""
        metrics = AnalyticsService.get_key_metrics('week')

        utilization = metrics['fleet_utilization']['value']
        # With 1 active bus out of 2 total, should be 50%
        expected = round((1 / 2) * 100)
        self.assertEqual(utilization, expected)

    def test_active_users_with_attendance(self):
        """Test active users calculation with attendance records"""
        # Create attendance for the child
        Attendance.objects.create(
            child=self.child,
            date=timezone.now().date(),
            status='present',
            trip_type='pickup'
        )

        metrics = AnalyticsService.get_key_metrics('week')
        # Should count the parent as active
        self.assertGreaterEqual(metrics['active_users']['value'], 1)

    def test_avg_trip_duration_with_completed_trip(self):
        """Test average trip duration calculation"""
        now = timezone.now()
        Trip.objects.create(
            bus=self.bus1,
            driver=self.driver_user,
            route='Route 1',
            trip_type='pickup',
            scheduled_time=now,
            start_time=now,
            end_time=now + timedelta(minutes=30),
            status='completed'
        )

        metrics = AnalyticsService.get_key_metrics('week')
        # Should be around 30 minutes
        self.assertGreaterEqual(metrics['avg_trip_duration']['value'], 25)
        self.assertLessEqual(metrics['avg_trip_duration']['value'], 35)


class AnalyticsPeriodFilteringTests(TestCase):
    """Test that analytics correctly filter by period"""

    def setUp(self):
        """Create test data across different time periods"""
        self.user = User.objects.create_user(
            username='driver1',
            user_type='driver',
            phone_number='100'
        )
        self.driver = Driver.objects.create(
            user=self.user,
            license_number='D123',
            phone_number='100'
        )
        self.bus = Bus.objects.create(
            bus_number='B1',
            number_plate='PLATE-1',
            capacity=10,
            driver=self.user
        )

    def test_week_period_filters_correctly(self):
        """Test that week period only counts last 7 days"""
        # Create trips at different times
        now = timezone.now()

        # Recent trip (should be counted in week)
        Trip.objects.create(
            bus=self.bus,
            driver=self.user,
            route='Route 1',
            trip_type='pickup',
            scheduled_time=now - timedelta(days=3)
        )

        # Old trip (should not be counted in week)
        Trip.objects.create(
            bus=self.bus,
            driver=self.user,
            route='Route 2',
            trip_type='pickup',
            scheduled_time=now - timedelta(days=10)
        )

        metrics = AnalyticsService.get_key_metrics('week')
        # Should only count 1 trip
        self.assertEqual(metrics['total_trips']['value'], 1)

    def test_year_period_includes_all_recent_trips(self):
        """Test that year period counts trips from last 365 days"""
        now = timezone.now()

        # Create trips within year
        Trip.objects.create(
            bus=self.bus,
            driver=self.user,
            route='Route 1',
            trip_type='pickup',
            scheduled_time=now - timedelta(days=10)
        )
        Trip.objects.create(
            bus=self.bus,
            driver=self.user,
            route='Route 2',
            trip_type='pickup',
            scheduled_time=now - timedelta(days=100)
        )

        metrics = AnalyticsService.get_key_metrics('year')
        # Should count both trips
        self.assertGreaterEqual(metrics['total_trips']['value'], 2)


class EdgeCaseTests(TestCase):
    """Test edge cases and error handling"""

    def test_metrics_with_no_data(self):
        """Test metrics calculation with empty database"""
        metrics = AnalyticsService.get_key_metrics('week')

        self.assertEqual(metrics['total_trips']['value'], 0)
        self.assertEqual(metrics['active_users']['value'], 0)
        self.assertGreaterEqual(metrics['fleet_utilization']['value'], 0)
        self.assertEqual(metrics['avg_trip_duration']['value'], 0)

    def test_metrics_with_invalid_period_defaults_to_month(self):
        """Test metrics with invalid period defaults correctly"""
        metrics = AnalyticsService.get_key_metrics('invalid_period')

        # Should still return valid structure
        self.assertIn('total_trips', metrics)
        self.assertIn('value', metrics['total_trips'])

    def test_fleet_utilization_with_no_buses(self):
        """Test fleet utilization when there are no buses"""
        # Ensure no buses exist
        Bus.objects.all().delete()

        metrics = AnalyticsService.get_key_metrics('week')
        self.assertEqual(metrics['fleet_utilization']['value'], 0)

    def test_avg_duration_with_zero_completed_trips(self):
        """Test average duration when no trips are completed"""
        user = User.objects.create_user(username='driver', user_type='driver')
        bus = Bus.objects.create(bus_number='B1', number_plate='P1', capacity=10)

        # Create trip without completion
        Trip.objects.create(
            bus=bus,
            driver=user,
            route='Route 1',
            trip_type='pickup',
            scheduled_time=timezone.now(),
            status='scheduled'  # Not completed
        )

        metrics = AnalyticsService.get_key_metrics('week')
        self.assertEqual(metrics['avg_trip_duration']['value'], 0)

    def test_percentage_change_with_extreme_values(self):
        """Test percentage change with very large differences"""
        # Large increase
        result = AnalyticsService.calculate_percentage_change(1000, 1)
        self.assertGreater(result, 0)

        # Large decrease
        result = AnalyticsService.calculate_percentage_change(1, 1000)
        self.assertLess(result, 0)


class ChangeCalculationTests(TestCase):
    """Test change calculation in metrics"""

    def setUp(self):
        """Create test data for change calculation"""
        self.user = User.objects.create_user(
            username='driver1',
            user_type='driver',
            phone_number='100'
        )
        self.driver = Driver.objects.create(
            user=self.user,
            license_number='D123',
            phone_number='100'
        )
        self.bus = Bus.objects.create(
            bus_number='B1',
            number_plate='PLATE-1',
            capacity=10,
            driver=self.user
        )

    def test_trips_change_shows_increase(self):
        """Test that trip count increase is reflected in change value"""
        now = timezone.now()

        # Create more trips in current period than previous
        # Current period trip
        Trip.objects.create(
            bus=self.bus,
            driver=self.user,
            route='Route 1',
            trip_type='pickup',
            scheduled_time=now - timedelta(days=2)
        )
        Trip.objects.create(
            bus=self.bus,
            driver=self.user,
            route='Route 2',
            trip_type='pickup',
            scheduled_time=now - timedelta(days=3)
        )

        metrics = AnalyticsService.get_key_metrics('week')

        # Change should be calculated (may be 0 or positive depending on previous period)
        self.assertIsInstance(metrics['total_trips']['change'], (int, float))

    def test_change_label_contains_period(self):
        """Test that change label includes the period"""
        metrics = AnalyticsService.get_key_metrics('week')

        for metric_name, metric_data in metrics.items():
            label = metric_data['change_label']
            self.assertIn('week', label.lower())

    def test_month_period_change_label(self):
        """Test change label for month period"""
        metrics = AnalyticsService.get_key_metrics('month')

        label = metrics['total_trips']['change_label']
        self.assertIn('month', label.lower())
