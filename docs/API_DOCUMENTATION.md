# School Bus Parent Tracking App - API Documentation

## Overview
This document outlines the Django REST Framework (DRF) API endpoints required for the parent bus tracking mobile application. The API is designed for minimal data transfer and optimal performance.

## Base Configuration

### Base URL
```
https://your-domain.com/api/v1/
```

### Authentication
- JWT Token-based authentication
- Header: `Authorization: Bearer <token>`

### Response Format
All responses follow this structure:
```json
{
  "success": boolean,
  "data": object|array,
  "message": "string (optional)",
  "errors": ["array of error messages (optional)"],
  "timestamp": "ISO datetime string"
}
```

## API Endpoints

### Authentication Endpoints

#### 1. Login
**POST** `/auth/login/`

**Request Body:**
```json
{
  "email": "parent@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "refresh_token_here",
    "user": {
      "id": 1,
      "name": "John Parent",
      "email": "parent@example.com",
      "role": "parent",
      "phone_number": "+1234567890",
      "profile_image": "https://example.com/images/profile.jpg"
    }
  }
}
```

#### 2. Get User Profile
**GET** `/auth/profile/`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Parent",
    "email": "parent@example.com",
    "role": "parent",
    "phone_number": "+1234567890",
    "profile_image": "https://example.com/images/profile.jpg"
  }
}
```

### Parent Dashboard Endpoints

#### 3. Parent Dashboard (Optimized)
**GET** `/parent/dashboard/`

**Response:**
```json
{
  "success": true,
  "data": {
    "children": [
      {
        "id": 1,
        "name": "Ethan",
        "class": "5A",
        "bus_number": "B001",
        "bus_status": "on_route",
        "attendance": true,
        "pickup_time": "07:30",
        "drop_time": "15:30",
        "parent_id": 1,
        "school_name": "Springfield Elementary",
        "bus_route_id": "RT001",
        "current_location": {
          "latitude": 40.7128,
          "longitude": -74.0060,
          "timestamp": "2024-01-15T08:30:00Z"
        }
      }
    ],
    "notifications_count": 2,
    "active_buses": [
      {
        "id": "BUS001",
        "bus_number": "B001",
        "driver_id": 101,
        "current_position": {
          "latitude": 40.7128,
          "longitude": -74.0060,
          "heading": 45,
          "speed": 25
        },
        "route_progress": 65,
        "estimated_arrival": "08:15",
        "last_updated": "2024-01-15T08:30:00Z",
        "status": "active"
      }
    ],
    "recent_alerts": []
  }
}
```

#### 4. Get Children List
**GET** `/parent/children/`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Ethan",
      "class": "5A",
      "bus_number": "B001",
      "bus_status": "on_route",
      "attendance": true,
      "pickup_time": "07:30",
      "drop_time": "15:30",
      "parent_id": 1,
      "school_name": "Springfield Elementary",
      "bus_route_id": "RT001"
    }
  ]
}
```

### Bus Tracking Endpoints

#### 5. Get Bus Location (Real-time)
**GET** `/buses/{bus_number}/location/`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "BUS001",
    "bus_number": "B001",
    "driver_id": 101,
    "current_position": {
      "latitude": 40.7128,
      "longitude": -74.0060,
      "heading": 45,
      "speed": 25
    },
    "route_progress": 65,
    "estimated_arrival": "08:15",
    "last_updated": "2024-01-15T08:30:00Z",
    "status": "active"
  }
}
```

#### 6. Get Bus Breadcrumb Trail
**GET** `/buses/{bus_number}/trail/`

**Query Parameters:**
- `date` (optional): YYYY-MM-DD format, defaults to today

**Response:**
```json
{
  "success": true,
  "data": {
    "bus_number": "B001",
    "route_id": "RT001",
    "breadcrumb_trail": [
      {
        "latitude": 40.7128,
        "longitude": -74.0060,
        "timestamp": "2024-01-15T08:00:00Z",
        "speed": 20
      },
      {
        "latitude": 40.7130,
        "longitude": -74.0065,
        "timestamp": "2024-01-15T08:01:00Z",
        "speed": 25
      }
    ],
    "date": "2024-01-15"
  }
}
```

### Notification Endpoints

#### 7. Get Notifications
**GET** `/notifications/`

**Query Parameters:**
- `limit`: Number of notifications (default: 20, max: 50)
- `offset`: Pagination offset (default: 0)
- `unread_only`: Boolean to filter unread notifications

**Response:**
```json
{
  "success": true,
  "data": {
    "count": 25,
    "results": [
      {
        "id": "notif_001",
        "type": "bus_delayed",
        "title": "Bus B001 Delayed",
        "message": "Due to traffic, Bus B001 is running 10 minutes late",
        "timestamp": "2024-01-15T08:30:00Z",
        "is_read": false,
        "priority": "medium",
        "related_child_id": 1,
        "related_bus_number": "B001",
        "action_required": false,
        "metadata": {
          "estimated_delay_minutes": 10,
          "new_arrival_time": "08:15"
        }
      }
    ]
  }
}
```

#### 8. Mark Notification as Read
**POST** `/notifications/{notification_id}/read/`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "notif_001",
    "is_read": true
  }
}
```

