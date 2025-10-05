# Integration Guide for AppBasi

## 📋 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Adding New Features](#adding-new-features)
3. [API Design Patterns](#api-design-patterns)
4. [Code Examples](#code-examples)
5. [Best Practices](#best-practices)

---

## 🏗️ Architecture Overview

### Technology Stack
- **Frontend**: React + Vite + TypeScript (Admin Panel)
- **Mobile**: React Native + Expo (Parent/Driver/Minder Apps)
- **Backend**: Django + Django REST Framework
- **Database**: SQLite (dev) / PostgreSQL (prod)

### Project Structure
```
AppBasi/
├── admin/              # React Admin Panel
│   └── project/
│       ├── src/
│       │   ├── pages/       # Page components
│       │   ├── services/    # API services
│       │   ├── components/  # Reusable components
│       │   └── types/       # TypeScript types
│       └── package.json
│
├── client/             # React Native Mobile App
│   ├── app/            # Expo Router pages
│   ├── src/
│   │   ├── contexts/   # React contexts
│   │   ├── services/   # API services
│   │   └── types/      # TypeScript types
│   └── package.json
│
└── server/             # Django Backend
    ├── buses/          # Bus app
    ├── children/       # Children app
    ├── drivers/        # Drivers app
    ├── parents/        # Parents app
    ├── admins/         # Admin workflows
    └── manage.py
```

### Key Design Principles
1. **Separation of Concerns**: Each Django app manages its own models
2. **RESTful APIs**: Standard HTTP methods for CRUD operations
3. **camelCase Consistency**: Backend serializers use camelCase to match frontend
4. **No Mapping**: Direct data flow between frontend and backend

---

## 🚀 Adding New Features

### Example: Adding a "Routes" Feature

#### Step 1: Backend (Django)

**1.1 Create Django App**
```bash
cd server
python manage.py startapp routes
```

**1.2 Define Models** (`routes/models.py`)
```python
from django.db import models

class Route(models.Model):
    routeName = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    bus = models.ForeignKey('buses.Bus', on_delete=models.CASCADE, related_name='routes')
    isActive = models.BooleanField(default=True)
    createdAt = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.routeName
```

**1.3 Create Serializers** (`routes/serializers.py`)
```python
from rest_framework import serializers
from .models import Route

class RouteSerializer(serializers.ModelSerializer):
    busNumber = serializers.CharField(source='bus.bus_number', read_only=True)

    class Meta:
        model = Route
        fields = ['id', 'routeName', 'description', 'bus', 'busNumber', 'isActive', 'createdAt']

class RouteCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Route
        fields = ['routeName', 'description', 'bus', 'isActive']
```

**1.4 Create Views** (`routes/views.py`)
```python
from rest_framework import generics
from rest_framework.permissions import AllowAny
from .models import Route
from .serializers import RouteSerializer, RouteCreateSerializer

class RouteListCreateView(generics.ListCreateAPIView):
    permission_classes = [AllowAny]
    queryset = Route.objects.select_related('bus').all()

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return RouteCreateSerializer
        return RouteSerializer

class RouteDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [AllowAny]
    queryset = Route.objects.select_related('bus').all()

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return RouteCreateSerializer
        return RouteSerializer
```

**1.5 Configure URLs** (`routes/urls.py`)
```python
from django.urls import path
from .views import RouteListCreateView, RouteDetailView

urlpatterns = [
    path('', RouteListCreateView.as_view(), name='route-list-create'),
    path('<int:pk>/', RouteDetailView.as_view(), name='route-detail'),
]
```

**1.6 Register in Main URLs** (`apo_basi/urls.py`)
```python
urlpatterns = [
    # ... existing urls
    path("api/routes/", include("routes.urls")),
]
```

**1.7 Register App** (`apo_basi/settings.py`)
```python
INSTALLED_APPS = [
    # ... existing apps
    'routes',
]
```

**1.8 Create Migrations**
```bash
python manage.py makemigrations routes
python manage.py migrate
```

#### Step 2: Frontend (Admin Panel)

**2.1 Define TypeScript Types** (`admin/project/src/types/index.ts`)
```typescript
export interface Route {
  id: string;
  routeName: string;
  description: string;
  bus: string;
  busNumber: string;
  isActive: boolean;
  createdAt: string;
}
```

**2.2 Create API Service** (`admin/project/src/services/routeApi.ts`)
```typescript
import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api/routes/';

export async function getRoutes() {
  return axios.get(`${API_BASE_URL}`);
}

export async function getRoute(id: string) {
  return axios.get(`${API_BASE_URL}${id}/`);
}

export async function createRoute(data: {
  routeName: string;
  description?: string;
  bus: string;
  isActive?: boolean;
}) {
  return axios.post(`${API_BASE_URL}`, data);
}

export async function updateRoute(id: string, data: {
  routeName?: string;
  description?: string;
  bus?: string;
  isActive?: boolean;
}) {
  return axios.put(`${API_BASE_URL}${id}/`, data);
}

export async function deleteRoute(id: string) {
  return axios.delete(`${API_BASE_URL}${id}/`);
}
```

**2.3 Create Page Component** (`admin/project/src/pages/RoutesPage.tsx`)
```typescript
import React, { useState, useEffect } from 'react';
import { getRoutes, createRoute, updateRoute, deleteRoute } from '../services/routeApi';
import type { Route } from '../types';

export default function RoutesPage() {
  const [routes, setRoutes] = useState<Route[]>([]);

  useEffect(() => {
    loadRoutes();
  }, []);

  async function loadRoutes() {
    try {
      const response = await getRoutes();
      setRoutes(response.data);
    } catch (error) {
      console.error('Failed to load routes:', error);
    }
  }

  // Add create, update, delete handlers...

  return (
    <div>
      <h1>Routes</h1>
      {/* Add UI components */}
    </div>
  );
}
```

**2.4 Add Route to App** (`admin/project/src/App.tsx`)
```typescript
import RoutesPage from './pages/RoutesPage';

// Add to routes configuration
{
  path: '/routes',
  element: <RoutesPage />
}
```

---

## 🎨 API Design Patterns

### RESTful Endpoint Structure
```
GET    /api/{resource}/           # List all
POST   /api/{resource}/           # Create new
GET    /api/{resource}/{id}/      # Get one
PUT    /api/{resource}/{id}/      # Update (full)
PATCH  /api/{resource}/{id}/      # Update (partial)
DELETE /api/{resource}/{id}/      # Delete

# Nested resources
GET    /api/{resource}/{id}/{nested}/
POST   /api/{resource}/{id}/{action}/
```

### Naming Conventions

**Backend (Django):**
- Models: `snake_case` for database fields
- Serializers: `camelCase` for API fields
- Views: `{Model}{Action}View` (e.g., `BusListCreateView`)
- URLs: `kebab-case` (e.g., `assign-driver`)

**Frontend:**
- Files: `PascalCase` for components, `camelCase` for utilities
- Functions: `camelCase` (e.g., `getBuses`)
- Variables: `camelCase`
- Constants: `UPPER_SNAKE_CASE`

### Serializer Pattern (camelCase)
```python
class BusSerializer(serializers.ModelSerializer):
    busNumber = serializers.CharField(source='bus_number')
    licensePlate = serializers.CharField(source='number_plate')
    # Maps DB snake_case to API camelCase
```

---

## 💡 Best Practices

### Backend

1. **Use Generic Views**: Prefer `generics.ListCreateAPIView` over `APIView`
2. **Separate Serializers**: One for read (full data), one for write (validation)
3. **Prefetch Related**: Always use `select_related()` and `prefetch_related()`
4. **Permission Classes**: Start with `AllowAny`, then add `IsAuthenticated`
5. **Error Handling**: Return proper HTTP status codes

### Frontend

1. **No Data Mapping**: Backend uses camelCase, frontend uses camelCase
2. **Async/Await**: Always use try-catch for API calls
3. **Loading States**: Show loading indicators during API calls
4. **Error Messages**: Display user-friendly error messages
5. **Reload on Success**: Refresh data after create/update/delete

### File Organization

```
server/{app_name}/
├── models.py          # Database models
├── serializers.py     # API serializers
├── views.py          # API views
├── urls.py           # URL routing
└── tests.py          # Unit tests

admin/project/src/
├── pages/            # One file per page
├── services/         # One API service per resource
├── components/       # Reusable UI components
└── types/           # TypeScript interfaces
```

---

## 🔄 Common Workflows

### Assigning Relationships

**Bad (in admins app):**
```python
# Don't put resource creation in admins
class AdminCreateBusView(...)  # ❌
```

**Good (in resource app):**
```python
# Resource CRUD in its own app
class BusListCreateView(...)  # ✅

# Complex workflows in admins
class AdminAssignDriverToBusView(...)  # ✅
```

### API Response Format

**List Response:**
```json
[
  {
    "id": 1,
    "busNumber": "B001",
    "capacity": 40,
    ...
  }
]
```

**Detail Response:**
```json
{
  "id": 1,
  "busNumber": "B001",
  "capacity": 40,
  "driverId": 5,
  "driverName": "John Doe",
  ...
}
```

### Error Response:
```json
{
  "error": "Driver not found",
  "detail": "No driver with id=999"
}
```

---

## 📚 Reference

### Django Commands
```bash
# Create app
python manage.py startapp {app_name}

# Migrations
python manage.py makemigrations
python manage.py migrate

# Run server
python manage.py runserver

# Create superuser
python manage.py createsuperuser
```

### Testing Endpoints
```bash
# List buses
curl http://localhost:8000/api/buses/

# Create bus
curl -X POST http://localhost:8000/api/buses/ \
  -H "Content-Type: application/json" \
  -d '{"busNumber":"B001","licensePlate":"ABC123","capacity":40}'

# Update bus
curl -X PUT http://localhost:8000/api/buses/1/ \
  -H "Content-Type: application/json" \
  -d '{"busNumber":"B002","licensePlate":"XYZ789","capacity":45}'
```

---

## 🎯 Next Steps

After reading this guide, you should be able to:
1. ✅ Add new Django apps with models and APIs
2. ✅ Create frontend pages that consume those APIs
3. ✅ Follow naming conventions for consistency
4. ✅ Use proper separation of concerns
5. ✅ Scale the codebase without technical debt

**For more specific examples, see:**
- `BUS_FEATURE_GUIDE.md` - Detailed bus management walkthrough
- `API_DOCUMENTATION.md` - Complete API reference
