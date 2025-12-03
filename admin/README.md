# ApoBasi Admin Dashboard - React + TypeScript

<div align="center">

**Modern Web Dashboard for School Bus Management**

[![React](https://img.shields.io/badge/React-18.3.1-blue.svg)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.5.3-blue.svg)](https://www.typescriptlang.org/)
[![Vite](https://img.shields.io/badge/Vite-5.4.2-purple.svg)](https://vitejs.dev/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-3.4.1-38B2AC.svg)](https://tailwindcss.com/)

</div>

---

## Overview

The ApoBasi Admin Dashboard is a modern, type-safe React application built with TypeScript and Vite. It provides school administrators with a comprehensive interface to manage buses, users, assignments, attendance, and real-time tracking.

### Key Features

- **Real-Time Dashboard**: Live statistics and metrics
- **Bus Management**: CRUD operations for school buses
- **User Management**: Create and manage parents, drivers, and bus minders
- **Assignment System**: Assign drivers, minders, and children to buses
- **Attendance Reports**: View and analyze attendance data
- **Analytics**: Trip history and performance metrics
- **Type-Safe**: Full TypeScript support for reliability
- **Responsive Design**: Works on all screen sizes
- **Fast Build**: Vite for lightning-fast HMR and builds

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Key Features](#key-features-in-detail)
- [API Integration](#api-integration)
- [Routing](#routing)
- [State Management](#state-management)
- [Styling](#styling)
- [Building for Production](#building-for-production)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- **Node.js**: Version 16 or higher
- **npm**: Version 7 or higher (comes with Node.js)
- **Backend API**: ApoBasi Django backend running on port 8000
- **Modern Browser**: Chrome, Firefox, Safari, or Edge

---

## Installation

### 1. Navigate to Admin Directory

```bash
cd Apo_Basi/admin
```

### 2. Install Dependencies

```bash
# Install all packages
npm install

# Or use yarn
yarn install
```

### 3. Configure API Endpoint

Edit `src/services/api.ts`:

```typescript
// Development
const API_BASE_URL = 'http://localhost:8000/api';

// Production
// const API_BASE_URL = 'https://api.apobasi.com/api';

export default API_BASE_URL;
```

### 4. Run Development Server

```bash
# Start dev server with hot reload
npm run dev

# Server will start on http://localhost:5173
```

### 5. Build for Production

```bash
# Create optimized production build
npm run build

# Preview production build locally
npm run preview
```

---

## Project Structure

```
admin/
│
├── src/
│   ├── main.tsx               # React entry point
│   ├── App.tsx                # Root component with routing
│   ├── index.css              # Global styles
│   │
│   ├── pages/                 # Page components
│   │   ├── Dashboard.tsx              # Main dashboard
│   │   ├── Login.tsx                  # Login page
│   │   ├── BusManagement.tsx          # Bus CRUD
│   │   ├── UserManagement.tsx         # User admin
│   │   ├── ChildManagement.tsx        # Children management
│   │   ├── AssignmentsPage.tsx        # Resource assignments
│   │   ├── AttendancePage.tsx         # Attendance tracking
│   │   ├── AnalyticsPage.tsx          # Reports & analytics
│   │   └── TrackingPage.tsx           # Live bus tracking
│   │
│   ├── components/            # Reusable components
│   │   ├── Layout.tsx                 # Page layout wrapper
│   │   ├── PrivateRoute.tsx           # Auth guard
│   │   ├── Sidebar.tsx                # Navigation sidebar
│   │   ├── Header.tsx                 # Top navigation bar
│   │   ├── LoadingSpinner.tsx         # Loading indicator
│   │   └── Modal.tsx                  # Modal dialog
│   │
│   ├── hooks/                 # Custom React hooks
│   │   ├── useBuses.ts                # Bus data hook
│   │   ├── useUsers.ts                # User data hook
│   │   ├── useChildren.ts             # Children data hook
│   │   └── useAuth.ts                 # Authentication hook
│   │
│   ├── services/              # API service layer
│   │   ├── api.ts                     # Axios instance
│   │   ├── busService.ts              # Bus API calls
│   │   ├── userService.ts             # User API calls
│   │   ├── childService.ts            # Child API calls
│   │   ├── assignmentService.ts       # Assignment API calls
│   │   └── authService.ts             # Auth API calls
│   │
│   ├── types/                 # TypeScript type definitions
│   │   └── index.ts                   # Shared types
│   │
│   └── utils/                 # Utility functions
│       ├── constants.ts               # App constants
│       └── helpers.ts                 # Helper functions
│
├── public/                    # Static assets
│   └── favicon.ico
│
├── dist/                      # Production build output
│
├── index.html                 # HTML entry point
├── package.json               # Dependencies
├── tsconfig.json              # TypeScript config
├── vite.config.ts             # Vite configuration
├── tailwind.config.js         # Tailwind CSS config
├── postcss.config.js          # PostCSS config
└── README.md                  # This file
```

---

## Architecture

### Layered Architecture

```
┌─────────────────────────────────────┐
│       Presentation Layer            │
│   (Pages, Components, UI)           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│       Business Logic Layer          │
│   (Custom Hooks, State Management)  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│       Service Layer                 │
│   (API Services, HTTP Client)       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│       Backend API                   │
│   (Django REST Framework)           │
└─────────────────────────────────────┘
```

### Component Hierarchy

```
App
├── Login
└── Layout (Protected)
    ├── Sidebar
    ├── Header
    └── Main Content
        ├── Dashboard
        ├── BusManagement
        ├── UserManagement
        ├── ChildManagement
        ├── AssignmentsPage
        ├── AttendancePage
        ├── AnalyticsPage
        └── TrackingPage
```

---

## Key Features in Detail

### 1. Dashboard

**File:** `src/pages/Dashboard.tsx`

Displays key metrics:
- Total buses
- Active drivers
- Registered children
- Today's attendance rate
- Recent activities
- Live bus status

```tsx
// Example usage
const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);

  useEffect(() => {
    fetchDashboardStats().then(setStats);
  }, []);

  return (
    <div className="grid grid-cols-4 gap-6">
      <StatCard title="Total Buses" value={stats?.totalBuses} />
      <StatCard title="Active Drivers" value={stats?.activeDrivers} />
      {/* More cards */}
    </div>
  );
};
```

### 2. Bus Management

**File:** `src/pages/BusManagement.tsx`

Features:
- List all buses with pagination
- Create new bus
- Edit bus details
- Delete bus
- Assign driver/minder
- View GPS location

```tsx
// Example: Create bus
const handleCreateBus = async (busData: BusFormData) => {
  try {
    await busService.createBus(busData);
    toast.success('Bus created successfully');
    refetchBuses();
  } catch (error) {
    toast.error('Failed to create bus');
  }
};
```

### 3. User Management

**File:** `src/pages/UserManagement.tsx`

Manage different user types:
- **Parents**: Create with phone number, add children
- **Drivers**: Create with license info
- **Bus Minders**: Create with ID number
- **Admins**: Create staff accounts

Auto-generates secure credentials for new users.

```tsx
// Example: Create parent
const handleCreateParent = async (parentData: ParentFormData) => {
  try {
    const result = await userService.createParent({
      firstName: parentData.firstName,
      lastName: parentData.lastName,
      phoneNumber: parentData.phoneNumber,
      children: parentData.children,
    });

    // Display generated credentials
    alert(`Username: ${result.username}\nPassword: ${result.password}`);
  } catch (error) {
    console.error('Error creating parent:', error);
  }
};
```

### 4. Assignments

**File:** `src/pages/AssignmentsPage.tsx`

Assign resources:
- Assign driver to bus
- Assign bus minder to bus
- Assign child to bus
- Bulk assignments
- View current assignments

```tsx
// Example: Assign driver to bus
const handleAssignDriver = async (driverId: number, busId: number) => {
  try {
    await assignmentService.assignDriver({ driverId, busId });
    toast.success('Driver assigned successfully');
  } catch (error) {
    toast.error('Failed to assign driver');
  }
};
```

### 5. Attendance Tracking

**File:** `src/pages/AttendancePage.tsx`

Features:
- View attendance by date
- Filter by bus or child
- Export reports
- Attendance analytics

### 6. Live Tracking

**File:** `src/pages/TrackingPage.tsx`

Real-time bus tracking:
- Google Maps integration
- Live bus markers
- Route visualization
- Bus status indicators

---

## API Integration

### Axios Configuration

**File:** `src/services/api.ts`

```typescript
import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add JWT token to all requests
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Handle 401 errors (token expired)
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Try to refresh token
      const refreshToken = localStorage.getItem('refresh_token');
      if (refreshToken) {
        try {
          const response = await axios.post(`${API_BASE_URL}/token/refresh/`, {
            refresh: refreshToken,
          });
          localStorage.setItem('access_token', response.data.access);
          // Retry original request
          error.config.headers.Authorization = `Bearer ${response.data.access}`;
          return apiClient.request(error.config);
        } catch (refreshError) {
          // Refresh failed, redirect to login
          localStorage.clear();
          window.location.href = '/login';
        }
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

### Service Example

**File:** `src/services/busService.ts`

```typescript
import apiClient from './api';
import { Bus, CreateBusRequest } from '../types';

export const busService = {
  // Get all buses
  async getAllBuses(): Promise<Bus[]> {
    const response = await apiClient.get('/buses/');
    return response.data.results;
  },

  // Get single bus
  async getBusById(id: number): Promise<Bus> {
    const response = await apiClient.get(`/buses/${id}/`);
    return response.data;
  },

  // Create bus
  async createBus(data: CreateBusRequest): Promise<Bus> {
    const response = await apiClient.post('/buses/', data);
    return response.data;
  },

  // Update bus
  async updateBus(id: number, data: Partial<Bus>): Promise<Bus> {
    const response = await apiClient.patch(`/buses/${id}/`, data);
    return response.data;
  },

  // Delete bus
  async deleteBus(id: number): Promise<void> {
    await apiClient.delete(`/buses/${id}/`);
  },
};
```

---

## Routing

**File:** `src/App.tsx`

```tsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import BusManagement from './pages/BusManagement';
import PrivateRoute from './components/PrivateRoute';
import Layout from './components/Layout';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Public routes */}
        <Route path="/login" element={<Login />} />

        {/* Protected routes */}
        <Route element={<PrivateRoute />}>
          <Route element={<Layout />}>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/buses" element={<BusManagement />} />
            <Route path="/users" element={<UserManagement />} />
            <Route path="/children" element={<ChildManagement />} />
            <Route path="/assignments" element={<AssignmentsPage />} />
            <Route path="/attendance" element={<AttendancePage />} />
            <Route path="/analytics" element={<AnalyticsPage />} />
            <Route path="/tracking" element={<TrackingPage />} />
          </Route>
        </Route>

        {/* 404 */}
        <Route path="*" element={<div>Page Not Found</div>} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
```

### Private Route Component

**File:** `src/components/PrivateRoute.tsx`

```tsx
import { Navigate, Outlet } from 'react-router-dom';

const PrivateRoute: React.FC = () => {
  const token = localStorage.getItem('access_token');

  if (!token) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
};

export default PrivateRoute;
```

---

## State Management

Currently using **React hooks** (`useState`, `useEffect`) for state management.

### Custom Hook Example

**File:** `src/hooks/useBuses.ts`

```typescript
import { useState, useEffect } from 'react';
import { busService } from '../services/busService';
import { Bus } from '../types';

export const useBuses = () => {
  const [buses, setBuses] = useState<Bus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBuses = async () => {
    try {
      setLoading(true);
      const data = await busService.getAllBuses();
      setBuses(data);
      setError(null);
    } catch (err) {
      setError('Failed to fetch buses');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBuses();
  }, []);

  return { buses, loading, error, refetch: fetchBuses };
};
```

---

## Styling

### Tailwind CSS

Utility-first CSS framework for rapid UI development.

**Configuration:** `tailwind.config.js`

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#3B82F6',
        secondary: '#10B981',
        danger: '#EF4444',
      },
    },
  },
  plugins: [],
}
```

### Example Component Styling

```tsx
const Button: React.FC<ButtonProps> = ({ children, onClick, variant = 'primary' }) => {
  const baseStyles = 'px-4 py-2 rounded-lg font-medium transition-colors';

  const variantStyles = {
    primary: 'bg-blue-500 hover:bg-blue-600 text-white',
    secondary: 'bg-gray-200 hover:bg-gray-300 text-gray-800',
    danger: 'bg-red-500 hover:bg-red-600 text-white',
  };

  return (
    <button
      className={`${baseStyles} ${variantStyles[variant]}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
```

---

## Building for Production

### Build Command

```bash
# Create optimized production build
npm run build

# Output will be in the dist/ directory
```

### Build Configuration

**File:** `vite.config.ts`

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    sourcemap: false,
    minify: 'esbuild',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
          axios: ['axios'],
        },
      },
    },
  },
});
```

---

## Deployment

### Deploy to Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel

# Production deployment
vercel --prod
```

### Deploy to Netlify

```bash
# Build the project
npm run build

# Deploy dist/ folder to Netlify
# Or connect GitHub repo for automatic deployments
```

### Deploy to AWS S3 + CloudFront

```bash
# Build
npm run build

# Sync to S3
aws s3 sync dist/ s3://your-bucket-name --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

### Environment Variables

Create `.env` files for different environments:

**.env.development:**
```env
VITE_API_BASE_URL=http://localhost:8000/api
```

**.env.production:**
```env
VITE_API_BASE_URL=https://api.apobasi.com/api
```

**Usage in code:**
```typescript
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;
```

---

## Troubleshooting

### Build Errors

```bash
# Clear cache and reinstall
rm -rf node_modules
rm package-lock.json
npm install

# Clear Vite cache
rm -rf node_modules/.vite
```

### CORS Errors

Ensure backend CORS settings allow your frontend origin:

```python
# Django settings.py
CORS_ALLOWED_ORIGINS = [
    "http://localhost:5173",
    "https://admin.apobasi.com",
]
```

### Hot Reload Not Working

```bash
# Restart dev server
npm run dev

# If still not working, clear cache
rm -rf node_modules/.vite
npm run dev
```

### TypeScript Errors

```bash
# Run type checking
npm run typecheck

# Fix common issues
npm install --save-dev @types/react @types/react-dom
```

---

## Development Best Practices

### Code Style

```bash
# Lint code
npm run lint

# Format code (if configured)
npm run format
```

### Type Safety

Always use TypeScript interfaces:

```typescript
// types/index.ts
export interface Bus {
  id: number;
  busNumber: string;
  numberPlate: string;
  capacity: number;
  model: string;
  year: number;
  isActive: boolean;
}

export interface CreateBusRequest {
  busNumber: string;
  numberPlate: string;
  capacity: number;
  model: string;
  year: number;
}
```

---

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Follow React and TypeScript best practices
4. Run linter before committing
5. Submit pull request

---

## License

MIT License - Part of the ApoBasi platform

---

## Support

- GitHub Issues
- Email: support@apobasi.com
- Docs: [docs.apobasi.com](https://docs.apobasi.com)

---

<div align="center">

**ApoBasi Admin Dashboard - School Management Made Easy**

Built with ❤️ using React + TypeScript + Vite

</div>