#### 9. Get Unread Notifications Count
**GET** `/notifications/unread-count/`

**Response:**
```json
{
  "success": true,
  "data": {
    "count": 5
  }
}
```

## Django Model Structure

### Variable Naming Conventions

```python
# models.py

from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    """
    Custom user model for different roles
    """
    ROLE_CHOICES = [
        ('parent', 'Parent'),
        ('driver', 'Driver'),
        ('busminder', 'Bus Minder'),
        ('admin', 'Administrator'),
    ]

    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    phone_number = models.CharField(max_length=15, blank=True)
    profile_image = models.ImageField(upload_to='profiles/', blank=True, null=True)

    # Optimized fields for API responses
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class School(models.Model):
    """
    School information
    """
    name = models.CharField(max_length=200)
    address = models.TextField()
    contact_number = models.CharField(max_length=15)

class Bus(models.Model):
    """
    Bus information with status tracking
    """
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('idle', 'Idle'),
        ('maintenance', 'Under Maintenance'),
        ('offline', 'Offline'),
    ]

    bus_number = models.CharField(max_length=20, unique=True, db_index=True)
    driver = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='driven_buses')
    capacity = models.PositiveIntegerField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='offline')

    # Optimization: Add indexes for frequent queries
    class Meta:
        indexes = [
            models.Index(fields=['bus_number', 'status']),
        ]

class BusRoute(models.Model):
    """
    Bus route configuration
    """
    route_id = models.CharField(max_length=20, unique=True, db_index=True)
    name = models.CharField(max_length=100)
    bus = models.ForeignKey(Bus, on_delete=models.CASCADE, related_name='routes')
    school = models.ForeignKey(School, on_delete=models.CASCADE)

    # Route timing
    start_time = models.TimeField()
    end_time = models.TimeField()
    active_days = models.JSONField(default=list)  # ['monday', 'tuesday', ...]

    # Distance and timing estimates
    total_distance_km = models.DecimalField(max_digits=6, decimal_places=2)
    estimated_duration_minutes = models.PositiveIntegerField()

class Child(models.Model):
    """
    Child/Student model linked to parents
    """
    BUS_STATUS_CHOICES = [
        ('not_started', 'Not Started'),
        ('boarding', 'Boarding'),
        ('on_route', 'On Route'),
        ('arrived', 'Arrived'),
        ('delayed', 'Delayed'),
        ('departed', 'Departed from School'),
    ]

    name = models.CharField(max_length=100)
    parent = models.ForeignKey(User, on_delete=models.CASCADE, related_name='children')
    school = models.ForeignKey(School, on_delete=models.CASCADE)
    class_name = models.CharField(max_length=10)  # e.g., "5A", "3B"

    # Bus assignment
    bus_route = models.ForeignKey(BusRoute, on_delete=models.SET_NULL, null=True)
    pickup_time = models.TimeField()
    drop_time = models.TimeField(null=True, blank=True)

    # Status tracking (denormalized for performance)
    bus_status = models.CharField(max_length=20, choices=BUS_STATUS_CHOICES, default='not_started')
    attendance = models.BooleanField(null=True, blank=True)

    # Optimization indexes
    class Meta:
        indexes = [
            models.Index(fields=['parent', 'bus_status']),
            models.Index(fields=['bus_route', 'attendance']),
        ]

class BusLocation(models.Model):
    """
    Real-time bus location tracking
    """
    bus = models.ForeignKey(Bus, on_delete=models.CASCADE, related_name='locations')

    # Location data
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    heading = models.FloatField(null=True, blank=True)  # Direction in degrees
    speed = models.FloatField(null=True, blank=True)    # km/h

    # Route progress
    route_progress = models.PositiveIntegerField(default=0)  # 0-100 percentage
    estimated_arrival = models.TimeField(null=True, blank=True)

    # Timestamps
    timestamp = models.DateTimeField(auto_now_add=True)
    last_updated = models.DateTimeField(auto_now=True)

    # Optimization: Keep only recent locations
    class Meta:
        indexes = [
            models.Index(fields=['bus', '-timestamp']),
        ]

class BusStop(models.Model):
    """
    Bus stops along the route
    """
    route = models.ForeignKey(BusRoute, on_delete=models.CASCADE, related_name='stops')
    name = models.CharField(max_length=100)

    # Location
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)

    # Stop order and timing
    stop_order = models.PositiveIntegerField()
    estimated_time = models.TimeField()
    is_completed = models.BooleanField(default=False)

    class Meta:
        ordering = ['stop_order']
        unique_together = ['route', 'stop_order']

class Notification(models.Model):
    """
    Push notifications for parents
    """
    NOTIFICATION_TYPES = [
        ('bus_delayed', 'Bus Delayed'),
        ('bus_arrived', 'Bus Arrived'),
        ('child_absent', 'Child Absent'),
        ('route_changed', 'Route Changed'),
        ('emergency', 'Emergency'),
        ('general', 'General'),
    ]

    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]

    notification_id = models.CharField(max_length=50, unique=True, db_index=True)
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')

    # Notification content
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=200)
    message = models.TextField()
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')

    # Related objects
    related_child = models.ForeignKey(Child, on_delete=models.CASCADE, null=True, blank=True)
    related_bus = models.ForeignKey(Bus, on_delete=models.CASCADE, null=True, blank=True)

    # Status and metadata
    is_read = models.BooleanField(default=False)
    action_required = models.BooleanField(default=False)
    metadata = models.JSONField(default=dict)  # For additional data

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient', 'is_read', '-created_at']),
            models.Index(fields=['notification_type', 'priority']),
        ]

class LocationHistory(models.Model):
    """
    Historical location data for breadcrumb trails
    """
    bus = models.ForeignKey(Bus, on_delete=models.CASCADE)
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    speed = models.FloatField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    date = models.DateField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['bus', 'date', 'timestamp']),
        ]
```

