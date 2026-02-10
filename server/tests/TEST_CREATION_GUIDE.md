# Test Creation Guide for Missing Coverage

This guide provides templates and examples for creating the missing tests identified in the comprehensive coverage analysis.

---

## Quick Reference: What Needs Tests

### Priority 1: Analytics Module (0% coverage)
- **Files to create:**
  - `tests/test_analytics_services.py` (~25-30 tests)
  - `tests/test_analytics_views.py` (~15-20 tests)
- **Estimated time:** 2-3 days

### Priority 2: Admin Module (~40% coverage)
- **Files to create:**
  - `tests/test_admins_views.py` (~35-40 tests)
- **Estimated time:** 2 days

### Priority 3: API Endpoints (~60% coverage)
- **Files to enhance:** All existing test files
- **Tests to add:** ~50-60 endpoint tests
- **Estimated time:** 3-4 days

---

## Template: Analytics Service Tests

### File: `tests/test_analytics_services.py`

```python
"""
Tests for analytics/services.py
"""
from django.test import TestCase
from django.utils import timezone
from datetime import timedelta

from analytics.services import AnalyticsService
from trips.models import Trip
from buses.models import Bus
from users.models import User
from drivers.models import Driver

# NOTE: These tests attempted in Ralph Loop but had structure issues
# The analytics service returns nested dictionaries, not flat values
# Need to inspect actual return structure before writing assertions


class DateRangeCalculationTests(TestCase):
    """Test date range utility methods"""

    def test_get_date_range_week(self):
        """Test getting last 7 days"""
        start, end = AnalyticsService.get_date_range('week')
        expected_days = 7
        actual_days = (end - start).days
        self.assertEqual(actual_days, expected_days)

    def test_get_date_range_month(self):
        """Test getting last 30 days"""
        start, end = AnalyticsService.get_date_range('month')
        self.assertEqual((end - start).days, 30)

    def test_get_date_range_year(self):
        """Test getting last 365 days"""
        start, end = AnalyticsService.get_date_range('year')
        self.assertEqual((end - start).days, 365)

    def test_get_date_range_invalid_defaults_to_month(self):
        """Test invalid period defaults to month"""
        start, end = AnalyticsService.get_date_range('invalid')
        self.assertEqual((end - start).days, 30)


class PercentageChangeTests(TestCase):
    """Test percentage change calculations"""

    def test_percentage_increase(self):
        """Test calculating percentage increase"""
        result = AnalyticsService.calculate_percentage_change(150, 100)
        self.assertEqual(result, 50.0)

    def test_percentage_decrease(self):
        """Test calculating percentage decrease"""
        result = AnalyticsService.calculate_percentage_change(75, 100)
        self.assertEqual(result, -25.0)

    def test_percentage_from_zero(self):
        """Test percentage change when previous is zero"""
        result = AnalyticsService.calculate_percentage_change(100, 0)
        self.assertEqual(result, 100.0)

    def test_percentage_both_zero(self):
        """Test percentage change when both values are zero"""
        result = AnalyticsService.calculate_percentage_change(0, 0)
        self.assertEqual(result, 0.0)


class KeyMetricsStructureTests(TestCase):
    """Test key metrics return structure"""

    def setUp(self):
        """Create minimal test data"""
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

    def test_get_key_metrics_returns_dict(self):
        """Test that get_key_metrics returns a dictionary"""
        metrics = AnalyticsService.get_key_metrics('week')
        self.assertIsInstance(metrics, dict)

    def test_get_key_metrics_has_required_keys(self):
        """Test that metrics dict has all required keys"""
        metrics = AnalyticsService.get_key_metrics('week')

        # TODO: Inspect actual structure returned by service
        # Current implementation may return nested dicts
        required_keys = [
            'total_trips',
            'active_users',
            'fleet_utilization'
        ]

        for key in required_keys:
            self.assertIn(key, metrics, f"Missing key: {key}")

# TODO: Add more test classes:
# - TripAnalyticsTests
# - BusPerformanceTests
# - AttendanceStatsTests
# - RouteEfficiencyTests
# - SafetyAlertsTests
```

---

## Template: Analytics View Tests

