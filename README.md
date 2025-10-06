# ApoBasi: School Bus Tracking Platform for Africa

## Overview
ApoBasi is a modular, scalable school bus tracking and attendance platform designed for African schools, parents, and day scholars—starting in Uganda and Kenya. The system is built to work reliably in low-network environments and to empower schools and families with real-time, transparent, and safe student transport management.

## Why ApoBasi Matters
- **Safety & Peace of Mind:** Parents and schools can track buses and students in real time, reducing anxiety and improving accountability.
- **Designed for Africa:** Built for the realities of African connectivity, with offline-first features and robust sync for low-network areas.
- **Inclusive:** Supports all parents, day scholars, and school staff, regardless of device or location.
- **Modular Architecture:** Each module (parent app, minder/driver app, admin dashboard, backend) is loosely coupled, so updates or issues in one do not disrupt others.
- **Scalable Launch:** Simultaneous rollout in Uganda and Kenya, with a vision to expand across Africa.

## Technology Stack

### Backend
- **Django Rest Framework (DRF):**
  - Secure, modular REST API for all data and authentication.
  - Handles business logic, user management, trip/attendance records, and device sync.
- **PostgreSQL:**
  - Reliable, scalable relational database.
  - Optimized for transactional safety and offline sync patterns.

### Frontend
- **React Native + Expo:**
  - Cross-platform mobile app for parents, drivers, and minders.
  - Works on Android and iOS, with offline-first data and background sync.
- **React + Vite (Web Admin Dashboard):**
  - Fast, modern web dashboard for school admins.
  - Real-time monitoring, reporting, and management tools.

## Key Features
- **Role-based Apps:**
  - Parent, Driver, Minder, and Admin flows are separated for clarity and security.
- **Offline-First:**
  - Attendance and trip data can be captured offline and synced when network is available.
- **Live Location Tracking:**
  - Real-time bus and student location for parents and schools.
- **Attendance Management:**
  - Minder can mark attendance offline; data syncs automatically.
- **Admin Dashboard:**
  - Web-based, fast, and easy to use for school staff.
- **Modular Design:**
  - Each module can be updated or scaled independently, minimizing risk and downtime.

## Project Structure
- `server/` — Django DRF backend
- `client/apo_basi-client/` — React Native mobile app
- `client/web-admin/` — React + Vite web admin dashboard

## Testing Environment

Testing is a core part of ApoBasi's development to ensure reliability across all modules:

- **Backend (DRF):**
  - Uses Django's built-in test framework (`pytest` and `unittest` compatible).
  - Run tests with:
    ```bash
    python manage.py test
    ```
  - Coverage reports and CI integration recommended.

- **Mobile App (React Native):**
  - Uses Jest for unit and integration tests.
  - React Native Testing Library for UI/component tests.
  - Run tests with:
    ```bash
    cd client/apo_basi-client
    npm test
    ```

- **Web Admin (React + Vite):**
  - Uses Vitest or Jest for unit tests.
  - React Testing Library for UI/component tests.
  - Run tests with:
    ```bash
    cd client/web-admin
    npm test
    ```

All modules are designed for independent testing, so issues in one do not block others. Continuous Integration (CI) is recommended for automated testing and quality assurance.

## Getting Started

### Prerequisites
- Python 3.8+ (for Django backend)
- Node.js 16+ and npm (for React Native client)
- Git
- PostgreSQL (recommended) or SQLite (for development)

### 1. Clone the Repository
```bash
git clone <repo-url>
cd ApoBasi
```

### 2. Backend Setup (Django REST Framework)

**For Junior Developers:**
The backend is built with Django REST Framework (DRF), which handles all the CRUD operations (Create, Read, Update, Delete) for our bus tracking system. Real-time location tracking uses WebSockets for efficient data transfer.

```bash
# Navigate to server directory
cd server

# Create a virtual environment (recommended)
python -m venv venv

# Activate virtual environment
# On Linux/Mac:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run database migrations
# This creates all the necessary tables in the database
python manage.py makemigrations
python manage.py migrate

# Create a superuser (admin) account
python manage.py createsuperuser

# Start the development server
python manage.py runserver
```

**Backend will run on:** `http://localhost:8000`
**Admin panel:** `http://localhost:8000/admin`

### 3. Mobile App Setup (React Native + Expo)

