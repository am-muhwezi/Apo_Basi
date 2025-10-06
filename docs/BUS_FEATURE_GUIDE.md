# Bus Management Feature Guide

## 📖 Overview

This guide explains how the Bus Management feature works in AppBasi, covering both backend and frontend implementation.

---

## 🏗️ Architecture

### Data Flow
```
Admin Panel (React)
    ↓ HTTP Request (camelCase JSON)
Django REST API (/api/buses/)
    ↓ Serializer (maps to snake_case)
Database (Bus Model)
    ↑ Query Results (snake_case)
Serializer (maps to camelCase)
    ↑ HTTP Response (camelCase JSON)
Admin Panel (React)
```

### Key Components

**Backend:**
- `buses/models.py` - Bus database model
- `buses/serializers.py` - camelCase API serializers
- `buses/views.py` - RESTful CRUD views
- `buses/urls.py` - URL routing

**Frontend:**
- `services/busApi.ts` - API service layer
- `pages/BusesPage.tsx` - Bus management UI
- `types/index.ts` - TypeScript types

---

## 🔧 Backend Implementation

### 1. Bus Model

**File**: `server/buses/models.py`

```python
class Bus(models.Model):
    # Basic Information
    bus_number = models.CharField(max_length=20, help_text="Bus ID")
    number_plate = models.CharField(max_length=20, unique=True)
    capacity = models.IntegerField(default=40)
    model = models.CharField(max_length=100, blank=True)
    year = models.IntegerField(null=True, blank=True)

    # GPS Tracking
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    current_location = models.CharField(max_length=255, blank=True)

    # Status
    is_active = models.BooleanField(default=False)
    last_maintenance = models.DateField(null=True, blank=True)

    # Relationships
    driver = models.ForeignKey(User, on_delete=models.SET_NULL, null=True,
                               related_name='driven_buses')
    bus_minder = models.ForeignKey(User, on_delete=models.SET_NULL, null=True,
                                   related_name='managed_buses')
```

**Key Features:**
- ✅ Unique license plates prevent duplicates
- ✅ GPS coordinates for real-time tracking
- ✅ Flexible relationships (driver/minder can be unassigned)
- ✅ Maintenance tracking

### 2. Serializers (camelCase)

**File**: `server/buses/serializers.py`

```python
class BusSerializer(serializers.ModelSerializer):
    """For GET requests - includes all data"""
    busNumber = serializers.CharField(source='bus_number')
    licensePlate = serializers.CharField(source='number_plate')
    driverId = serializers.IntegerField(source='driver.id', read_only=True)
    driverName = serializers.SerializerMethodField()
    assignedChildrenCount = serializers.SerializerMethodField()

    class Meta:
        model = Bus
        fields = ['id', 'busNumber', 'licensePlate', 'capacity', ...]

class BusCreateSerializer(serializers.ModelSerializer):
    """For POST/PUT requests - validates input"""
    busNumber = serializers.CharField(source='bus_number', required=True)
    licensePlate = serializers.CharField(source='number_plate', required=True)
    status = serializers.ChoiceField(choices=['active', 'maintenance', 'inactive'])

    def create(self, validated_data):
        status = validated_data.pop('status', 'active')
        validated_data['is_active'] = (status == 'active')
        return super().create(validated_data)
```

**Why camelCase?**
- ✅ Frontend uses camelCase JavaScript/TypeScript
- ✅ No mapping needed between frontend and backend
- ✅ Simpler code, fewer bugs

### 3. Views (RESTful CRUD)

**File**: `server/buses/views.py`

```python
class BusListCreateView(generics.ListCreateAPIView):
    """
    GET /api/buses/ - List all buses
    POST /api/buses/ - Create new bus
    """
    queryset = Bus.objects.select_related('driver', 'bus_minder')\
                          .prefetch_related('children').all()

    def get_serializer_class(self):
        return BusCreateSerializer if self.request.method == 'POST' else BusSerializer

class BusDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/buses/{id}/ - Get bus details
    PUT /api/buses/{id}/ - Update bus
    DELETE /api/buses/{id}/ - Delete bus
    """
    queryset = Bus.objects.select_related('driver', 'bus_minder')\
                          .prefetch_related('children').all()

    def get_serializer_class(self):
        return BusCreateSerializer if self.request.method in ['PUT', 'PATCH'] else BusSerializer
```