### File: `tests/test_analytics_views.py`

```python
"""
Tests for analytics/views.py
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

from users.models import User


class AnalyticsAuthenticationTests(TestCase):
    """Test authentication requirements"""

    def setUp(self):
        self.client = APIClient()

    def test_analytics_overview_requires_auth(self):
        """Test that analytics overview requires authentication"""
        response = self.client.get('/api/analytics/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_key_metrics_requires_auth(self):
        """Test that key metrics requires authentication"""
        response = self.client.get('/api/analytics/metrics/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    # TODO: Add tests for all 7 endpoints


class KeyMetricsViewTests(TestCase):
    """Test key_metrics view"""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123',
            user_type='admin'
        )
        self.client.force_authenticate(user=self.user)

    def test_key_metrics_default_period(self):
        """Test metrics with default period"""
        response = self.client.get('/api/analytics/metrics/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_key_metrics_week_period(self):
        """Test metrics with week period"""
        response = self.client.get('/api/analytics/metrics/?period=week')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_key_metrics_invalid_period(self):
        """Test metrics with invalid period returns 400"""
        response = self.client.get('/api/analytics/metrics/?period=invalid')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.json())


# TODO: Add test classes for all 7 endpoints
```

---

## Template: Admin View Tests

### File: `tests/test_admins_views.py`

```python
"""
Tests for admins/views.py
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

from users.models import User
from admins.models import Admin


class AdminRegistrationTests(TestCase):
    """Test admin registration endpoint"""

    def setUp(self):
        self.client = APIClient()

    def test_admin_register_success(self):
        """Test successful admin registration"""
        data = {
            'username': 'newadmin',
            'password': 'secure_password_123',
            'first_name': 'Admin',
            'last_name': 'User'
        }
        response = self.client.post('/api/admins/register/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('tokens', response.json())
        self.assertIn('user', response.json())

    def test_admin_register_creates_user_and_profile(self):
        """Test that registration creates both User and Admin"""
        data = {
            'username': 'newadmin',
            'password': 'secure_password_123',
            'first_name': 'Admin',
            'last_name': 'User'
        }
        response = self.client.post('/api/admins/register/', data)

        # Verify User created
        user = User.objects.get(username='newadmin')
        self.assertEqual(user.user_type, 'admin')

        # Verify Admin profile created
        admin = Admin.objects.get(user=user)
        self.assertIsNotNone(admin)

    def test_admin_register_missing_fields(self):
        """Test registration with missing required fields"""
        data = {'username': 'incomplete'}
        response = self.client.post('/api/admins/register/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class AdminAddParentTests(TestCase):
    """Test bulk parent+children creation"""

    def setUp(self):
        self.client = APIClient()
        self.admin_user = User.objects.create_user(
            username='admin',
            password='pass',
            user_type='admin'
        )
        self.client.force_authenticate(user=self.admin_user)

    def test_add_parent_with_children(self):
        """Test creating parent with multiple children"""
        data = {
            'first_name': 'Parent',
            'last_name': 'Smith',
            'children': [
                {
                    'first_name': 'Child1',
                    'last_name': 'Smith',
                    'class_grade': '1'
                },
                {
                    'first_name': 'Child2',
                    'last_name': 'Smith',
                    'class_grade': '2'
                }
            ]
        }
        response = self.client.post('/api/admins/add-parent/', data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        result = response.json()
        self.assertIn('parent', result)
        self.assertIn('children', result)
        self.assertEqual(len(result['children']), 2)

    def test_add_parent_auto_generates_credentials(self):
        """Test that credentials are auto-generated"""
        data = {
            'first_name': 'Parent',
            'last_name': 'Doe',
            'children': []
        }
        response = self.client.post('/api/admins/add-parent/', data, format='json')

        result = response.json()
        parent = result['parent']
        self.assertIn('username', parent)
        self.assertIn('password', parent)
        self.assertTrue(parent['username'].startswith('parent_'))
        self.assertEqual(len(parent['password']), 12)  # Auto-generated password


# TODO: Add more test classes:
# - AdminAddDriverTests
# - AdminAddBusminderTests
# - DashboardStatsTests
# - AdminAssignmentTests
```