## API Performance Optimizations

### 1. Database Query Optimization
```python
# Use select_related and prefetch_related
children = Child.objects.select_related('bus_route__bus', 'school').filter(parent=request.user)

# Use only() for minimal field selection
notifications = Notification.objects.only('id', 'title', 'message', 'is_read', 'created_at').filter(recipient=user)
```

### 2. Caching Strategy
```python
# Redis caching for frequently accessed data
from django.core.cache import cache

def get_bus_location(bus_number):
    cache_key = f"bus_location_{bus_number}"
    location = cache.get(cache_key)

    if not location:
        location = BusLocation.objects.filter(bus__bus_number=bus_number).last()
        cache.set(cache_key, location, timeout=30)  # 30 seconds cache

    return location
```

### 3. API Response Compression
```python
# settings.py
MIDDLEWARE = [
    'django.middleware.gzip.GZipMiddleware',
    # ... other middleware
]
```

### 4. Pagination for Large Datasets
```python
# Use cursor pagination for better performance
from rest_framework.pagination import CursorPagination

class NotificationPagination(CursorPagination):
    page_size = 20
    ordering = '-created_at'
```

## Security Considerations

### 1. JWT Token Configuration
```python
# settings.py
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=24),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
}
```

### 2. API Rate Limiting
```python
# Use django-ratelimit
from django_ratelimit.decorators import ratelimit

@ratelimit(key='user', rate='100/h', method='GET')
def get_notifications(request):
    # API logic
```

### 3. Data Validation
```python
# Use DRF serializers for validation
from rest_framework import serializers

class BusLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusLocation
        fields = ['latitude', 'longitude', 'heading', 'speed', 'timestamp']
```

This API documentation provides a complete structure for your DRF backend with optimized performance, proper variable naming, and security considerations.