**Performance Optimizations:**
- `select_related()` - Reduces queries for foreign keys (driver, minder)
- `prefetch_related()` - Reduces queries for reverse relations (children)

### 4. URL Configuration

**File**: `server/buses/urls.py`

```python
urlpatterns = [
    path('', BusListCreateView.as_view(), name='bus-list-create'),
    path('<int:pk>/', BusDetailView.as_view(), name='bus-detail'),
    path('<int:pk>/assign-driver/', BusAssignDriverView.as_view()),
    path('<int:pk>/assign-minder/', BusAssignMinderView.as_view()),
    path('<int:pk>/assign-children/', BusAssignChildrenView.as_view()),
    path('<int:pk>/children/', BusChildrenView.as_view()),
]
```

---

## 💻 Frontend Implementation

### 1. API Service

**File**: `admin/project/src/services/busApi.ts`

```typescript
const API_BASE_URL = 'http://localhost:8000/api/buses/';

// List all buses
export async function getBuses() {
  return axios.get(`${API_BASE_URL}`);
}

// Create bus
export async function createBus(data: {
  busNumber: string;
  licensePlate: string;
  capacity: number;
  model?: string;
  year?: number;
  status?: string;
  lastMaintenance?: string;
}) {
  return axios.post(`${API_BASE_URL}`, data);
}

// Update bus
export async function updateBus(id: string, data: {...}) {
  return axios.put(`${API_BASE_URL}${id}/`, data);
}

// Delete bus
export async function deleteBus(id: string) {
  return axios.delete(`${API_BASE_URL}${id}/`);
}
```

**Simple and Clean:**
- ✅ No data transformation
- ✅ Direct API calls
- ✅ TypeScript types for safety

### 2. React Page Component

**File**: `admin/project/src/pages/BusesPage.tsx`

```typescript
export default function BusesPage() {
  const [buses, setBuses] = useState<Bus[]>([]);

  useEffect(() => {
    loadBuses();
  }, []);

  async function loadBuses() {
    try {
      const response = await getBuses();
      setBuses(response.data);  // No mapping needed!
    } catch (error) {
      console.error('Failed to load buses:', error);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    try {
      if (selectedBus) {
        await updateBus(selectedBus.id, formData);
      } else {
        await createBus(formData);
      }
      loadBuses();
      setShowModal(false);
    } catch (error) {
      alert('Failed to save bus');
    }
  }
}
```

---

## 📡 API Endpoints Reference

### Bus CRUD

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/api/buses/` | List all buses | - | `Bus[]` |
| POST | `/api/buses/` | Create bus | `{busNumber, licensePlate, capacity, ...}` | `Bus` |
| GET | `/api/buses/{id}/` | Get bus details | - | `Bus` |
| PUT | `/api/buses/{id}/` | Update bus | `{busNumber?, licensePlate?, ...}` | `Bus` |
| DELETE | `/api/buses/{id}/` | Delete bus | - | `204 No Content` |

### Bus Assignments

| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| POST | `/api/buses/{id}/assign-driver/` | Assign driver | `{driver_id: number}` |
| POST | `/api/buses/{id}/assign-minder/` | Assign minder | `{minder_id: number}` |
| POST | `/api/buses/{id}/assign-children/` | Assign children | `{children_ids: number[]}` |
| GET | `/api/buses/{id}/children/` | Get bus children | - |

---

## 🔄 Common Workflows

### Creating a Bus

**Request:**
```bash
POST /api/buses/
Content-Type: application/json