---

## Test Data Creation Patterns

### Using Existing Helpers

```python
from tests.helpers import create_sample_data

def setUp(self):
    """Use helper to create common test data"""
    self.data = create_sample_data()
    self.bus = self.data['bus']
    self.driver = self.data['driver_profile']
    self.child1 = self.data['child1']
```

### Using Factories

```python
from tests.factories import BusFactory, ChildFactory, ParentFactory

def test_with_factory_data(self):
    """Use factories for quick test data creation"""
    bus = BusFactory(capacity=10)
    parent = ParentFactory()
    child = ChildFactory(parent=parent, assigned_bus=bus)
```

---

## Common Test Patterns

### Testing ViewSet CRUD Operations

```python
class BusViewSetTests(TestCase):
    """Test Bus ViewSet CRUD operations"""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='admin', user_type='admin')
        self.client.force_authenticate(user=self.user)

    def test_list_buses(self):
        """Test GET /api/buses/"""
        response = self.client.get('/api/buses/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_create_bus(self):
        """Test POST /api/buses/"""
        data = {
            'bus_number': 'B999',
            'number_plate': 'TEST-999',
            'capacity': 20
        }
        response = self.client.post('/api/buses/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_retrieve_bus(self):
        """Test GET /api/buses/{id}/"""
        bus = Bus.objects.create(bus_number='B1', number_plate='P1', capacity=10)
        response = self.client.get(f'/api/buses/{bus.id}/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_update_bus(self):
        """Test PUT /api/buses/{id}/"""
        bus = Bus.objects.create(bus_number='B1', number_plate='P1', capacity=10)
        data = {'bus_number': 'B1', 'number_plate': 'P1-NEW', 'capacity': 15}
        response = self.client.put(f'/api/buses/{bus.id}/', data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_delete_bus(self):
        """Test DELETE /api/buses/{id}/"""
        bus = Bus.objects.create(bus_number='B1', number_plate='P1', capacity=10)
        response = self.client.delete(f'/api/buses/{bus.id}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
```

### Testing Custom Actions

```python
class BusViewSetCustomActionsTests(TestCase):
    """Test Bus ViewSet custom actions"""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='admin', user_type='admin')
        self.client.force_authenticate(user=self.user)
        self.bus = Bus.objects.create(bus_number='B1', number_plate='P1', capacity=10)

    def test_assign_driver_action(self):
        """Test POST /api/buses/{id}/assign-driver/"""
        driver_user = User.objects.create_user(username='driver', user_type='driver')
        driver = Driver.objects.create(user=driver_user, license_number='D123')

        data = {'driver_id': driver.id}
        response = self.client.post(f'/api/buses/{self.bus.id}/assign-driver/', data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_get_children_action(self):
        """Test GET /api/buses/{id}/children/"""
        response = self.client.get(f'/api/buses/{self.bus.id}/children/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
```

### Testing Permissions

```python
class BusPermissionTests(TestCase):
    """Test Bus ViewSet permissions"""

    def setUp(self):
        self.client = APIClient()

    def test_list_buses_requires_authentication(self):
        """Test that unauthenticated users cannot list buses"""
        response = self.client.get('/api/buses/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_parent_cannot_create_bus(self):
        """Test that parents cannot create buses"""
        parent_user = User.objects.create_user(username='parent', user_type='parent')
        self.client.force_authenticate(user=parent_user)

        data = {'bus_number': 'B1', 'number_plate': 'P1', 'capacity': 10}
        response = self.client.post('/api/buses/', data)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_can_create_bus(self):
        """Test that admins can create buses"""
        admin_user = User.objects.create_user(username='admin', user_type='admin')
        self.client.force_authenticate(user=admin_user)

        data = {'bus_number': 'B1', 'number_plate': 'P1', 'capacity': 10}
        response = self.client.post('/api/buses/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
```

### Testing Query Parameters