```bash
# Navigate to client directory
cd client

# Install dependencies
npm install

# Start Expo development server
npm start

# Scan QR code with Expo Go app (Android/iOS)
# Or press 'a' for Android emulator
# Or press 'i' for iOS simulator
```

**Important:** Make sure the backend server is running before testing the mobile app.

### 4. Web Admin Dashboard Setup (Optional)

```bash
# Navigate to web admin directory
cd client/web-admin

# Install dependencies
npm install

# Start development server
npm run dev
```

## User Guide: How Different Users Interact with the System

**For Junior Developers:**
ApoBasi supports four different user types, each with their own set of permissions and capabilities. Understanding these roles is crucial for building secure and functional features.

### 1. Admin Users

**What they do:** Manage the entire bus tracking system, create users, and make assignments.

**How to use:**

1. **Login to Admin Panel**
   ```
   URL: http://localhost:8000/admin
   Credentials: Use the superuser account you created during setup
   ```

2. **Create a Parent Account**
   ```http
   POST /api/admin/add-parent/
   Body: {
     "first_name": "John",
     "last_name": "Doe",
     "children": [
       {
         "first_name": "Alice",
         "last_name": "Doe",
         "class_grade": "Grade 5"
       }
     ]
   }
   Response: Returns generated username and password
   ```

3. **Create a Driver Account**
   ```http
   POST /api/admin/add-driver/
   Body: {
     "first_name": "James",
     "last_name": "Smith",
     "license_number": "DL123456",
     "phone_number": "+256700123456"
   }
   Response: Returns generated username and password
   ```

4. **Create a Bus Minder Account**
   ```http
   POST /api/admin/add-busminder/
   Body: {
     "first_name": "Mary",
     "last_name": "Johnson",
     "phone_number": "+256700654321",
     "email": "mary@school.com",
     "id_number": "ID987654"
   }
   Response: Returns generated username and password
   ```

5. **Assign Driver to Bus**
   ```http
   POST /api/admin/assign-driver-to-bus/
   Body: {
     "driver_id": 1,
     "bus_id": 1
   }
   ```

6. **Assign Bus Minder to Bus**
   ```http
   POST /api/admin/assign-busminder-to-bus/
   Body: {
     "busminder_id": 1,
     "bus_id": 1
   }
   ```

7. **Assign Child to Bus**
   ```http
   POST /api/admin/assign-child-to-bus/
   Body: {
     "child_id": 1,
     "bus_id": 1
   }
   ```

---

### 2. Parent Users

**What they do:** Track their children's location and attendance status.

**How to use:**

1. **Login**
   ```http
   POST /api/parents/login/
   Body: {
     "username": "parent_abc12345",
     "password": "generated_password"
   }
   Response: Returns JWT tokens and children list
   ```

2. **View All Children with Current Status**
   ```http
   GET /api/parents/my-children/
   Headers: Authorization: Bearer <access_token>

   Response: {
     "children": [
       {
         "id": 1,
         "first_name": "Alice",
         "last_name": "Doe",
         "class_grade": "Grade 5",
         "assigned_bus": {
           "id": 1,
           "number_plate": "UAH 123X"
         },
         "current_status": "On the way to school",
         "last_updated": "2025-10-02T08:30:00Z"
       }
     ]
   }
   ```

3. **View Child's Attendance History**
   ```http
   GET /api/parents/children/1/attendance/
   Headers: Authorization: Bearer <access_token>

   Response: Returns attendance records with dates and status changes
   ```

**Status Meanings:**
- **"Not on Bus"**: Child hasn't boarded yet
- **"On the way to school"**: Child is on the bus heading to school
- **"At School"**: Child has arrived and disembarked at school
- **"On the way home"**: Child is on the bus heading home
- **"Dropped Off"**: Child has been safely dropped off at home
- **"Absent"**: Child was marked absent for the day

---

### 3. Bus Minder Users

**What they do:** Mark attendance for children on their assigned bus(es).

**How to use:**

1. **Login** (similar to parent login)
   ```http
   POST /api/busminders/login/
   ```

2. **View Assigned Buses**
   ```http
   GET /api/busminders/my-buses/
   Headers: Authorization: Bearer <access_token>

   Response: {
     "buses": [
       {
         "id": 1,
         "number_plate": "UAH 123X",
         "is_active": true,
         "children_count": 15,
         "children": [...]
       }
     ]
   }
   ```

3. **View Children on a Specific Bus**
   ```http
   GET /api/busminders/buses/1/children/
   Headers: Authorization: Bearer <access_token>

   Response: Returns list of children with parent contacts and today's attendance
   ```