{
  "busNumber": "B001",
  "licensePlate": "ABC-123",
  "capacity": 40,
  "model": "Mercedes Sprinter",
  "year": 2023,
  "status": "active"
}
```

**Response:**
```json
{
  "id": 1,
  "busNumber": "B001",
  "licensePlate": "ABC-123",
  "capacity": 40,
  "model": "Mercedes Sprinter",
  "year": 2023,
  "isActive": true,
  "driverId": null,
  "driverName": null,
  "minderId": null,
  "minderName": null,
  "assignedChildrenCount": 0
}
```

### Assigning a Driver

**Request:**
```bash
POST /api/buses/1/assign-driver/
Content-Type: application/json

{
  "driver_id": 5
}
```

**Response:**
```json
{
  "message": "Driver John Doe assigned to bus B001",
  "bus": {
    "id": 1,
    "busNumber": "B001",
    "driverId": 5,
    "driverName": "John Doe",
    ...
  }
}
```

### Assigning Children

**Request:**
```bash
POST /api/buses/1/assign-children/
Content-Type: application/json

{
  "children_ids": [10, 11, 12, 13, 14]
}
```

**Response:**
```json
{
  "message": "5 children assigned to bus B001",
  "bus": {
    "id": 1,
    "busNumber": "B001",
    "assignedChildrenCount": 5,
    ...
  }
}
```

---

## 🐛 Troubleshooting

### Common Issues

**1. Bus creation fails with "This field is required"**
- ✅ Ensure `busNumber` and `licensePlate` are provided
- ✅ Check field names are camelCase, not snake_case

**2. Children assignment returns "Cannot assign X children. Bus capacity is Y"**
- ✅ Check bus capacity setting
- ✅ Reduce number of children or increase capacity

**3. Frontend shows empty list but backend has data**
- ✅ Check API URL is correct (`http://localhost:8000/api/buses/`)
- ✅ Check CORS settings in Django
- ✅ Check browser console for errors

**4. Driver/Minder assignment fails**
- ✅ Verify user exists and has correct `user_type` ('driver' or 'busminder')
- ✅ Use correct field name: `driver_id` not `driverId`

---

## ✅ Testing Checklist

### Backend Tests
```bash
# Test bus creation
curl -X POST http://localhost:8000/api/buses/ \
  -H "Content-Type: application/json" \
  -d '{"busNumber":"B001","licensePlate":"XYZ789","capacity":40}'

# Test bus update
curl -X PUT http://localhost:8000/api/buses/1/ \
  -H "Content-Type: application/json" \
  -d '{"busNumber":"B002","capacity":45}'

# Test bus deletion
curl -X DELETE http://localhost:8000/api/buses/1/
```

### Frontend Tests
1. ✅ Create bus with all fields
2. ✅ Create bus with minimal fields (busNumber, licensePlate, capacity)
3. ✅ Update bus details
4. ✅ Delete bus
5. ✅ Assign driver to bus
6. ✅ Assign minder to bus
7. ✅ Assign children to bus
8. ✅ View bus children list

---

## 🚀 Future Enhancements

### Planned Features
1. **Route Management** - Assign routes to buses
2. **Real-time GPS Tracking** - Live location updates
3. **Maintenance Scheduling** - Automated maintenance reminders
4. **Bus Analytics** - Usage reports and efficiency metrics
5. **Capacity Alerts** - Notify when bus is at capacity
6. **Multi-shift Support** - Handle morning and afternoon routes

### Scalability Considerations
- Add pagination for large bus fleets (`PageNumberPagination`)
- Implement search and filtering (`django-filter`)
- Add caching for frequently accessed data (`Redis`)
- Use WebSockets for real-time location updates (`Django Channels`)

---

## 📚 Related Documentation

- `INTEGRATION_GUIDE.md` - General guide for adding features
- `API_DOCUMENTATION.md` - Complete API reference
- `CLAUDE.md` - Project overview and commands
- `README.md` - Getting started guide

---

## 🎯 Summary

The Bus Management feature demonstrates AppBasi's clean architecture:
1. ✅ **No mapping** - camelCase everywhere
2. ✅ **RESTful design** - Standard endpoints
3. ✅ **Separation of concerns** - Each app owns its resources
4. ✅ **Simple and scalable** - Easy to extend

Follow this pattern when adding new features like Routes, Trips, or Maintenance.