```python
class TripFilteringTests(TestCase):
    """Test trip filtering via query parameters"""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='admin', user_type='admin')
        self.client.force_authenticate(user=self.user)

        # Create test trips
        self.bus1 = Bus.objects.create(bus_number='B1', number_plate='P1', capacity=10)
        self.bus2 = Bus.objects.create(bus_number='B2', number_plate='P2', capacity=10)

        Trip.objects.create(bus=self.bus1, status='scheduled')
        Trip.objects.create(bus=self.bus1, status='in_progress')
        Trip.objects.create(bus=self.bus2, status='completed')

    def test_filter_by_status(self):
        """Test filtering trips by status"""
        response = self.client.get('/api/trips/?status=scheduled')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 1)

    def test_filter_by_bus(self):
        """Test filtering trips by bus"""
        response = self.client.get(f'/api/trips/?bus_id={self.bus1.id}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 2)

    def test_multiple_filters(self):
        """Test using multiple query parameters"""
        response = self.client.get(
            f'/api/trips/?bus_id={self.bus1.id}&status=in_progress'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 1)
```

---

## Tips for Writing Good Tests

### 1. Test Names Should Be Descriptive
```python
# Good
def test_parent_can_view_own_children_only(self):

# Bad
def test_children(self):
```

### 2. One Assertion Focus Per Test
```python
# Good
def test_create_bus_returns_201(self):
    response = self.client.post('/api/buses/', data)
    self.assertEqual(response.status_code, status.HTTP_201_CREATED)

def test_create_bus_returns_bus_data(self):
    response = self.client.post('/api/buses/', data)
    self.assertIn('bus_number', response.json())

# Bad (multiple unrelated assertions)
def test_create_bus(self):
    response = self.client.post('/api/buses/', data)
    self.assertEqual(response.status_code, status.HTTP_201_CREATED)
    self.assertIn('bus_number', response.json())
    self.assertTrue(Bus.objects.filter(bus_number='B1').exists())
    self.assertEqual(len(mail.outbox), 1)  # Too many concerns
```

### 3. Use setUp() for Common Data
```python
class MyTests(TestCase):
    def setUp(self):
        """Create data used by all tests"""
        self.client = APIClient()
        self.user = User.objects.create_user(username='test')
        self.client.force_authenticate(user=self.user)

    def test_something(self):
        # Can use self.client and self.user
        pass
```

### 4. Test Both Success and Failure Paths
```python
def test_create_bus_success(self):
    """Test creating bus with valid data"""
    # ... success case

def test_create_bus_missing_required_field(self):
    """Test creating bus without required field fails"""
    # ... failure case

def test_create_bus_duplicate_number_plate(self):
    """Test creating bus with duplicate plate fails"""
    # ... failure case
```

---

## Running Tests

### Run All Tests
```bash
python manage.py test --settings=apo_basi.test_settings
```

### Run Specific Test File
```bash
python manage.py test tests.test_analytics_views --settings=apo_basi.test_settings
```

### Run Specific Test Class
```bash
python manage.py test tests.test_analytics_views.KeyMetricsViewTests --settings=apo_basi.test_settings
```

### Run Specific Test Method
```bash
python manage.py test tests.test_analytics_views.KeyMetricsViewTests.test_key_metrics_default_period --settings=apo_basi.test_settings
```

### Run with Verbose Output
```bash
python manage.py test --verbosity=2 --settings=apo_basi.test_settings
```

---

## Next Steps

1. **Start with Analytics** (highest priority, 0% coverage)
   - Create `tests/test_analytics_services.py`
   - Create `tests/test_analytics_views.py`
   - Run tests: `python manage.py test tests.test_analytics_* --settings=apo_basi.test_settings`

2. **Move to Admin Tests** (high priority, ~40% coverage)
   - Create `tests/test_admins_views.py`
   - Test credential generation thoroughly
   - Test bulk operations

3. **Add API Endpoint Tests** (medium priority)
   - Enhance existing test files with endpoint tests
   - Focus on query parameters and permissions

4. **Verify Coverage Improvement**
   - Run: `coverage run --source='.' manage.py test --settings=apo_basi.test_settings`
   - Report: `coverage report`
   - HTML: `coverage html`

---

**Last Updated:** 2026-01-22
**Current Test Count:** 265 (all passing)
**Target:** 350-400 tests for 90% coverage