4. **Mark Attendance for a Child**
   ```http
   POST /api/busminders/mark-attendance/
   Headers: Authorization: Bearer <access_token>
   Body: {
     "child_id": 1,
     "status": "on_bus",
     "notes": "Child boarded at 7:15 AM"
   }

   Response: Confirms attendance marked
   ```

**Status Options for Marking:**
- `not_on_bus`
- `on_bus`
- `at_school`
- `on_way_home`
- `dropped_off`
- `absent`

---

### 4. Driver Users

**What they do:** View their assigned bus and route information.

**How to use:**

1. **Login** (similar to parent login)
   ```http
   POST /api/drivers/login/
   ```

2. **View Assigned Bus**
   ```http
   GET /api/drivers/my-bus/
   Headers: Authorization: Bearer <access_token>

   Response: {
     "id": 1,
     "number_plate": "UAH 123X",
     "is_active": true,
     "current_location": "Kampala Road",
     "latitude": "0.347596",
     "longitude": "32.582520",
     "children_count": 15,
     "children": [...]
   }
   ```

3. **View Route (Children List with Parent Contacts)**
   ```http
   GET /api/drivers/my-route/
   Headers: Authorization: Bearer <access_token>

   Response: {
     "bus": {...},
     "route": [
       {
         "child_name": "Alice Doe",
         "class_grade": "Grade 5",
         "parent_name": "John Doe",
         "parent_contact": "+256700123456",
         "parent_emergency": "+256700999888",
         "attendance_status": "On the way to school"
       }
     ]
   }
   ```

---

## Real-Time Location Tracking

**For Junior Developers:**
The system uses WebSockets for real-time location updates. While most CRUD operations use REST API, location tracking requires a persistent connection for efficiency.

**Current Implementation:**
- WebSocket endpoint for real-time bus location updates
- See `server/buses/realtime.py` for the WebSocket implementation
- See `server/REALTIME_TRACKING_SETUP.md` for detailed setup

**Note:** FastAPI can be integrated for high-performance location streaming if needed. The current WebSocket implementation handles real-time updates efficiently for most use cases.

---

## API Endpoints Summary

### Authentication
- `POST /api/parents/login/` - Parent login
- `POST /api/drivers/login/` - Driver login (if implemented)
- `POST /api/busminders/login/` - Bus minder login (if implemented)

### Admin Endpoints (Requires Admin Permission)
- `POST /api/admin/add-parent/` - Create parent with children
- `POST /api/admin/add-driver/` - Create driver account
- `POST /api/admin/add-busminder/` - Create bus minder account
- `POST /api/admin/assign-driver-to-bus/` - Assign driver to bus
- `POST /api/admin/assign-busminder-to-bus/` - Assign bus minder to bus
- `POST /api/admin/assign-child-to-bus/` - Assign child to bus

### Parent Endpoints (Requires Parent Permission)
- `GET /api/parents/my-children/` - View all children with current status
- `GET /api/parents/children/<child_id>/attendance/` - View child's attendance history

### Bus Minder Endpoints (Requires Bus Minder Permission)
- `GET /api/busminders/my-buses/` - View assigned buses
- `GET /api/busminders/buses/<bus_id>/children/` - View children on a bus
- `POST /api/busminders/mark-attendance/` - Mark child attendance

### Driver Endpoints (Requires Driver Permission)
- `GET /api/drivers/my-bus/` - View assigned bus and children
- `GET /api/drivers/my-route/` - View route with parent contact info

---

## Security & Permissions

**For Junior Developers:**
The system uses role-based access control (RBAC) to ensure users can only access data they're authorized to see.

**Permission Classes:**
- `IsParent` - Ensures user is a parent
- `IsDriver` - Ensures user is a driver
- `IsBusMinder` - Ensures user is a bus minder
- `IsAdmin` - Ensures user is an admin or superuser

**Example:**
Parents can ONLY view their own children's data. If a parent tries to access another parent's child, they'll receive a 403 Forbidden error.

**Authentication:**
All endpoints (except login/register) require a valid JWT access token in the Authorization header:
```
Authorization: Bearer <access_token>
```

---

## Contributing
We welcome contributions from African developers and educators! See `CONTRIBUTING.md` for guidelines.

## License
MIT License

---
ApoBasi: Empowering safe, transparent, and modern school transport for Africa.

---
Built with ❤️ for Africa
