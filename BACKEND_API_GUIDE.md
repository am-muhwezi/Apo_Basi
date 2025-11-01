# Backend API Development Guide
## Django REST Framework + FastAPI for Real-time Tracking

**Target Audience:** Junior developers with NO backend development background
**Goal:** Take you from zero to developing API features and teaching others
**Stack:** Django, Django REST Framework (DRF), FastAPI, PostgreSQL/SQLite

---

## Table of Contents
1. [Understanding Backend Development](#1-understanding-backend-development)
2. [Python Fundamentals](#2-python-fundamentals)
3. [Django Basics](#3-django-basics)
4. [Django REST Framework (DRF)](#4-django-rest-framework-drf)
5. [Database Models & Relationships](#5-database-models--relationships)
6. [Building REST API Endpoints](#6-building-rest-api-endpoints)
7. [Authentication & Authorization](#7-authentication--authorization)
8. [FastAPI for Real-time Location Tracking](#8-fastapi-for-real-time-location-tracking)
9. [WebSocket Communication](#9-websocket-communication)
10. [Database Queries & Optimization](#10-database-queries--optimization)
11. [Testing & Debugging](#11-testing--debugging)
12. [Common Development Tasks](#12-common-development-tasks)
13. [Best Practices](#13-best-practices)

---

## 1. Understanding Backend Development

### What is Backend Development?
The backend is the **server-side** of an application. It:
- Stores and manages data (database)
- Handles business logic
- Provides APIs for frontend/mobile apps
- Manages user authentication
- Processes requests and sends responses

### Client-Server Architecture
```
Mobile App/Web (Client) ⟷ Backend Server ⟷ Database
                          (API)
```

**Example Flow:**
1. User clicks "Login" in mobile app
2. App sends request: `POST /api/login {username, password}`
3. Backend checks credentials in database
4. Backend sends response: `{token: "abc123", user: {...}}`
5. App receives response and logs user in

### REST API Basics

**REST** = Representational State Transfer

**HTTP Methods:**
- `GET` - Read data (e.g., get list of drivers)
- `POST` - Create new data (e.g., add new driver)
- `PUT` / `PATCH` - Update existing data
- `DELETE` - Remove data

**Example Endpoints:**
```
GET    /api/drivers/           # List all drivers
GET    /api/drivers/1/         # Get driver with ID 1
POST   /api/drivers/           # Create new driver
PATCH  /api/drivers/1/         # Update driver 1
DELETE /api/drivers/1/         # Delete driver 1
```

---

## 2. Python Fundamentals

### 2.1 Python Basics

```python
# Variables
name = "John"
age = 25
height = 5.9
is_active = True

# Lists
numbers = [1, 2, 3, 4, 5]
names = ["Alice", "Bob", "Charlie"]

# Dictionaries (like objects)
user = {
    "name": "John",
    "age": 25,
    "email": "john@example.com"
}

# Functions
def greet(name):
    return f"Hello, {name}!"

# Calling function
message = greet("Alice")
print(message)  # Output: Hello, Alice!

# Classes
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def introduce(self):
        return f"I am {self.name}, {self.age} years old"

# Using classes
person = Person("John", 25)
print(person.introduce())

# List comprehension (powerful!)
numbers = [1, 2, 3, 4, 5]
squares = [n ** 2 for n in numbers]
# Result: [1, 4, 9, 16, 25]

# Filter list
even_numbers = [n for n in numbers if n % 2 == 0]
# Result: [2, 4]
```

### 2.2 Virtual Environments

```bash
# Create virtual environment
python -m venv venv

# Activate (Linux/Mac)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Install packages
pip install django djangorestframework

# Save dependencies
pip freeze > requirements.txt

# Install from requirements
pip install -r requirements.txt
```

---

## 3. Django Basics

### 3.1 Installation & Setup

```bash
# Install Django
pip install django djangorestframework

# Create new project
django-admin startproject busTracker

# Navigate to project
cd busTracker

# Create app (module)
python manage.py startapp drivers

# Run migrations (setup database)
python manage.py migrate

# Create superuser (admin)
python manage.py createsuperuser

# Run development server
python manage.py runserver

# Access at http://127.0.0.1:8000
```

### 3.2 Project Structure

```
busTracker/
├── manage.py              # Command-line utility
├── busTracker/            # Project settings
│   ├── __init__.py
│   ├── settings.py       # Configuration
│   ├── urls.py           # Main URL routing
│   └── wsgi.py
├── drivers/              # App for drivers
│   ├── models.py         # Database models
│   ├── views.py          # Request handlers
│   ├── serializers.py    # Data conversion
│   ├── urls.py           # App URLs
│   └── admin.py          # Admin interface
├── buses/                # App for buses
├── parents/              # App for parents
└── requirements.txt
```

### 3.3 Settings Configuration

**busTracker/settings.py:**
```python
# Installed apps
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Third-party
    'rest_framework',
    'corsheaders',  # For cross-origin requests

    # Our apps
    'drivers',
    'buses',
    'parents',
    'children',
]

# CORS (allow frontend to access API)
CORS_ALLOWED_ORIGINS = [
    "http://localhost:5173",  # Vite dev server
    "http://localhost:3000",  # React dev server
]

# REST Framework settings
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
```

---

## 4. Django REST Framework (DRF)

### 4.1 Installation

```bash
pip install djangorestframework
pip install djangorestframework-simplejwt
pip install django-cors-headers
```

### 4.2 Basic API View

**drivers/views.py:**
```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class HelloWorldView(APIView):
    def get(self, request):
        return Response({
            "message": "Hello, World!",
            "status": "success"
        })
```

**drivers/urls.py:**
```python
from django.urls import path
from .views import HelloWorldView

urlpatterns = [
    path("hello/", HelloWorldView.as_view(), name="hello"),
]
```

**busTracker/urls.py:**
```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/drivers/", include("drivers.urls")),
]
```

**Test:**
```bash
# Start server
python manage.py runserver

# Visit: http://127.0.0.1:8000/api/drivers/hello/
# You'll see: {"message": "Hello, World!", "status": "success"}
```

---

## 5. Database Models & Relationships

### 5.1 Creating Models

**users/models.py:**
```python
from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    """Extended user model"""
    USER_TYPES = (
        ("parent", "Parent"),
        ("busminder", "Bus Minder"),
        ("driver", "Driver"),
        ("admin", "Admin"),
    )

    user_type = models.CharField(max_length=20, choices=USER_TYPES)
    phone_number = models.CharField(max_length=15, blank=True, null=True)

    def __str__(self):
        return f"{self.username} ({self.get_user_type_display()})"
```

**drivers/models.py:**
```python
from django.db import models
from users.models import User
from buses.models import Bus

class Driver(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
    ]

    # One-to-One relationship with User
    user = models.OneToOneField(User, on_delete=models.CASCADE, primary_key=True)

    # Driver-specific fields
    license_number = models.CharField(max_length=50)
    license_expiry = models.DateField(null=True, blank=True)
    phone_number = models.CharField(max_length=20)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')

    # Foreign Key relationship (many-to-one)
    assigned_bus = models.ForeignKey(
        Bus,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='driver_profile'
    )

    def __str__(self):
        return f"Driver: {self.user.get_full_name() or self.user.username}"

    class Meta:
        ordering = ['user__first_name']
```

**buses/models.py:**
```python
from django.db import models
from users.models import User

class Bus(models.Model):
    number_plate = models.CharField(max_length=20, unique=True)
    capacity = models.IntegerField()
    is_active = models.BooleanField(default=True)

    # Location tracking
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    current_location = models.CharField(max_length=255, blank=True)
    speed = models.FloatField(default=0)
    heading = models.FloatField(null=True, blank=True)
    last_updated = models.DateTimeField(auto_now=True)

    # Relationships
    driver = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        limit_choices_to={'user_type': 'driver'},
        related_name='driven_buses'
    )
    bus_minder = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        limit_choices_to={'user_type': 'busminder'},
        related_name='monitored_buses'
    )

    def __str__(self):
        return self.number_plate
```

### 5.2 Relationships Explained

**One-to-One:** One user has exactly one driver profile
```python
user = models.OneToOneField(User, on_delete=models.CASCADE)
```

**Many-to-One (Foreign Key):** Many drivers can be assigned to one bus
```python
assigned_bus = models.ForeignKey(Bus, on_delete=models.SET_NULL)
```

**Many-to-Many:** Many children can be in many buses (through assignments)
```python
children = models.ManyToManyField(Child, related_name='buses')
```

### 5.3 Making Migrations

```bash
# Create migration files
python manage.py makemigrations

# Apply migrations to database
python manage.py migrate

# Check migration status
python manage.py showmigrations

# Rollback migration
python manage.py migrate drivers 0001
```

---

## 6. Building REST API Endpoints

### 6.1 Serializers (Data Conversion)

Serializers convert Python objects to JSON and vice versa.

**drivers/serializers.py:**
```python
from rest_framework import serializers
from .models import Driver
from users.models import User

class DriverSerializer(serializers.ModelSerializer):
    """Serializer for displaying driver data"""

    # Get user fields
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)

    # Get assigned bus info
    bus_number_plate = serializers.CharField(
        source='assigned_bus.number_plate',
        read_only=True,
        allow_null=True
    )

    class Meta:
        model = Driver
        fields = [
            'user',  # User ID
            'first_name',
            'last_name',
            'email',
            'username',
            'license_number',
            'license_expiry',
            'phone_number',
            'status',
            'assigned_bus',
            'bus_number_plate',
        ]

class DriverCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating driver"""

    # User fields
    first_name = serializers.CharField(write_only=True)
    last_name = serializers.CharField(write_only=True)
    email = serializers.EmailField(write_only=True)
    username = serializers.CharField(write_only=True)
    password = serializers.CharField(write_only=True)

    class Meta:
        model = Driver
        fields = [
            'first_name',
            'last_name',
            'email',
            'username',
            'password',
            'license_number',
            'phone_number',
            'status',
        ]

    def create(self, validated_data):
        # Extract user data
        user_data = {
            'first_name': validated_data.pop('first_name'),
            'last_name': validated_data.pop('last_name'),
            'email': validated_data.pop('email'),
            'username': validated_data.pop('username'),
            'password': validated_data.pop('password'),
            'user_type': 'driver',
        }

        # Create user
        user = User.objects.create_user(**user_data)

        # Create driver profile
        driver = Driver.objects.create(user=user, **validated_data)

        return driver
```

### 6.2 Views (Request Handlers)

**Using Generic Views (Recommended):**
```python
# drivers/views.py
from rest_framework import generics
from rest_framework.permissions import AllowAny
from .models import Driver
from .serializers import DriverSerializer, DriverCreateSerializer

class DriverListCreateView(generics.ListCreateAPIView):
    """
    GET /api/drivers/ - List all drivers
    POST /api/drivers/ - Create new driver
    """
    permission_classes = [AllowAny]
    queryset = Driver.objects.select_related('user', 'assigned_bus').all()

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return DriverCreateSerializer
        return DriverSerializer

class DriverDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/drivers/{id}/ - Get driver details
    PUT /api/drivers/{id}/ - Update driver
    PATCH /api/drivers/{id}/ - Partial update
    DELETE /api/drivers/{id}/ - Delete driver
    """
    permission_classes = [AllowAny]
    queryset = Driver.objects.select_related('user', 'assigned_bus').all()
    lookup_field = 'user_id'

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return DriverCreateSerializer
        return DriverSerializer
```

**Custom API Views:**
```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class MyBusView(APIView):
    """Get driver's assigned bus with children"""

    def get(self, request):
        # Get current user
        user = request.user

        # Get buses where this driver is assigned
        buses = Bus.objects.filter(driver=user).prefetch_related('children')

        if not buses.exists():
            return Response({
                "message": "You are not assigned to any bus yet",
                "bus": None
            })

        bus = buses.first()
        children = bus.children.all()

        # Build response
        data = {
            "id": bus.id,
            "number_plate": bus.number_plate,
            "is_active": bus.is_active,
            "children_count": children.count(),
            "children": [
                {
                    "id": child.id,
                    "name": f"{child.first_name} {child.last_name}",
                    "class_grade": child.class_grade,
                }
                for child in children
            ]
        }

        return Response(data)
```

### 6.3 URL Routing

**drivers/urls.py:**
```python
from django.urls import path
from .views import (
    DriverListCreateView,
    DriverDetailView,
    MyBusView
)

urlpatterns = [
    path("", DriverListCreateView.as_view(), name="driver-list-create"),
    path("<int:user_id>/", DriverDetailView.as_view(), name="driver-detail"),
    path("my-bus/", MyBusView.as_view(), name="my-bus"),
]
```

**Main URLs:**
```python
# busTracker/urls.py
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/drivers/", include("drivers.urls")),
    path("api/buses/", include("buses.urls")),
    path("api/parents/", include("parents.urls")),
]
```

---

## 7. Authentication & Authorization

### 7.1 JWT Authentication Setup

```bash
pip install djangorestframework-simplejwt
```

**settings.py:**
```python
from datetime import timedelta

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
}
```

### 7.2 Login Endpoint

**users/views.py:**
```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate

@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({
            'error': 'Username and password are required'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Authenticate user
    user = authenticate(username=username, password=password)

    if user is not None:
        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)

        return Response({
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'user_type': user.user_type,
            },
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            },
            'message': 'Login successful'
        })
    else:
        return Response({
            'error': 'Invalid credentials'
        }, status=status.HTTP_401_UNAUTHORIZED)
```

### 7.3 Custom Permissions

**users/permissions.py:**
```python
from rest_framework import permissions

class IsDriver(permissions.BasePermission):
    """Allow access only to drivers"""

    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.user_type == 'driver'

class IsParent(permissions.BasePermission):
    """Allow access only to parents"""

    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.user_type == 'parent'

# Usage in views
class MyBusView(APIView):
    permission_classes = [IsAuthenticated, IsDriver]

    def get(self, request):
        # Only authenticated drivers can access
        pass
```

---

## 8. FastAPI for Real-time Location Tracking

### 8.1 Why FastAPI?

**Django:** Great for traditional CRUD operations, admin interface
**FastAPI:** Perfect for real-time features, WebSockets, high performance

We use **both**:
- Django for main API (users, drivers, buses)
- FastAPI for location tracking (high-frequency updates)

### 8.2 FastAPI Setup

**Install:**
```bash
pip install fastapi uvicorn
```

**Create tracking server (separate from Django):**
```
busTracker/
├── manage.py
├── busTracker/
├── drivers/
└── tracking_server/
    ├── main.py           # FastAPI app
    ├── models.py
    └── requirements.txt
```

**tracking_server/main.py:**
```python
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import time

app = FastAPI(title="Bus Tracking API")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage (use Redis in production)
location_cache = {}

# Data models
class LocationUpdate(BaseModel):
    bus_id: int
    latitude: float
    longitude: float
    speed: float
    heading: Optional[float] = None
    driver_id: int

class LocationResponse(BaseModel):
    bus_id: int
    latitude: float
    longitude: float
    speed: float
    heading: Optional[float]
    timestamp: float

@app.get("/")
def read_root():
    return {"message": "Bus Tracking API", "status": "running"}

@app.post("/api/location/update")
async def update_location(location: LocationUpdate):
    """
    Update bus location
    Called by driver app every 5-10 seconds
    """
    location_cache[location.bus_id] = {
        "bus_id": location.bus_id,
        "latitude": location.latitude,
        "longitude": location.longitude,
        "speed": location.speed,
        "heading": location.heading,
        "driver_id": location.driver_id,
        "timestamp": time.time()
    }

    # TODO: Also update Django database
    # await sync_to_django_db(location)

    return {"status": "success", "message": "Location updated"}

@app.get("/api/location/{bus_id}")
async def get_location(bus_id: int):
    """
    Get current location of a bus
    Called by parent app to track bus
    """
    if bus_id not in location_cache:
        raise HTTPException(status_code=404, detail="Bus not found")

    return location_cache[bus_id]

@app.get("/api/location/all")
async def get_all_locations():
    """
    Get all bus locations
    Used by admin dashboard for live map
    """
    return list(location_cache.values())

# Run with: uvicorn main:app --reload --port 8001
```

**Run FastAPI Server:**
```bash
cd tracking_server
uvicorn main:app --reload --port 8001

# Access at: http://127.0.0.1:8001
# API docs: http://127.0.0.1:8001/docs
```

### 8.3 Connecting to Django Database

**tracking_server/database.py:**
```python
import psycopg2
from psycopg2.extras import RealDictCursor

class DatabaseConnection:
    def __init__(self):
        self.connection = psycopg2.connect(
            host="localhost",
            database="bustracker",
            user="postgres",
            password="password"
        )

    def update_bus_location(self, bus_id, latitude, longitude, speed, heading):
        cursor = self.connection.cursor()
        cursor.execute("""
            UPDATE buses_bus
            SET latitude = %s,
                longitude = %s,
                speed = %s,
                heading = %s,
                last_updated = NOW()
            WHERE id = %s
        """, (latitude, longitude, speed, heading, bus_id))
        self.connection.commit()
        cursor.close()

# Usage in FastAPI
db = DatabaseConnection()

@app.post("/api/location/update")
async def update_location(location: LocationUpdate):
    # Update cache
    location_cache[location.bus_id] = {...}

    # Update Django database
    db.update_bus_location(
        location.bus_id,
        location.latitude,
        location.longitude,
        location.speed,
        location.heading
    )

    return {"status": "success"}
```

---

## 9. WebSocket Communication

### 9.1 WebSocket with FastAPI

**tracking_server/main.py:**
```python
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import List
import json
import asyncio

app = FastAPI()

# Store active WebSocket connections
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        """Send message to all connected clients"""
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except:
                pass

manager = ConnectionManager()

@app.websocket("/ws/tracking")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time location updates
    Admin dashboard connects to this for live map
    """
    await manager.connect(websocket)

    try:
        while True:
            # Send current locations every 2 seconds
            await websocket.send_json({
                "type": "location_update",
                "buses": list(location_cache.values())
            })
            await asyncio.sleep(2)

    except WebSocketDisconnect:
        manager.disconnect(websocket)

# When location is updated, broadcast to all clients
@app.post("/api/location/update")
async def update_location(location: LocationUpdate):
    # Update cache
    location_cache[location.bus_id] = {...}

    # Broadcast to all connected WebSocket clients
    await manager.broadcast({
        "type": "location_update",
        "bus_id": location.bus_id,
        "data": location_cache[location.bus_id]
    })

    return {"status": "success"}
```

### 9.2 Client Connection (Frontend)

**JavaScript Client:**
```javascript
const ws = new WebSocket('ws://localhost:8001/ws/tracking');

ws.onopen = () => {
    console.log('Connected to tracking server');
};

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log('Location update:', data);

    // Update map markers
    updateMapMarkers(data.buses);
};

ws.onerror = (error) => {
    console.error('WebSocket error:', error);
};

ws.onclose = () => {
    console.log('Disconnected from tracking server');
};
```

---

## 10. Database Queries & Optimization

### 10.1 QuerySet Basics

```python
from drivers.models import Driver

# Get all drivers
drivers = Driver.objects.all()

# Filter
active_drivers = Driver.objects.filter(status='active')

# Get single object
driver = Driver.objects.get(user_id=1)

# Or use get_object_or_404 (better for APIs)
from django.shortcuts import get_object_or_404
driver = get_object_or_404(Driver, user_id=1)

# Count
count = Driver.objects.filter(status='active').count()

# Exists
has_drivers = Driver.objects.filter(status='active').exists()

# Order
drivers = Driver.objects.order_by('user__first_name')

# Limit
first_10 = Driver.objects.all()[:10]
```

### 10.2 Relationships & Joins

```python
# Select related (JOIN) - for ForeignKey and OneToOne
drivers = Driver.objects.select_related('user', 'assigned_bus').all()

# Prefetch related - for ManyToMany and reverse ForeignKey
buses = Bus.objects.prefetch_related('children').all()

# Access related data
driver = Driver.objects.select_related('user').first()
print(driver.user.first_name)  # No additional query!

# Without select_related, this would cause extra query
driver = Driver.objects.first()
print(driver.user.first_name)  # Additional query executed
```

### 10.3 Complex Queries

```python
from django.db.models import Q, Count, Avg

# OR queries
drivers = Driver.objects.filter(
    Q(status='active') | Q(license_expiry__gte=date.today())
)

# AND queries
drivers = Driver.objects.filter(
    status='active',
    license_expiry__gte=date.today()
)

# Aggregation
from django.db.models import Count, Avg

# Count children per bus
buses = Bus.objects.annotate(
    child_count=Count('children')
).filter(child_count__gt=20)

# Average speed
avg_speed = Bus.objects.aggregate(Avg('speed'))
```

---

## 11. Testing & Debugging

### 11.1 Django Shell

```bash
# Open Django shell
python manage.py shell

# Test queries
>>> from drivers.models import Driver
>>> drivers = Driver.objects.all()
>>> print(drivers)
>>> driver = Driver.objects.first()
>>> print(driver.user.first_name)
```

### 11.2 API Testing with cURL

```bash
# GET request
curl http://127.0.0.1:8000/api/drivers/

# POST request
curl -X POST http://127.0.0.1:8000/api/drivers/ \
  -H "Content-Type: application/json" \
  -d '{"first_name":"John","last_name":"Doe","email":"john@example.com"}'

# With authentication
curl http://127.0.0.1:8000/api/drivers/my-bus/ \
  -H "Authorization: Bearer your_access_token_here"
```

### 11.3 Debugging

```python
# Print to console
print(f"Driver: {driver.user.first_name}")

# Import debugger
import pdb; pdb.set_trace()

# Or use breakpoint() (Python 3.7+)
breakpoint()

# Log to file
import logging
logger = logging.getLogger(__name__)
logger.info(f"Driver created: {driver.id}")
```

---

## 12. Common Development Tasks

### 12.1 Adding New Model

**Step 1:** Create model
```python
# myapp/models.py
class School(models.Model):
    name = models.CharField(max_length=200)
    address = models.TextField()
    phone = models.CharField(max_length=20)

    def __str__(self):
        return self.name
```

**Step 2:** Make migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

**Step 3:** Register in admin
```python
# myapp/admin.py
from django.contrib import admin
from .models import School

admin.site.register(School)
```

### 12.2 Adding New API Endpoint

**Step 1:** Create serializer
```python
# myapp/serializers.py
class SchoolSerializer(serializers.ModelSerializer):
    class Meta:
        model = School
        fields = '__all__'
```

**Step 2:** Create view
```python
# myapp/views.py
class SchoolListView(generics.ListCreateAPIView):
    queryset = School.objects.all()
    serializer_class = SchoolSerializer
```

**Step 3:** Add URL
```python
# myapp/urls.py
urlpatterns = [
    path("schools/", SchoolListView.as_view()),
]
```

### 12.3 Running Migrations

```bash
# Create migrations
python manage.py makemigrations

# See SQL that will be executed
python manage.py sqlmigrate drivers 0001

# Apply migrations
python manage.py migrate

# Reset migrations (careful!)
python manage.py migrate drivers zero
```

---

## 13. Best Practices

### 13.1 Code Organization

✅ **DO:**
```python
# Clear, descriptive names
def get_active_drivers():
    return Driver.objects.filter(status='active')

# Use select_related/prefetch_related
drivers = Driver.objects.select_related('user').all()

# Validate input
if not phone_number:
    return Response({"error": "Phone required"}, status=400)
```

❌ **DON'T:**
```python
# Unclear names
def gad():
    return Driver.objects.filter(status='active')

# N+1 queries problem
for driver in Driver.objects.all():
    print(driver.user.first_name)  # Query for each driver!

# No validation
phone = request.data.get('phone')
parent = Parent.objects.get(phone=phone)  # Crashes if not found
```

### 13.2 Security

```python
# ✅ Use permissions
class DriverDetailView(APIView):
    permission_classes = [IsAuthenticated, IsDriver]

# ✅ Validate input
serializer = DriverSerializer(data=request.data)
if serializer.is_valid():
    serializer.save()

# ✅ Use environment variables for secrets
import os
SECRET_KEY = os.environ.get('SECRET_KEY')

# ❌ Don't expose sensitive data
return Response({
    "password": user.password  # NEVER do this!
})
```

### 13.3 Performance

```python
# ✅ Use select_related
drivers = Driver.objects.select_related('user', 'assigned_bus').all()

# ✅ Use pagination for large lists
from rest_framework.pagination import PageNumberPagination

class DriverListView(generics.ListAPIView):
    pagination_class = PageNumberPagination

# ✅ Cache expensive queries
from django.core.cache import cache

def get_statistics():
    stats = cache.get('dashboard_stats')
    if not stats:
        stats = calculate_statistics()
        cache.set('dashboard_stats', stats, 300)  # 5 minutes
    return stats
```

---

## Quick Commands Reference

```bash
# Django
python manage.py runserver            # Start server
python manage.py makemigrations       # Create migrations
python manage.py migrate              # Apply migrations
python manage.py createsuperuser      # Create admin user
python manage.py shell                # Open Python shell
python manage.py test                 # Run tests

# FastAPI
uvicorn main:app --reload             # Start FastAPI server
uvicorn main:app --reload --port 8001 # Custom port

# Database
python manage.py dbshell              # Open database shell
python manage.py flush                # Clear database

# Dependencies
pip install -r requirements.txt       # Install dependencies
pip freeze > requirements.txt         # Save dependencies
```

---

## Architecture Summary

```
Mobile Apps (Flutter)
   ↓ HTTP/HTTPS
Django REST API (Port 8000)
   ├── CRUD operations
   ├── Authentication
   ├── Business logic
   └── Database: PostgreSQL/SQLite

FastAPI Server (Port 8001)
   ├── Real-time location updates
   ├── WebSocket connections
   └── High-frequency updates

Database (PostgreSQL/SQLite)
   └── Stores all data
```

---

## Useful Resources

- **Django Docs:** https://docs.djangoproject.com/
- **DRF Docs:** https://www.django-rest-framework.org/
- **FastAPI Docs:** https://fastapi.tiangolo.com/
- **Python Tutorial:** https://docs.python.org/3/tutorial/

---

**Document Version:** 1.0
**Last Updated:** October 2024
**Maintainer:** Development Team
