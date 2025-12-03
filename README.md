# ApoBasi - Enterprise School Bus Tracking Platform

<div align="center">

**A Production-Ready, Microservices-Based Platform for Real-Time School Transportation Management**

[![Django](https://img.shields.io/badge/Django-5.2.6-green.svg)](https://www.djangoproject.com/)
[![React](https://img.shields.io/badge/React-18.3.1-blue.svg)](https://reactjs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.6.0+-blue.svg)](https://flutter.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.5.3-blue.svg)](https://www.typescriptlang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

</div>

---

## Table of Contents

- [Executive Summary](#executive-summary)
- [System Architecture](#system-architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [API Documentation](#api-documentation)
- [Data Flow & Real-Time Architecture](#data-flow--real-time-architecture)
- [Security & Authentication](#security--authentication)
- [Development Workflow](#development-workflow)
- [Testing Strategy](#testing-strategy)
- [Deployment](#deployment)
- [Performance Considerations](#performance-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Executive Summary

### Project Overview

ApoBasi is a comprehensive, production-ready school bus tracking and attendance management platform designed specifically for the African market, initially targeting Uganda and Kenya. The system addresses critical challenges in student transportation safety, real-time tracking, and transparent communication between schools, parents, drivers, and bus monitors.

### Key Value Propositions

- **Safety & Accountability**: Real-time GPS tracking with status updates for every student
- **Offline-First Architecture**: Robust operation in low-connectivity environments typical of African infrastructure
- **Role-Based Access Control**: Secure, multi-tenant system with granular permissions
- **Scalable Microservices Design**: Independent services that can scale horizontally
- **Cross-Platform Mobile**: Single codebase for iOS and Android using Flutter
- **Real-Time Communication**: WebSocket-based live location updates with sub-second latency

### Target Users

1. **Parents/Guardians**: Track children's location and attendance in real-time
2. **Drivers**: View assigned routes and broadcast GPS location
3. **Bus Minders**: Manage student attendance with offline capability
4. **School Administrators**: Comprehensive dashboard for system management

---

## Mobile Applications - UI & Features

### ParentsApp - Real-Time Tracking for Parents

**Platform:** Flutter (iOS & Android)
**Architecture:** Clean architecture with presentation, business logic, and data layers

#### Key UI Features

**1. Parent Dashboard**
- **Child Cards**: Visual cards showing each child's current status
- **Status Indicators**: Color-coded status (on bus, at school, dropped off, absent)
- **Quick Actions**: Tap child card for detailed view and live tracking
- **Responsive Design**: Adapts to all screen sizes using Sizer package
- **Material Design 3**: Modern, accessible UI components

**2. Live Bus Tracking Map**
- **3D Bus Marker**: Custom yellow school bus icon that rotates based on GPS heading (0-360°)
- **Real-Time Updates**: WebSocket connection displays location updates in real-time
- **"LIVE" Badge**: Visual indicator when bus is actively moving
- **Connection Status**: Green/red dot showing WebSocket connection state
- **Map Controls**: Zoom, pan, center on bus, toggle satellite/map view
- **Route Visualization**: Planned route displayed alongside actual path
- **Smooth Animations**: Interpolated marker movement for fluid experience

**3. Child Detail Screen**
- **Profile Information**: Child's name, class, bus assignment
- **Current Status**: Latest attendance status with timestamp
- **Parent Information**: Contact details and emergency info
- **Action Buttons**: Call driver, view attendance history, live tracking

**4. Attendance History**
- **Calendar View**: Monthly calendar with attendance markings
- **Detailed Records**: Pickup/dropoff times, status, notes
- **Filter Options**: By date range, status type
- **Export Capability**: Share or save attendance reports

**5. Notification Center**
- **Push Notifications**: Alerts for status changes (future feature)
- **In-App Notifications**: System messages and updates
- **Custom Alerts**: Set up notifications for specific events

**6. Profile & Settings**
- **Parent Profile**: Update contact information
- **Preferences**: Notification settings, language selection
- **Multiple Children**: Manage all children from one account
- **Theme Options**: Light/dark mode support

#### Technical Highlights

**Real-Time Communication:**
```dart
// Socket.IO client integration
socket.on('location_update', (data) {
  setState(() {
    busLocation = LatLng(data['latitude'], data['longitude']);
    busHeading = data['heading'];
    busSpeed = data['speed'];
  });
});
```

**3D Bus Marker Widget:**
```dart
BusMarker3D(
  size: 80,
  heading: busHeading,  // Rotates marker
  isMoving: busSpeed > 1,  // Shows LIVE badge
  busNumber: busData.busNumber,
  onTap: () => showBusDetails(),
)
```

**Offline-First Architecture:**
- Local caching using SharedPreferences
- Displays last known location when offline
- Auto-sync when connection restored
- Clear offline/online indicators

**For complete ParentsApp documentation, see:** [ParentsApp/README.md](ParentsApp/README.md)

---

### DriversandMinders - Unified App for Staff

**Platform:** Flutter (iOS & Android)
**Role-Based UI:** Different interfaces for drivers vs bus minders

#### Key UI Features

**1. Unified Login Screen**
- **Phone-Based Authentication**: Login with phone number and password
- **Role Detection**: Automatically routes to appropriate interface based on user type
- **Remember Me**: Persist login credentials securely
- **Clean Material Design**: Simple, accessible login form

**2. Driver Interface**

**Start Shift Screen:**
- **Bus Information Card**: Displays assigned bus details (plate, model, capacity)
- **Quick Stats**: Children assigned, current route status
- **Action Buttons**: Start morning trip, start afternoon trip, end shift
- **Location Preview**: Shows current GPS location before starting

**Active Trip Screen:**
- **Live Map**: Real-time map showing driver's current location
- **3D Bus Marker**: Driver sees their own position with heading indicator
- **Route Visualization**: Planned route with upcoming stops
- **Next Stop Widget**: Prominent display of next pickup/dropoff location
- **Upcoming Stops List**: Scrollable list of remaining stops with child details
- **Trip Controls**:
  - Pause/resume location broadcasting
  - Mark stop as completed
  - Access parent contacts for emergencies
- **Connection Indicator**: Shows GPS status and server connection
- **Speed Display**: Current speed from GPS

**Route Management:**
- **Children List**: All assigned children with parent contacts
- **Tap to Call**: One-tap calling to parent phone numbers
- **Stop Sequence**: Ordered list of pickup/dropoff locations
- **Student Photos**: Visual identification (when available)

**3. Bus Minder Interface**

**Trip Progress Screen:**
- **Map View**: Displays bus route and current location (read-only)
- **Children Status Overview**: Quick glance at all children's attendance
- **Active Trip Info**: Trip type (morning/afternoon), start time, progress

**Attendance Screen:**
- **Student Cards**: Visual cards for each assigned child
- **Photo Display**: Child's photo for easy identification
- **Quick Actions**: Swipe gestures for common status updates
- **Status Buttons**:
  - Not on bus
  - On bus (boarding)
  - At school (dropped off at school)
  - On way home (boarding for return)
  - Dropped off (at home)
  - Absent
- **Parent Contact**: Tap to call/message parent
- **Notes Field**: Add contextual notes for each attendance entry
- **Timestamp**: Automatic timestamp for all status changes

**Offline Attendance:**
- **Queue Indicator**: Shows number of pending syncs
- **Visual Feedback**: Different colors for synced vs pending
- **Auto-Sync**: Automatically syncs when connection restored
- **Conflict Resolution**: Handles duplicate entries gracefully

**Multiple Bus Support (Minders):**
- **Bus Selection Screen**: Choose which bus to manage
- **Switch Between Buses**: Quick toggle between assigned buses
- **Per-Bus Attendance**: Separate attendance for each bus

#### Technical Highlights

**GPS Broadcasting (Driver):**
```dart
// Driver location service
class DriverLocationService {
  Timer? _locationTimer;

  void startBroadcasting() {
    _locationTimer = Timer.periodic(
      Duration(seconds: 5),
      (timer) async {
        Position position = await Geolocator.getCurrentPosition();
        await pushLocationToServer(position);
      },
    );
  }
}
```

**Role-Based Routing:**
```dart
// Automatic navigation based on user role
if (user.userType == 'driver') {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => DriverStartShiftScreen()),
  );
} else if (user.userType == 'busminder') {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => BusMinderDashboard()),
  );
}
```

**Offline Queue System:**
```dart
// Attendance sync service
class AttendanceSyncService {
  Future<void> markAttendance(AttendanceData data) async {
    try {
      await api.markAttendance(data);
    } catch (e) {
      await queueForLater(data);  // Save offline
    }
  }

  // Auto-sync when online
  void onConnectivityChange() {
    if (isOnline) syncPendingAttendance();
  }
}
```

**Responsive Design:**
- **Sizer Package**: Responsive sizing across devices
- **Adaptive Layouts**: Different layouts for tablets vs phones
- **Orientation Support**: Both portrait and landscape modes
- **Accessibility**: Screen reader support, high contrast mode

**For complete DriversandMinders documentation, see:** [DriversandMinders/README.md](DriversandMinders/README.md)

---

### Mobile Apps - Shared Features

**Material Design 3:**
- Modern, clean UI following Google's latest design guidelines
- Custom color schemes matching brand identity (yellow/gold theme)
- Smooth animations and transitions
- Consistent iconography using Material Icons

**Performance Optimizations:**
- **Lazy Loading**: Load data as needed, not all at once
- **Image Caching**: Cache bus markers and photos locally
- **Efficient State Management**: Minimal rebuilds, optimized setState
- **Background Sync**: Efficient data synchronization
- **Battery Optimization**: Intelligent GPS polling based on movement

**Security:**
- **Secure Storage**: Encrypted token storage using flutter_secure_storage
- **JWT Authentication**: Tokens included in all API requests
- **Auto-Logout**: Timeout after inactivity
- **Certificate Pinning**: Prevent man-in-the-middle attacks (production)

**Cross-Platform Compatibility:**
- **Single Codebase**: 95%+ code shared between iOS and Android
- **Platform-Specific**: Native features when needed (permissions, etc.)
- **Consistent UX**: Same user experience across platforms
- **Easy Maintenance**: Update once, deploy everywhere

---

## System Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                                    │
├─────────────────┬──────────────────┬──────────────────┬─────────────────┤
│  Parents App    │ Drivers/Minders  │  Admin Dashboard │   Web Browser   │
│   (Flutter)     │    (Flutter)     │  (React + Vite)  │                 │
│  iOS/Android    │   iOS/Android    │   TypeScript     │                 │
└────────┬────────┴────────┬─────────┴─────────┬────────┴─────────────────┘
         │                 │                   │
         │ HTTP/REST       │ HTTP/REST         │ HTTP/REST
         │ WebSocket       │ WebSocket         │
         │                 │                   │
┌────────▼─────────────────▼───────────────────▼──────────────────────────┐
│                     API GATEWAY / LOAD BALANCER                          │
└────────┬─────────────────┬───────────────────┬──────────────────────────┘
         │                 │                   │
         │                 │                   │
┌────────▼────────┐ ┌──────▼──────┐  ┌────────▼────────┐
│  Django REST    │ │  Socket.IO  │  │   FastAPI       │
│   Framework     │ │   Server    │  │ (Future/Alt)    │
│   Port: 8000    │ │ Port: 4000  │  │                 │
│                 │ │             │  │                 │
│ • Authentication│ │ • Real-time │  │ • High-perf     │
│ • Business Logic│ │   GPS       │  │   endpoints     │
│ • CRUD API      │ │ • WebSocket │  │                 │
└────────┬────────┘ └──────┬──────┘  └────────┬────────┘
         │                 │                   │
         │                 │                   │
┌────────▼─────────────────▼───────────────────▼──────────────────────────┐
│                        DATA LAYER                                        │
├──────────────────────────┬───────────────────────────────────────────────┤
│  PostgreSQL / SQLite     │         In-Memory Store                      │
│  • User data             │         • Active driver locations            │
│  • Bus records           │         • Real-time sessions                 │
│  • Attendance history    │                                              │
│  • Trip logs             │                                              │
└──────────────────────────┴───────────────────────────────────────────────┘
```

### Microservices Architecture

The platform follows a **loosely-coupled microservices pattern** with three main services:

1. **Django Backend Service** (Primary API)
   - RESTful API for all CRUD operations
   - JWT-based authentication
   - Role-based permission system
   - Database ORM and migrations

2. **Socket.IO Service** (Real-Time Communication)
   - WebSocket server for GPS broadcasting
   - Room-based pub/sub architecture
   - In-memory state management
   - Horizontal scaling capability

3. **Admin Frontend Service** (Web Dashboard)
   - React SPA with TypeScript
   - Vite for fast builds
   - Tailwind CSS for styling
   - Direct API integration

### Architectural Principles

- **Separation of Concerns**: Each service handles a specific domain
- **Offline-First**: Mobile apps cache data and sync when online
- **Stateless APIs**: JWT tokens eliminate server-side sessions
- **Event-Driven**: Real-time updates via WebSocket events
- **Scalability**: Services can be deployed and scaled independently

---

## Technology Stack

### Backend Services

#### Django REST Framework Service
| Technology | Version | Purpose |
|------------|---------|---------|
| Python | 3.6+ | Runtime environment |
| Django | 5.2.6 | Web framework |
| Django REST Framework | 3.16.1 | RESTful API |
| djangorestframework-simplejwt | 5.5.1 | JWT authentication |
| django-cors-headers | 4.9.0 | CORS handling |
| FastAPI | 0.109.0 | High-performance endpoints (optional) |
| Uvicorn | 0.27.0 | ASGI server |
| SQLite/PostgreSQL | - | Relational database |

#### Socket.IO Service
| Technology | Version | Purpose |
|------------|---------|---------|
| Node.js | 16+ | Runtime environment |
| Express.js | 5.1.0 | Web framework |
| Socket.IO | 4.8.1 | WebSocket communication |
| CORS | 2.8.5 | Cross-origin support |

### Frontend Services

#### Admin Dashboard (Web)
| Technology | Version | Purpose |
|------------|---------|---------|
| React | 18.3.1 | UI framework |
| TypeScript | 5.5.3 | Type safety |
| Vite | 5.4.2 | Build tool |
| React Router DOM | 7.9.5 | Client-side routing |
| Axios | 1.12.2 | HTTP client |
| Tailwind CSS | 3.4.1 | Utility-first CSS |
| Lucide React | 0.344.0 | Icon library |

#### Mobile Applications (Flutter)
| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter SDK | 3.6.0+ | Mobile framework |
| Dart | 3.6.0+ | Programming language |
| Dio | 5.4.0 | HTTP client |
| shared_preferences | 2.2.2 | Local storage |
| Google Maps Flutter | 2.12.3 | Map integration |
| Flutter Map | 8.2.2 | Alternative mapping |
| Geolocator | 14.0.2 | GPS location |
| Socket.IO Client | 2.0.3+1 | Real-time connection |
| Sizer | 3.1.3 | Responsive design |

---

## Project Structure

```
Apo_Basi/
│
├── server/                         # Django REST Framework Backend
│   ├── manage.py                   # Django management script
│   ├── requirements.txt            # Python dependencies
│   ├── SETUP.md                    # Backend setup guide
│   │
│   ├── Apo_Basi/                   # Project configuration
│   │   ├── settings.py             # Django settings
│   │   ├── urls.py                 # URL routing
│   │   └── wsgi.py                 # WSGI configuration
│   │
│   ├── users/                      # User management app
│   │   ├── models.py               # Custom User model
│   │   ├── serializers.py          # User serializers
│   │   ├── views.py                # Authentication views
│   │   └── permissions.py          # Custom permissions
│   │
│   ├── buses/                      # Bus management app
│   │   ├── models.py               # Bus model with GPS & location history
│   │   ├── serializers.py          # Bus serializers
│   │   └── views.py                # Bus CRUD & location endpoints
│   │
│   ├── children/                   # Student management app
│   │   ├── models.py               # Child model
│   │   └── views.py                # Child endpoints
│   │
│   ├── parents/                    # Parent-specific features
│   │   ├── models.py               # Parent profile
│   │   └── views.py                # Parent endpoints (direct phone login)
│   │
│   ├── drivers/                    # Driver-specific features
│   │   └── views.py                # Driver endpoints & location push
│   │
│   ├── busminders/                 # Bus minder features
│   │   ├── models.py               # BusMinder model
│   │   └── views.py                # Minder & attendance endpoints
│   │
│   ├── attendance/                 # Attendance tracking
│   │   ├── models.py               # Attendance records
│   │   └── views.py                # Attendance API
│   │
│   ├── trips/                      # Trip management
│   │   └── models.py               # Trip history
│   │
│   ├── assignments/                # Resource assignments
│   │   ├── models.py               # Assignment records
│   │   └── API_DOCUMENTATION.md    # Assignment API docs
│   │
│   └── admins/                     # Admin workflows
│       └── views.py                # Admin endpoints
│
├── socketio-server/                # Socket.IO Real-Time Server
│   ├── server.js                   # WebSocket server implementation
│   ├── package.json                # Node dependencies
│   ├── .env                        # Environment configuration
│   └── README.md                   # Socket server docs
│
├── admin/                          # React Admin Dashboard
│   ├── README.md                   # Complete admin dashboard guide
│   ├── package.json                # NPM dependencies
│   ├── vite.config.ts              # Vite configuration
│   ├── tsconfig.json               # TypeScript config
│   ├── tailwind.config.js          # Tailwind CSS config
│   │
│   ├── src/
│   │   ├── main.tsx                # React entry point
│   │   ├── App.tsx                 # Root component with routing
│   │   │
│   │   ├── pages/                  # Page components
│   │   │   ├── Dashboard.tsx       # Admin dashboard with stats
│   │   │   ├── Login.tsx           # Admin login
│   │   │   ├── BusManagement.tsx   # Bus CRUD operations
│   │   │   ├── UserManagement.tsx  # User admin panel
│   │   │   ├── ChildManagement.tsx # Student management
│   │   │   ├── AssignmentsPage.tsx # Assignment interface
│   │   │   ├── AttendancePage.tsx  # Attendance reports
│   │   │   ├── AnalyticsPage.tsx   # Analytics & insights
│   │   │   └── TrackingPage.tsx    # Live bus tracking
│   │   │
│   │   ├── components/             # Reusable components
│   │   │   ├── Layout.tsx          # Page layout wrapper
│   │   │   ├── PrivateRoute.tsx    # Auth guard
│   │   │   ├── Sidebar.tsx         # Navigation sidebar
│   │   │   ├── Header.tsx          # Top bar
│   │   │   ├── Modal.tsx           # Modal dialogs
│   │   │   └── LoadingSpinner.tsx  # Loading states
│   │   │
│   │   ├── hooks/                  # Custom React hooks
│   │   │   ├── useBuses.ts         # Bus data management
│   │   │   ├── useUsers.ts         # User data management
│   │   │   ├── useChildren.ts      # Children data
│   │   │   └── useAuth.ts          # Authentication
│   │   │
│   │   ├── services/               # API services
│   │   │   ├── api.ts              # Axios instance & interceptors
│   │   │   ├── busService.ts       # Bus API calls
│   │   │   ├── userService.ts      # User API calls
│   │   │   ├── childService.ts     # Child API calls
│   │   │   ├── assignmentService.ts# Assignment API calls
│   │   │   └── authService.ts      # Auth API calls
│   │   │
│   │   └── types/                  # TypeScript types
│   │       └── index.ts            # Shared type definitions
│   │
│   └── public/                     # Static assets
│
├── ParentsApp/                     # Flutter App for Parents
│   ├── README.md                   # Complete ParentsApp guide
│   ├── BUS_MARKER_DESIGN_GUIDE.md  # Custom bus marker guide
│   ├── pubspec.yaml                # Flutter dependencies
│   │
│   ├── lib/
│   │   ├── main.dart               # App entry point
│   │   │
│   │   ├── presentation/           # UI layer (screens)
│   │   │   ├── parent_dashboard/   # Dashboard with child cards
│   │   │   ├── child_detail/       # Child detail & tracking
│   │   │   │   └── widgets/        # Live map, status cards
│   │   │   ├── notifications_center/# Notification center
│   │   │   └── parent_profile_settings/# Profile management
│   │   │
│   │   ├── services/               # Business logic
│   │   │   ├── api_service.dart    # HTTP client (Dio)
│   │   │   ├── socket_service.dart # WebSocket for real-time
│   │   │   ├── notification_service.dart# Push notifications
│   │   │   └── mapbox_route_service.dart# Route rendering
│   │   │
│   │   ├── models/                 # Data models
│   │   │   ├── child_model.dart    # Child entity
│   │   │   └── bus_location_model.dart# GPS location
│   │   │
│   │   ├── widgets/                # Reusable widgets
│   │   │   └── location/           # Location-based widgets
│   │   │       ├── bus_marker_3d.dart   # 3D bus marker
│   │   │       └── live_tracking_map.dart# Map widget
│   │   │
│   │   └── config/                 # Configuration
│   │       └── api_config.dart     # API endpoints
│   │
│   ├── assets/                     # Static assets
│   │   └── images/                 # Images (bus icons, etc.)
│   │
│   ├── android/                    # Android configuration
│   └── ios/                        # iOS configuration
│
├── DriversandMinders/              # Flutter App for Drivers & Minders
│   ├── README.md                   # Complete DriversandMinders guide
│   ├── PHONE_LOGIN_COMPLETE.md     # Phone login implementation
│   ├── IMPLEMENTATION_STATUS.md    # Feature status tracker
│   ├── pubspec.yaml                # Flutter dependencies
│   │
│   ├── lib/
│   │   ├── main.dart               # App entry point (role detection)
│   │   │
│   │   ├── presentation/           # UI layer
│   │   │   ├── shared_login_screen/# Unified login for both roles
│   │   │   │
│   │   │   ├── driver_start_shift_screen/  # Driver: Start shift
│   │   │   ├── driver_active_trip_screen/  # Driver: Active trip with GPS
│   │   │   │   └── widgets/
│   │   │   │       ├── route_map_widget.dart      # Route visualization
│   │   │   │       ├── bus_marker_3d.dart         # 3D bus marker
│   │   │   │       ├── next_stop_widget.dart      # Next stop info
│   │   │   │       └── upcoming_stops_widget.dart # Stops list
│   │   │   │
│   │   │   ├── busminder_trip_progress_screen/# Minder: Trip view
│   │   │   └── busminder_attendance_screen/   # Minder: Mark attendance
│   │   │       └── busminder_attendance_screen/# Attendance UI
│   │   │
│   │   ├── services/               # Business logic
│   │   │   ├── api_service.dart    # HTTP client (Dio)
│   │   │   ├── driver_location_service.dart# GPS broadcasting
│   │   │   └── socket_service.dart # WebSocket (optional)
│   │   │
│   │   ├── models/                 # Data models
│   │   │   ├── user.dart           # User model
│   │   │   ├── bus.dart            # Bus model
│   │   │   ├── child.dart          # Child model
│   │   │   └── attendance.dart     # Attendance record
│   │   │
│   │   ├── widgets/                # Reusable widgets
│   │   │   ├── busminder_drawer_widget.dart # Navigation drawer
│   │   │   └── location/           # Location widgets
│   │   │
│   │   └── config/                 # Configuration
│   │       └── api_config.dart     # API endpoints
│   │
│   ├── android/                    # Android configuration
│   └── ios/                        # iOS configuration
│
├── docs/                           # Comprehensive Documentation
│   ├── API_DOCUMENTATION.md        # Complete API reference
│   ├── QUICK_START.md              # Quick start guide
│   ├── INTEGRATION_GUIDE.md        # System integration guide
│   ├── BUS_FEATURE_GUIDE.md        # Bus feature documentation
│   └── BUS_IMPLEMENTATION_SUMMARY.md# Bus implementation details
│
├── PRODUCTION_READINESS.md         # Production deployment checklist
├── REAL_TIME_BUS_TRACKING_SETUP.md # Real-time tracking setup guide
├── QUICK_START_PRODUCTION.md       # Production quick start
│
└── README.md                       # This file
```

---

## Getting Started

### Prerequisites

Ensure you have the following installed:

- **Python 3.8+** (for Django backend)
- **Node.js 16+** and **npm** (for Socket.IO and Admin dashboard)
- **Flutter 3.6.0+** and **Dart** (for mobile apps)
- **Git** (for version control)
- **PostgreSQL** (recommended for production) or **SQLite** (for development)

### Installation Guide

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd Apo_Basi
```

#### 2. Backend Setup (Django REST Framework)

```bash
# Navigate to server directory
cd server

# Create and activate virtual environment
python -m venv venv

# Activate virtual environment
# On Linux/macOS:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run database migrations
python manage.py makemigrations
python manage.py migrate

# Create superuser for admin access
python manage.py createsuperuser

# Start development server
python manage.py runserver
```

**Backend will be available at:** `http://localhost:8000`
**Admin panel:** `http://localhost:8000/admin`

#### 3. Socket.IO Server Setup

```bash
# Navigate to socket directory
cd socket

# Install dependencies
npm install

# Start Socket.IO server
node index.js
```

**Socket.IO server will run on:** `http://localhost:4000`

#### 4. Admin Dashboard Setup (React + TypeScript)

```bash
# Navigate to admin directory
cd admin

# Install dependencies
npm install

# Start development server
npm run dev
```

**Admin dashboard will be available at:** `http://localhost:5173`

**Default Admin Login:**
- Create an admin user through Django shell or use the superuser created earlier
- Access the admin panel at `/login`

---

## Admin Dashboard - Detailed Overview

The Admin Dashboard is a modern React + TypeScript web application that provides comprehensive management capabilities for the ApoBasi platform.

### Dashboard Features

#### 1. **Real-Time Dashboard**
- **Live Statistics**: Total buses, active drivers, registered children, attendance rates
- **Recent Activities**: Real-time feed of system events
- **Bus Status Overview**: Active/inactive buses with GPS status
- **Quick Actions**: Common tasks accessible from dashboard
- **Visual Analytics**: Charts and graphs for key metrics

#### 2. **Bus Management**
- **CRUD Operations**: Create, read, update, and delete buses
- **Bus Details**: Number plate, model, capacity, year, status
- **GPS Tracking**: View current location and history
- **Assignment Status**: See assigned driver and bus minder
- **Bulk Operations**: Import/export bus data
- **Search & Filter**: Find buses by plate, status, or assignment

#### 3. **User Management**
- **Multi-Role Support**: Create and manage users for all roles
  - **Parents**: Auto-generate credentials, add children during creation
  - **Drivers**: Assign license info and bus
  - **Bus Minders**: Can be assigned to multiple buses
  - **Admins**: Create additional admin accounts
- **Credential Generation**: Automatic secure username/password creation
- **User Status**: Activate/deactivate user accounts
- **Bulk Import**: CSV upload for mass user creation
- **Password Reset**: Admin-initiated password resets

#### 4. **Student (Children) Management**
- **Student Profiles**: Name, class/grade, age, parent info
- **Bus Assignment**: Assign students to buses
- **Attendance History**: View full attendance records
- **Parent Linking**: Associate students with parent accounts
- **Bulk Operations**: Import student lists
- **Search**: Find students by name, class, or parent

#### 5. **Assignment System**
- **Driver-to-Bus Assignment**: One driver per bus
- **Minder-to-Bus Assignment**: Multiple buses per minder supported
- **Child-to-Bus Assignment**: Track which students ride which bus
- **Visual Assignment Board**: Drag-and-drop interface (future)
- **Assignment History**: Track changes over time
- **Validation**: Prevent conflicting assignments

#### 6. **Attendance Tracking & Reports**
- **Daily Attendance**: View attendance for any date
- **Filter Options**: By bus, child, date range, status
- **Status Breakdown**: Present, absent, late, etc.
- **Export Reports**: PDF and CSV formats
- **Analytics**: Attendance trends and patterns
- **Parent Notifications**: Auto-notify parents of absences

#### 7. **Live Bus Tracking**
- **Real-Time Map**: See all buses on a single map
- **Individual Bus View**: Track specific bus location
- **Route Visualization**: See planned routes vs actual path
- **Status Indicators**: Moving, stopped, offline
- **Historical Playback**: Review past trips
- **Geofencing**: Set up school zones and alerts

#### 8. **Analytics & Insights**
- **Trip History**: Complete log of all trips
- **Performance Metrics**: On-time rates, delays, etc.
- **Driver Performance**: Trip completion, punctuality
- **Bus Utilization**: Capacity usage, efficiency
- **Custom Reports**: Generate specific analytics
- **Data Export**: Excel, CSV, PDF formats

### Tech Stack Highlights

**Frontend Framework:**
- **React 18.3.1** with **TypeScript 5.5.3** for type safety
- **Vite 5.4.2** for lightning-fast builds and HMR
- **Tailwind CSS 3.4.1** for utility-first styling
- **Lucide React** for consistent iconography

**State Management:**
- Custom React hooks for data fetching
- Context API for global state
- Local storage for session persistence

**API Integration:**
- **Axios 1.12.2** with interceptors for auth
- Automatic token refresh on expiry
- Request/response logging in development
- Error handling with user-friendly messages

**Routing:**
- **React Router DOM 7.9.5** for client-side routing
- Protected routes with authentication guards
- Nested routes for complex layouts
- Programmatic navigation

### Key Admin Workflows

#### Creating a New Parent Account
```typescript
1. Navigate to User Management
2. Click "Add Parent"
3. Enter parent details (name, phone)
4. Add children (name, class, age)
5. System generates secure credentials
6. Display credentials to admin (one-time view)
7. Parent can login immediately
```

#### Assigning Students to Buses
```typescript
1. Go to Assignments page
2. Select assignment type: "Child to Bus"
3. Choose student from dropdown
4. Select bus from dropdown
5. Confirm assignment
6. Student now appears on bus roster
```

#### Viewing Real-Time Bus Locations
```typescript
1. Navigate to Live Tracking
2. Map loads with all active buses
3. Click bus marker for details
4. View speed, heading, last update
5. Subscribe to specific bus for updates
```

### Security Features

- **JWT Authentication**: All requests include bearer token
- **Role-Based Access**: Admin-only routes protected
- **Token Refresh**: Automatic renewal before expiry
- **Session Timeout**: Auto-logout after inactivity
- **Audit Logging**: Track admin actions
- **HTTPS Only**: Production enforces secure connections

### Performance Optimizations

- **Code Splitting**: Lazy load routes for faster initial load
- **Asset Optimization**: Minified JS/CSS, compressed images
- **Caching Strategy**: Browser caching for static assets
- **Debounced Search**: Reduce API calls on user input
- **Pagination**: Limit data fetched per request
- **Virtual Scrolling**: Handle large lists efficiently

### Deployment Ready

- **Environment Configs**: Separate dev/staging/production
- **Build Optimization**: Tree-shaking, minification
- **CDN Compatible**: Static files can be served from CDN
- **Docker Support**: Containerized deployment option
- **CI/CD Ready**: Automated build and deployment pipelines

**For complete admin dashboard documentation, see:** [admin/README.md](admin/README.md)

---

#### 5. Mobile Apps Setup (Flutter)

##### ParentsApp

```bash
# Navigate to ParentsApp directory
cd ParentsApp

# Install Flutter dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

##### DriversandMinders App

```bash
# Navigate to DriversandMinders directory
cd DriversandMinders

# Install Flutter dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

### Environment Configuration

#### Backend Environment Variables

Create a `.env` file in the `server/` directory:

```env
# Django Settings
DEBUG=True
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1

# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/apobasi
# Or use SQLite for development:
# DATABASE_URL=sqlite:///db.sqlite3

# JWT Settings
JWT_SECRET_KEY=your-jwt-secret-here
JWT_ACCESS_TOKEN_LIFETIME=60  # minutes
JWT_REFRESH_TOKEN_LIFETIME=1440  # minutes (24 hours)

# CORS Settings
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
```

#### Admin Dashboard Configuration

Update `admin/src/services/api.ts` with correct API endpoints:

```typescript
const API_BASE_URL = 'http://localhost:8000/api';
const SOCKET_URL = 'http://localhost:4000';
```

#### Mobile Apps Configuration

Update API endpoints in Flutter apps:

**ParentsApp/lib/services/api_service.dart:**
```dart
static const String baseUrl = 'http://YOUR_LOCAL_IP:8000/api';
static const String socketUrl = 'http://YOUR_LOCAL_IP:4000';
```

**Note:** Replace `YOUR_LOCAL_IP` with your machine's local IP address (not `localhost`) when testing on physical devices.

---

## API Documentation

### Base URL

```
Development: http://localhost:8000/api
Production: https://api.apobasi.com/api
```

### Authentication

All authenticated endpoints require a JWT token in the Authorization header:

```http
Authorization: Bearer <access_token>
```

### Authentication Endpoints

#### User Login

```http
POST /api/users/login/
Content-Type: application/json

{
  "username": "user_abc12345",
  "password": "SecurePass123"
}

Response:
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "user_abc12345",
    "userType": "parent",
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

#### Parent Phone Login

```http
POST /api/parents/direct-phone-login/
Content-Type: application/json

{
  "phoneNumber": "+256700123456"
}
```

#### Token Refresh

```http
POST /api/token/refresh/
Content-Type: application/json

{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}

Response:
{
  "access": "new_access_token_here"
}
```

### Parent Endpoints

#### Get My Children

```http
GET /api/parents/my-children/
Authorization: Bearer <access_token>

Response:
{
  "children": [
    {
      "id": 1,
      "firstName": "Alice",
      "lastName": "Doe",
      "classGrade": "Grade 5",
      "assignedBus": {
        "id": 1,
        "numberPlate": "UAH 123X",
        "latitude": "0.347596",
        "longitude": "32.582520",
        "currentLocation": "Kampala Road"
      },
      "currentStatus": "On the way to school",
      "lastUpdated": "2025-11-07T08:30:00Z"
    }
  ]
}
```

#### Get Child Attendance History

```http
GET /api/parents/children/{child_id}/attendance/
Authorization: Bearer <access_token>

Response:
{
  "attendance": [
    {
      "id": 1,
      "date": "2025-11-07",
      "status": "present",
      "pickupTime": "07:15:00",
      "dropoffTime": "14:45:00",
      "notes": "On time"
    }
  ]
}
```

### Bus Minder Endpoints

#### Get My Buses

```http
GET /api/busminders/my-buses/
Authorization: Bearer <access_token>

Response:
{
  "buses": [
    {
      "id": 1,
      "numberPlate": "UAH 123X",
      "capacity": 40,
      "isActive": true,
      "childrenCount": 15
    }
  ]
}
```

#### Get Children on Bus

```http
GET /api/busminders/buses/{bus_id}/children/
Authorization: Bearer <access_token>

Response:
{
  "children": [
    {
      "id": 1,
      "firstName": "Alice",
      "lastName": "Doe",
      "classGrade": "Grade 5",
      "parent": {
        "name": "John Doe",
        "phoneNumber": "+256700123456"
      },
      "todayAttendance": {
        "status": "present",
        "lastUpdated": "2025-11-07T07:15:00Z"
      }
    }
  ]
}
```

#### Mark Attendance

```http
POST /api/busminders/mark-attendance/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "childId": 1,
  "status": "present",
  "notes": "Boarded at 7:15 AM"
}

Response:
{
  "success": true,
  "attendance": {
    "id": 123,
    "childId": 1,
    "status": "present",
    "timestamp": "2025-11-07T07:15:00Z"
  }
}
```

**Status Options:**
- `not_on_bus`
- `on_bus`
- `at_school`
- `on_way_home`
- `dropped_off`
- `absent`

### Driver Endpoints

#### Get My Bus

```http
GET /api/drivers/my-bus/
Authorization: Bearer <access_token>

Response:
{
  "id": 1,
  "numberPlate": "UAH 123X",
  "model": "Toyota Coaster",
  "capacity": 40,
  "isActive": true,
  "currentLocation": "Kampala Road",
  "latitude": "0.347596",
  "longitude": "32.582520",
  "childrenCount": 15
}
```

#### Get My Route

```http
GET /api/drivers/my-route/
Authorization: Bearer <access_token>

Response:
{
  "bus": {...},
  "route": [
    {
      "childName": "Alice Doe",
      "classGrade": "Grade 5",
      "parentName": "John Doe",
      "parentContact": "+256700123456",
      "attendanceStatus": "On the way to school"
    }
  ]
}
```

### Admin Endpoints

All admin endpoints require `IsAdmin` or `IsSuperuser` permission.

#### Create Parent Account

```http
POST /api/admins/add-parent/
Authorization: Bearer <admin_access_token>
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+256700123456",
  "children": [
    {
      "firstName": "Alice",
      "lastName": "Doe",
      "classGrade": "Grade 5",
      "age": 10
    }
  ]
}

Response:
{
  "parent": {
    "id": 1,
    "username": "parent_abc12345",
    "password": "GeneratedPass123",
    "firstName": "John",
    "lastName": "Doe"
  },
  "children": [...]
}
```

#### Assign Driver to Bus

```http
POST /api/admins/assign-driver/
Authorization: Bearer <admin_access_token>
Content-Type: application/json

{
  "driverId": 1,
  "busId": 1
}
```

#### Assign Bus Minder to Bus

```http
POST /api/admins/assign-busminder/
Authorization: Bearer <admin_access_token>
Content-Type: application/json

{
  "busminderId": 1,
  "busId": 1
}
```

#### Assign Child to Bus

```http
POST /api/admins/assign-child/
Authorization: Bearer <admin_access_token>
Content-Type: application/json

{
  "childId": 1,
  "busId": 1
}
```

### Bus Endpoints

#### List All Buses

```http
GET /api/buses/
Authorization: Bearer <access_token>

Response:
{
  "count": 10,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "numberPlate": "UAH 123X",
      "busNumber": "BUS-001",
      "capacity": 40,
      "model": "Toyota Coaster",
      "year": 2020,
      "isActive": true,
      "latitude": "0.347596",
      "longitude": "32.582520",
      "currentLocation": "Kampala Road",
      "lastUpdated": "2025-11-07T08:30:00Z"
    }
  ]
}
```

#### Create Bus

```http
POST /api/buses/
Authorization: Bearer <admin_access_token>
Content-Type: application/json

{
  "busNumber": "BUS-002",
  "numberPlate": "UAH 456Y",
  "capacity": 40,
  "model": "Mercedes-Benz Sprinter",
  "year": 2021
}
```

#### Update Bus Location (Real-Time)

This is typically done via Socket.IO, but can also be done via REST:

```http
PATCH /api/buses/{bus_id}/
Authorization: Bearer <driver_access_token>
Content-Type: application/json

{
  "latitude": "0.347596",
  "longitude": "32.582520",
  "speed": 45,
  "heading": 180
}
```

---

## Data Flow & Real-Time Architecture

### Real-Time GPS Tracking Flow

```
┌─────────────────┐
│  Driver App     │
│  (Flutter)      │
└────────┬────────┘
         │
         │ 1. Geolocator gets GPS coordinates every 5 seconds
         │
         ▼
┌─────────────────────────────────────────────────┐
│  Socket.IO emit "driver_location_room"          │
│  {                                              │
│    busId: 1,                                    │
│    latitude: 0.347596,                          │
│    longitude: 32.582520,                        │
│    speed: 45,                                   │
│    heading: 180                                 │
│  }                                              │
└────────┬────────────────────────────────────────┘
         │
         │ 2. WebSocket connection to Socket.IO server
         │
         ▼
┌─────────────────────────────────────────────────┐
│  Socket.IO Server (Node.js)                     │
│  Port: 4000                                     │
│                                                 │
│  • Stores location in memory (busLocations map) │
│  • Broadcasts to room "bus_{busId}"            │
└────────┬────────────────────────────────────────┘
         │
         │ 3. Broadcast "bus_update" event to all subscribers
         │
         ▼
┌─────────────────┐
│  Parent App     │
│  (Flutter)      │
│                 │
│  • Listening on │
│    "bus_update" │
│  • Updates map  │
│    marker       │
└─────────────────┘
```

### Authentication Flow

```
┌──────────────┐
│  Client App  │
└──────┬───────┘
       │
       │ POST /api/users/login/ {username, password}
       │
       ▼
┌──────────────────────────────────────────┐
│  Django Backend                          │
│                                          │
│  1. Validate credentials                 │
│  2. Generate JWT access token (60 min)  │
│  3. Generate JWT refresh token (24 hrs) │
└──────┬───────────────────────────────────┘
       │
       │ Returns {access, refresh, user}
       │
       ▼
┌──────────────────────────────────────────┐
│  Client App                              │
│                                          │
│  • Store tokens in:                      │
│    - SharedPreferences (Flutter)         │
│    - localStorage (Web)                  │
│                                          │
│  • Include in all requests:              │
│    Authorization: Bearer <access_token>  │
└──────────────────────────────────────────┘
```

### Offline-First Attendance Flow

```
┌─────────────────┐
│  Bus Minder App │
└────────┬────────┘
         │
         │ 1. Mark child attendance (offline or online)
         │
         ▼
┌─────────────────────────────────────────┐
│  Local Storage (SharedPreferences)      │
│                                         │
│  • Queue attendance updates             │
│  • Store timestamp and data             │
└────────┬────────────────────────────────┘
         │
         │ 2. Check network connectivity
         │
         ▼
┌─────────────────────────────────────────┐
│  IF ONLINE:                             │
│    POST /api/busminders/mark-attendance/│
│    • Sync queued updates                │
│    • Clear local queue on success       │
│                                         │
│  IF OFFLINE:                            │
│    • Keep in queue                      │
│    • Retry when connection restored     │
└─────────────────────────────────────────┘
```

### Real-Time Bus Location Tracking (Detailed)

The ApoBasi platform implements a sophisticated real-time GPS tracking system with sub-second latency:

#### System Components

**1. Driver App (GPS Source)**
- Uses `geolocator` package for high-accuracy GPS
- Broadcasts location every 5-10 seconds while moving
- Sends via HTTP POST to Django backend
- Includes: latitude, longitude, speed, heading, timestamp

**2. Django Backend (Location Processor)**
- Receives location via `POST /api/buses/push-location/`
- Validates driver authentication and bus assignment
- Stores in PostgreSQL (`BusLocationHistory` table)
- Caches in Redis with 60-second TTL
- Publishes to Redis pub/sub channel
- Forwards to Socket.IO server via HTTP POST

**3. Socket.IO Server (Real-Time Broadcaster)**
- Node.js server on port 3000
- Receives location from Django
- Broadcasts to subscribed parents via WebSocket
- Room-based subscription (e.g., `bus_1` room)
- JWT authentication for parents

**4. Parents App (Real-Time Consumer)**
- Connects to Socket.IO server via WebSocket
- Subscribes to child's bus updates
- Displays 3D bus marker on map
- Marker rotates based on GPS heading
- Shows "LIVE" badge when receiving updates

#### Data Flow Sequence

```
Step 1: Driver starts trip
└─> Driver App obtains GPS coordinates

Step 2: Location broadcast (every 5-10 seconds)
└─> HTTP POST to Django: /api/buses/push-location/
    Body: { lat: 9.0820, lng: 7.5340, speed: 45, heading: 180 }

Step 3: Django processes location
├─> Validate driver token (JWT)
├─> Check driver.assigned_bus exists
├─> Save to BusLocationHistory table
├─> Cache in Redis: bus:1:location (60s TTL)
├─> Publish to Redis channel: location_updates
└─> HTTP POST to Socket.IO: /api/notify/location-update

Step 4: Socket.IO broadcasts
├─> Parse location data
├─> Emit to room: bus_1
└─> Event: location_update

Step 5: Parents receive update
├─> Socket.IO client in Parents App
├─> Event listener: socket.on('location_update')
├─> Update map marker position
└─> Rotate marker based on heading
```

#### Advanced Features

**3D Bus Markers**
- Custom-designed yellow school bus icon
- Real-time rotation based on GPS heading (0-360°)
- Smooth animation between position updates
- "LIVE" badge when actively receiving updates
- Connection status indicator (green/red dot)

**Location Accuracy**
- High precision: 12 digits with 8 decimal places
- Accuracy: ~1-2 meters in optimal conditions
- GPS coordinates: WGS 84 datum
- Speed: km/h, calculated from GPS
- Heading: degrees from true north

**Offline Handling**
- Driver: Queues locations if offline, syncs when reconnected
- Parents: Shows last known location with timestamp
- Connection status clearly indicated on UI
- Auto-reconnect with exponential backoff

**Performance Optimizations**
- Distance filter: Only update if moved >10 meters
- Speed-based interval: Slower updates when stationary
- Redis caching reduces database load
- WebSocket keeps persistent connection (low overhead)

**Battery Optimization (Driver App)**
- Reduce GPS polling when speed < 1 km/h
- Increase interval to 30 seconds when stationary
- Location updates stop when shift ends
- Foreground-only tracking (background service disabled)

#### WebSocket Events

**Parent → Socket.IO Server:**
```javascript
// Subscribe to bus location updates
socket.emit('subscribe_bus', {
  busId: 1,
  token: 'Bearer eyJ0eXAiOiJKV1QiLCJhbGc...'
});

// Response
socket.on('subscribed', { busId: 1, success: true });
```

**Socket.IO Server → Parent:**
```javascript
// Real-time location update
socket.on('location_update', {
  busId: 1,
  bus_number: "KAA 123B",
  latitude: -1.286389,
  longitude: 36.817223,
  speed: 45,
  heading: 180,
  timestamp: "2025-12-03T10:30:45Z"
});
```

#### Database Schema

**BusLocationHistory** (PostgreSQL)
```sql
CREATE TABLE buses_buslocationhistory (
    id SERIAL PRIMARY KEY,
    bus_id INTEGER REFERENCES buses_bus(id),
    latitude DECIMAL(12, 8) NOT NULL,
    longitude DECIMAL(12, 8) NOT NULL,
    speed DECIMAL(5, 2) DEFAULT 0.0,
    heading DECIMAL(5, 2) DEFAULT 0.0,
    accuracy DECIMAL(6, 2),
    timestamp TIMESTAMP DEFAULT NOW(),
    INDEX idx_bus_timestamp (bus_id, timestamp DESC)
);
```

#### Redis Architecture

**Caching Strategy:**
```
Key Pattern: bus:{bus_id}:location
Value: JSON string of latest location
TTL: 60 seconds (auto-expires if driver stops sending)

Pub/Sub Channel: location_updates
Subscribers: Socket.IO server
Purpose: Real-time notification of new locations
```

**For complete real-time tracking setup, see:** [REAL_TIME_BUS_TRACKING_SETUP.md](REAL_TIME_BUS_TRACKING_SETUP.md)

---

## Security & Authentication

### Authentication Strategy

- **JWT (JSON Web Tokens)**: Stateless authentication for scalability
- **Access Token**: 60-minute lifetime for API requests
- **Refresh Token**: 24-hour lifetime for obtaining new access tokens
- **Secure Storage**: Tokens stored securely on client devices

### Authorization & Permissions

#### Custom Permission Classes

Located in `server/users/permissions.py`:

```python
class IsParent(BasePermission):
    """Only allows access to users with user_type = 'parent'"""

class IsDriver(BasePermission):
    """Only allows access to users with user_type = 'driver'"""

class IsBusMinder(BasePermission):
    """Only allows access to users with user_type = 'busminder'"""

class IsAdmin(BasePermission):
    """Only allows access to admin users"""
```

#### Role-Based Access Control (RBAC)

| User Type | Permissions |
|-----------|-------------|
| **Parent** | View own children, view attendance, track bus location |
| **Driver** | View assigned bus, view route, broadcast location |
| **Bus Minder** | View assigned buses, mark attendance, view children |
| **Admin** | Full system access, user management, assignments |

### Data Isolation

- **Parents** can only access their own children's data
- **Drivers** can only see their assigned bus
- **Bus Minders** can only manage children on their assigned buses
- **Cross-tenant access** is blocked at the database query level

### Security Best Practices

1. **Password Security**
   - Django's built-in password hashing (PBKDF2)
   - Auto-generated secure passwords for new users
   - Password reset functionality

2. **CORS Configuration**
   - Whitelist specific origins only
   - No wildcard (`*`) in production

3. **Input Validation**
   - DRF serializer validation
   - Type checking with TypeScript (frontend)
   - SQL injection prevention via ORM

4. **HTTPS in Production**
   - All production traffic over HTTPS
   - Secure cookie flags enabled
   - HSTS headers configured

---

## Development Workflow

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/add-trip-history

# Make changes and commit
git add .
git commit -m "feat: Add trip history endpoint"

# Push to remote
git push origin feature/add-trip-history

# Create pull request on GitHub/GitLab
```

### Code Style Guidelines

#### Python (Backend)
- Follow **PEP 8** style guide
- Use **Black** for formatting
- Use **flake8** for linting
- Use **type hints** where applicable

```bash
# Format code
black .

# Lint code
flake8 .
```

#### TypeScript (Admin Dashboard)
- Follow **ESLint** rules
- Use **Prettier** for formatting
- Strict TypeScript mode enabled

```bash
# Lint code
npm run lint

# Type check
npm run typecheck
```

#### Dart (Flutter Apps)
- Follow **Dart style guide**
- Use **flutter_lints** package
- Run formatter before committing

```bash
# Format code
flutter format .

# Analyze code
flutter analyze
```

### Database Migrations

#### Creating Migrations

```bash
# After modifying models in Django
python manage.py makemigrations

# Review generated migration files
# Then apply migrations
python manage.py migrate
```

#### Migration Best Practices

1. **Never edit migration files manually** unless absolutely necessary
2. **Always review migrations** before applying to production
3. **Test migrations** on a copy of production data
4. **Backup database** before running migrations in production

### Adding New Features

#### Backend (Django)

1. Create new app if needed: `python manage.py startapp feature_name`
2. Define models in `models.py`
3. Create serializers in `serializers.py`
4. Write views in `views.py`
5. Add URL routes in `urls.py`
6. Create and run migrations
7. Test endpoints with Postman/Insomnia

#### Frontend (React)

1. Create new page component in `src/pages/`
2. Create reusable components in `src/components/`
3. Add API service function in `src/services/`
4. Create custom hook if needed in `src/hooks/`
5. Add route in `App.tsx`
6. Test in browser

#### Mobile (Flutter)

1. Create new screen in `lib/screens/`
2. Add API method in `lib/services/api_service.dart`
3. Create models if needed in `lib/models/`
4. Update navigation in `main.dart`
5. Test on emulator and physical device

---

## Testing Strategy

### Backend Testing (Django)

```bash
# Run all tests
python manage.py test

# Run specific app tests
python manage.py test users

# Run with coverage
pip install coverage
coverage run --source='.' manage.py test
coverage report
```

#### Test Structure

```python
# server/users/tests.py
from django.test import TestCase
from rest_framework.test import APIClient
from .models import User

class UserAuthenticationTestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123',
            user_type='parent'
        )

    def test_user_login(self):
        response = self.client.post('/api/users/login/', {
            'username': 'testuser',
            'password': 'testpass123'
        })
        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.json())
```

### Frontend Testing (React)

```bash
# Run tests
npm test

# Run with coverage
npm test -- --coverage
```

### Mobile Testing (Flutter)

```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Manual Testing Checklist

- [ ] User authentication (all roles)
- [ ] Parent can view children
- [ ] Driver can broadcast location
- [ ] Bus minder can mark attendance
- [ ] Admin can create users and assignments
- [ ] Real-time location updates
- [ ] Offline mode functionality
- [ ] Permission enforcement

---

## Deployment

### Production Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Load Balancer / CDN                  │
│                    (Nginx / Cloudflare)                  │
└────────┬────────────────────────────┬────────────────────┘
         │                            │
         │                            │
┌────────▼────────┐          ┌────────▼────────┐
│  Django Backend │          │  React Admin    │
│  (Gunicorn +    │          │  (Static Files) │
│   Nginx)        │          │                 │
│  Port: 8000     │          │                 │
└────────┬────────┘          └─────────────────┘
         │
         │
┌────────▼────────────────────────────────┐
│  PostgreSQL Database                    │
│  (AWS RDS / DigitalOcean Managed DB)    │
└─────────────────────────────────────────┘
```

### Backend Deployment (Django)

#### Using Gunicorn + Nginx

```bash
# Install Gunicorn
pip install gunicorn

# Run with Gunicorn
gunicorn Apo_Basi.wsgi:application --bind 0.0.0.0:8000 --workers 4
```

#### Nginx Configuration

```nginx
server {
    listen 80;
    server_name api.apobasi.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /path/to/Apo_Basi/server/staticfiles/;
    }
}
```

#### Environment Variables for Production

```env
DEBUG=False
SECRET_KEY=production-secret-key-here
ALLOWED_HOSTS=api.apobasi.com,www.apobasi.com
DATABASE_URL=postgresql://user:password@db-host:5432/apobasi
CORS_ALLOWED_ORIGINS=https://admin.apobasi.com,https://apobasi.com
```

### Admin Dashboard Deployment

```bash
# Build for production
npm run build

# Deploy dist/ folder to:
# - Vercel
# - Netlify
# - AWS S3 + CloudFront
# - Any static hosting service
```

### Socket.IO Deployment

```bash
# Use PM2 for process management
npm install -g pm2

# Start server
pm2 start index.js --name apobasi-socket

# Set up auto-restart
pm2 startup
pm2 save
```

### Mobile App Deployment

#### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Google Play)
flutter build appbundle --release
```

#### iOS

```bash
# Build for iOS
flutter build ios --release

# Then archive and upload via Xcode
```

### Database Backup Strategy

```bash
# Automated daily backups
pg_dump -h localhost -U postgres apobasi > backup_$(date +%Y%m%d).sql

# Restore from backup
psql -h localhost -U postgres apobasi < backup_20251107.sql
```

---

## Performance Considerations

### Backend Optimization

1. **Database Query Optimization**
   - Use `select_related()` and `prefetch_related()` to reduce queries
   - Add database indexes on frequently queried fields
   - Use pagination for large datasets

```python
# Example: Optimized query
buses = Bus.objects.select_related('driver', 'bus_minder').prefetch_related('children')
```

2. **Caching Strategy**
   - Use Redis for frequently accessed data
   - Cache bus locations in memory
   - Cache user sessions

3. **API Rate Limiting**
   - Implement rate limiting to prevent abuse
   - Use DRF throttling classes

### Frontend Optimization

1. **Code Splitting**
   - Lazy load routes with React.lazy()
   - Split vendor bundles

2. **Asset Optimization**
   - Compress images
   - Use WebP format
   - Implement lazy loading for images

### Mobile Optimization

1. **Location Update Frequency**
   - Balance accuracy vs battery life
   - Reduce GPS polling when stationary

2. **Data Synchronization**
   - Batch API requests
   - Use delta sync for large datasets
   - Implement exponential backoff for retries

---

## Troubleshooting

### Common Issues

#### Backend Issues

**Problem:** Database connection errors

```bash
# Solution: Check database settings
python manage.py dbshell

# Verify migrations are up to date
python manage.py showmigrations
```

**Problem:** CORS errors in browser

```python
# Solution: Update settings.py
CORS_ALLOWED_ORIGINS = [
    "http://localhost:5173",
    "http://localhost:3000",
]
```

#### Frontend Issues

**Problem:** API requests failing

```typescript
// Solution: Check API base URL in api.ts
console.log('API Base URL:', API_BASE_URL);

// Verify token is being sent
console.log('Authorization header:', axios.defaults.headers.common['Authorization']);
```

#### Mobile Issues

**Problem:** Cannot connect to backend from physical device

```dart
// Solution: Use your machine's local IP, not localhost
static const String baseUrl = 'http://192.168.1.100:8000/api';
```

**Problem:** Location not updating

```dart
// Solution: Check permissions in AndroidManifest.xml and Info.plist
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Logs & Debugging

#### Backend Logs

```bash
# Django development server logs
python manage.py runserver --verbosity 2

# Check Django logs in production
tail -f /var/log/django/apobasi.log
```

#### Socket.IO Logs

```javascript
// Enable debug mode in index.js
const io = require('socket.io')(server, {
  cors: { origin: '*' },
  transports: ['websocket', 'polling'],
  debug: true
});
```

#### Flutter Logs

```bash
# View real-time logs
flutter logs

# Verbose output
flutter run -v
```

---

## Contributing

We welcome contributions from developers, designers, and educators! Here's how you can help:

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'feat: Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Commit Message Convention

Follow **Conventional Commits** specification:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting)
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Maintenance tasks

### Code Review Process

1. All PRs require at least one approval
2. All tests must pass
3. Code must follow style guidelines
4. Documentation must be updated

---

## Documentation

Comprehensive documentation is available throughout the repository:

### Component-Specific Documentation

**Admin Dashboard:**
- **[admin/README.md](admin/README.md)** - Complete admin dashboard guide with features, API integration, and deployment

**Mobile Applications:**
- **[ParentsApp/README.md](ParentsApp/README.md)** - Parents app guide with real-time tracking, architecture, and features
- **[ParentsApp/BUS_MARKER_DESIGN_GUIDE.md](ParentsApp/BUS_MARKER_DESIGN_GUIDE.md)** - Custom 3D bus marker implementation
- **[DriversandMinders/README.md](DriversandMinders/README.md)** - Drivers and minders app with GPS broadcasting and offline attendance
- **[DriversandMinders/PHONE_LOGIN_COMPLETE.md](DriversandMinders/PHONE_LOGIN_COMPLETE.md)** - Phone-based authentication setup
- **[DriversandMinders/IMPLEMENTATION_STATUS.md](DriversandMinders/IMPLEMENTATION_STATUS.md)** - Feature implementation tracker

**Backend:**
- **[server/SETUP.md](server/SETUP.md)** - Backend setup and configuration
- **[server/assignments/API_DOCUMENTATION.md](server/assignments/API_DOCUMENTATION.md)** - Assignment API endpoints

### Feature Documentation

- **[docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)** - Complete API reference for all endpoints
- **[docs/QUICK_START.md](docs/QUICK_START.md)** - Quick start guide for developers
- **[docs/INTEGRATION_GUIDE.md](docs/INTEGRATION_GUIDE.md)** - System integration and architecture
- **[docs/BUS_FEATURE_GUIDE.md](docs/BUS_FEATURE_GUIDE.md)** - Bus management features
- **[docs/BUS_IMPLEMENTATION_SUMMARY.md](docs/BUS_IMPLEMENTATION_SUMMARY.md)** - Bus feature implementation details

### Setup & Deployment

- **[REAL_TIME_BUS_TRACKING_SETUP.md](REAL_TIME_BUS_TRACKING_SETUP.md)** - Complete real-time tracking setup with Redis, Socket.IO, and troubleshooting
- **[PRODUCTION_READINESS.md](PRODUCTION_READINESS.md)** - Production deployment checklist, monitoring, and security
- **[QUICK_START_PRODUCTION.md](QUICK_START_PRODUCTION.md)** - Production quick start guide

---

## Production Readiness

### System Status

✅ **Completed Features:**
- Real-time GPS tracking with Socket.IO
- JWT authentication across all services
- Role-based access control (RBAC)
- Offline-first attendance management
- 3D bus markers with rotation
- Parent phone-based login
- Admin dashboard with full CRUD operations
- Mobile apps for iOS and Android
- Database migrations and schema optimization

⚠️ **Known Limitations:**
- **Background GPS Tracking**: Driver app requires foreground operation (no background service)
  - Workaround: Keep app open during trips, use screen pinning
  - Future: Native Android/iOS background service implementation
- **Push Notifications**: Not yet implemented (scheduled for Phase 2)
- **SMS Alerts**: Notification system in development

### Production Deployment Checklist

#### Infrastructure Requirements

**Servers:**
- Django Backend: 2GB RAM, 2 CPU cores minimum
- Socket.IO Server: 1GB RAM, 1 CPU core
- PostgreSQL: 2GB RAM, SSD storage recommended
- Redis: 512MB RAM minimum
- Nginx/Load Balancer for SSL termination

**Third-Party Services:**
- Google Maps API key (for mobile apps)
- SMS gateway (for parent notifications - optional)
- CDN for static assets (recommended)
- Monitoring service (e.g., Sentry, DataDog)

#### Pre-Deployment Steps

**Backend (Django):**
```bash
# Update environment variables
DEBUG=False
SECRET_KEY=<strong-random-key>
ALLOWED_HOSTS=your-domain.com,www.your-domain.com
DATABASE_URL=postgresql://user:pass@host:5432/apobasi
REDIS_HOST=your-redis-host
SOCKETIO_SERVER_URL=https://socket.your-domain.com

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --no-input

# Create superuser
python manage.py createsuperuser

# Start with Gunicorn
gunicorn Apo_Basi.wsgi:application --bind 0.0.0.0:8000 --workers 4
```

**Socket.IO Server:**
```bash
# Update .env
NODE_ENV=production
SOCKET_PORT=3000
DJANGO_API_URL=https://api.your-domain.com
JWT_SECRET=<same-as-django-secret>
REDIS_HOST=your-redis-host

# Use PM2 for process management
pm2 start server.js --name socketio-server
pm2 startup
pm2 save
```

**Mobile Apps:**
```bash
# Update API endpoints in config files
# ParentsApp/lib/config/api_config.dart
# DriversandMinders/lib/config/api_config.dart

# Build release versions
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build appbundle --release  # Google Play
```

#### Security Configuration

**SSL/TLS:**
- Enable HTTPS on all domains
- Use Let's Encrypt or commercial SSL certificates
- Configure HSTS headers
- Enforce secure WebSocket connections (wss://)

**Environment Variables:**
- Never commit `.env` files to version control
- Use secure secret management (AWS Secrets Manager, HashiCorp Vault)
- Rotate keys and tokens regularly

**CORS Settings:**
```python
# Django settings.py
CORS_ALLOWED_ORIGINS = [
    "https://admin.your-domain.com",
    "https://www.your-domain.com",
]
CORS_ALLOW_CREDENTIALS = True
```

**Rate Limiting:**
```python
# Implement API rate limiting
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour'
    }
}
```

#### Monitoring & Logging

**Application Monitoring:**
- **Sentry** for error tracking and crash reporting
- **DataDog/New Relic** for performance monitoring
- **Google Analytics** for user behavior (mobile apps)
- **Firebase Crashlytics** for mobile crash reports

**Server Monitoring:**
- CPU, memory, disk usage
- Database connection pool status
- Redis memory usage and hit rate
- Socket.IO connection count and message throughput

**Key Metrics to Track:**
- API response times (p50, p95, p99)
- Location broadcast latency
- WebSocket connection stability
- Database query performance
- App crash rates and ANR (Application Not Responding)

**Logging Strategy:**
```python
# Django logging configuration
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/var/log/apobasi/django.log',
            'maxBytes': 1024*1024*15,  # 15MB
            'backupCount': 10,
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}
```

#### Database Optimization

**Indexes:**
```sql
-- Critical indexes for performance
CREATE INDEX idx_bus_location_history_bus_timestamp
ON buses_buslocationhistory(bus_id, timestamp DESC);

CREATE INDEX idx_attendance_child_date
ON attendance_attendance(child_id, date DESC);

CREATE INDEX idx_assignments_bus
ON assignments_assignment(bus_id, is_active);
```

**Backup Strategy:**
```bash
# Automated daily backups
0 2 * * * pg_dump -h localhost -U postgres apobasi > /backups/apobasi_$(date +\%Y\%m\%d).sql

# Retention: Keep last 30 days
find /backups -name "apobasi_*.sql" -mtime +30 -delete
```

#### Performance Targets

**Backend API:**
- Average response time: < 200ms
- 95th percentile: < 500ms
- Location push endpoint: < 100ms
- Concurrent users: 1000+

**Mobile Apps:**
- App startup time: < 3 seconds
- Location update frequency: 5-10 seconds
- Map rendering: 60 FPS
- Battery drain: < 10% per hour (driver app during active trip)

**Real-Time System:**
- WebSocket connection time: < 2 seconds
- Location broadcast latency: < 100ms
- Socket.IO server: Support 1000+ concurrent connections
- Redis pub/sub latency: < 50ms

### Testing Before Production

**Load Testing:**
```bash
# Use Apache Bench or Artillery for API load testing
ab -n 1000 -c 100 https://api.your-domain.com/api/buses/

# Socket.IO load testing
artillery run socketio-load-test.yml
```

**Mobile Testing:**
- Test on low-end Android devices (2GB RAM)
- Test iOS on older devices (iPhone 8 or equivalent)
- Test with poor network conditions (3G, high latency)
- Test GPS accuracy in various locations (urban, rural)
- Battery drain tests (8-hour shifts for drivers)

**Integration Testing:**
- Multiple parents viewing same bus simultaneously
- Driver switching buses mid-trip
- Network interruptions and reconnections
- Database failover scenarios
- Redis cache expiration handling

### Rollback Plan

**Version Control:**
- Tag releases: `git tag -a v1.0.0 -m "Production release 1.0.0"`
- Keep previous 3 releases available
- Document database schema changes for each release

**Database Migrations:**
- Always backup before migrations
- Test migrations on staging with production data copy
- Have rollback SQL scripts prepared
- Use Django's `sqlmigrate` to review SQL before applying

**Mobile Apps:**
- Keep APK/IPA of previous version
- Google Play/App Store rollback capabilities
- Staged rollout (release to 10% users first)
- Monitor crash reports during rollout

**For complete production guide, see:** [PRODUCTION_READINESS.md](PRODUCTION_READINESS.md)

---

## Roadmap

### Phase 1 (Current)
- [x] User authentication system
- [x] Real-time GPS tracking
- [x] Attendance management
- [x] Admin dashboard
- [x] Mobile apps for parents and staff

### Phase 2 (Q1 2026)
- [ ] Push notifications
- [ ] Trip history and analytics
- [ ] Multi-school support
- [ ] Invoice and billing system
- [ ] SMS alerts for parents

### Phase 3 (Q2 2026)
- [ ] AI-powered route optimization
- [ ] Predictive arrival times
- [ ] Parent feedback system
- [ ] Driver performance metrics
- [ ] Expansion to additional countries

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## Support

For questions, issues, or feature requests:

- **GitHub Issues**: [Create an issue](https://github.com/yourusername/apobasi/issues)
- **Email**: support@apobasi.com
- **Documentation**: [docs.apobasi.com](https://docs.apobasi.com)

---

## Acknowledgments

- Built with love for African schools and families
- Designed for the unique challenges of African infrastructure
- Empowering safe, transparent, and modern school transportation

---

<div align="center">

**ApoBasi - Empowering Safe School Transport for Africa**

Made with ❤️ by the ApoBasi Team

</div>
