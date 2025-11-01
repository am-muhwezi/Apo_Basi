# Admin Dashboard Development Guide (React + Vite)
## For School Bus Tracking Admin Portal

**Target Audience:** Junior developers with NO web development background
**Goal:** Take you from zero to developing features and teaching others
**Stack:** React, Vite, TypeScript, REST API integration

---

## Table of Contents
1. [Understanding Web Development Basics](#1-understanding-web-development-basics)
2. [React & Vite Fundamentals](#2-react--vite-fundamentals)
3. [Project Structure & Architecture](#3-project-structure--architecture)
4. [Working with REST APIs](#4-working-with-rest-apis)
5. [Building UI Components](#5-building-ui-components)
6. [State Management & React Hooks](#6-state-management--react-hooks)
7. [Routing & Navigation](#7-routing--navigation)
8. [Forms & Data Validation](#8-forms--data-validation)
9. [Tables & Data Display](#9-tables--data-display)
10. [Real-time Updates](#10-real-time-updates)
11. [Authentication & Authorization](#11-authentication--authorization)
12. [Common Development Tasks](#12-common-development-tasks)
13. [Best Practices](#13-best-practices)

---

## 1. Understanding Web Development Basics

### What is a Web Application?
A web application runs in a browser (Chrome, Firefox, etc.) and consists of:
- **HTML:** Structure (headings, buttons, forms)
- **CSS:** Styling (colors, layouts, animations)
- **JavaScript:** Interactivity (clicking, form submission, API calls)

### Frontend vs Backend
- **Frontend (What we're building):** What users see and interact with
- **Backend:** Server that stores data and handles business logic

### Why React?
- **Component-Based:** Build reusable UI pieces
- **Fast:** Virtual DOM for efficient updates
- **Popular:** Large community, many jobs
- **Ecosystem:** Rich libraries (routing, forms, charts, etc.)

### Why Vite?
- **Fast:** Hot Module Replacement (HMR) - instant updates
- **Modern:** Uses latest JavaScript features
- **Simple:** Less configuration than webpack

---

## 2. React & Vite Fundamentals

### 2.1 Installation & Setup

**Prerequisites:**
```bash
# Install Node.js (v18+)
# https://nodejs.org/

# Verify installation
node --version
npm --version
```

**Create New Project:**
```bash
# Create Vite + React project
npm create vite@latest my-admin-dashboard -- --template react-ts

# Navigate to project
cd my-admin-dashboard

# Install dependencies
npm install

# Run development server
npm run dev

# Open http://localhost:5173
```

### 2.2 JavaScript/TypeScript Basics

**Variables:**
```typescript
// TypeScript adds types to JavaScript
let name: string = "John";
let age: number = 25;
let isActive: boolean = true;

// Arrays
let numbers: number[] = [1, 2, 3, 4, 5];
let names: string[] = ["Alice", "Bob", "Charlie"];

// Objects
interface User {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'driver' | 'parent';
}

const user: User = {
  id: 1,
  name: "John Doe",
  email: "john@example.com",
  role: "admin",
};

// Functions
function greet(name: string): string {
  return `Hello, ${name}!`;
}

// Arrow functions (modern syntax)
const greet2 = (name: string): string => {
  return `Hello, ${name}!`;
};

// Short arrow function
const greet3 = (name: string): string => `Hello, ${name}!`;

// Async/Await (for API calls)
async function fetchData(): Promise<User[]> {
  const response = await fetch('/api/users');
  const data = await response.json();
  return data;
}
```

**Array Methods (Very Important!):**
```typescript
const users = [
  { id: 1, name: "Alice", age: 25 },
  { id: 2, name: "Bob", age: 30 },
  { id: 3, name: "Charlie", age: 35 },
];

// map - Transform each item
const names = users.map(user => user.name);
// Result: ["Alice", "Bob", "Charlie"]

// filter - Keep items that match condition
const youngUsers = users.filter(user => user.age < 30);
// Result: [{ id: 1, name: "Alice", age: 25 }]

// find - Get first item that matches
const alice = users.find(user => user.name === "Alice");
// Result: { id: 1, name: "Alice", age: 25 }

// forEach - Do something for each item
users.forEach(user => {
  console.log(user.name);
});
```

### 2.3 React Components

**Functional Component:**
```tsx
// src/components/Button.tsx
interface ButtonProps {
  text: string;
  onClick: () => void;
  variant?: 'primary' | 'secondary';
}

const Button = ({ text, onClick, variant = 'primary' }: ButtonProps) => {
  return (
    <button
      onClick={onClick}
      className={`btn btn-${variant}`}
    >
      {text}
    </button>
  );
};

export default Button;
```

**Using Components:**
```tsx
// src/App.tsx
import Button from './components/Button';

function App() {
  const handleClick = () => {
    alert('Button clicked!');
  };

  return (
    <div>
      <h1>My Dashboard</h1>
      <Button text="Click Me" onClick={handleClick} />
      <Button text="Secondary" onClick={handleClick} variant="secondary" />
    </div>
  );
}

export default App;
```

---

## 3. Project Structure & Architecture

### 3.1 Folder Structure

```
admin-dashboard/
├── public/                # Static assets
├── src/
│   ├── assets/           # Images, icons
│   ├── components/       # Reusable UI components
│   │   ├── common/      # Buttons, Inputs, Cards
│   │   ├── layout/      # Navbar, Sidebar, Footer
│   │   └── features/    # Feature-specific components
│   ├── pages/            # Page components
│   │   ├── Dashboard.tsx
│   │   ├── Drivers.tsx
│   │   ├── BusMinders.tsx
│   │   └── Trips.tsx
│   ├── services/         # API calls
│   │   ├── api.ts
│   │   ├── authService.ts
│   │   └── driverService.ts
│   ├── hooks/            # Custom React hooks
│   ├── types/            # TypeScript types
│   ├── utils/            # Helper functions
│   ├── App.tsx           # Main app component
│   ├── main.tsx          # Entry point
│   └── index.css         # Global styles
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript config
└── vite.config.ts        # Vite config
```

### 3.2 Key Files Explained

**main.tsx** - Entry point:
```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.tsx';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
```

**App.tsx** - Main component:
```tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import Drivers from './pages/Drivers';
import Login from './pages/Login';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<Dashboard />} />
        <Route path="/drivers" element={<Drivers />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
```

**package.json** - Dependencies:
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "axios": "^1.6.0",
    "lucide-react": "^0.300.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "vite": "^5.0.0",
    "typescript": "^5.0.0"
  }
}
```

---

## 4. Working with REST APIs

### 4.1 API Service Setup

**src/services/api.ts:**
```typescript
import axios, { AxiosInstance } from 'axios';

// Base API configuration
const API_BASE_URL = 'http://192.168.100.43:8000';

// Create axios instance
const api: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth token to requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Handle errors globally
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Unauthorized - redirect to login
      localStorage.removeItem('access_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
```

### 4.2 Service Functions

**src/services/driverService.ts:**
```typescript
import api from './api';

export interface Driver {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  licenseNumber: string;
  status: 'active' | 'inactive';
  assignedBus?: {
    id: number;
    numberPlate: string;
  };
}

export const driverService = {
  // Get all drivers
  async getAll(): Promise<Driver[]> {
    const response = await api.get('/api/drivers/');
    return response.data;
  },

  // Get single driver
  async getById(id: number): Promise<Driver> {
    const response = await api.get(`/api/drivers/${id}/`);
    return response.data;
  },

  // Create driver
  async create(data: Partial<Driver>): Promise<Driver> {
    const response = await api.post('/api/drivers/', data);
    return response.data;
  },

  // Update driver
  async update(id: number, data: Partial<Driver>): Promise<Driver> {
    const response = await api.patch(`/api/drivers/${id}/`, data);
    return response.data;
  },

  // Delete driver
  async delete(id: number): Promise<void> {
    await api.delete(`/api/drivers/${id}/`);
  },

  // Assign bus to driver
  async assignBus(driverId: number, busId: number): Promise<void> {
    await api.post('/api/admins/assign-driver/', {
      driver_id: driverId,
      bus_id: busId,
    });
  },
};
```

### 4.3 Using Services in Components

```tsx
import { useState, useEffect } from 'react';
import { driverService, Driver } from '../services/driverService';

const DriversPage = () => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDrivers();
  }, []);

  const loadDrivers = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await driverService.getAll();
      setDrivers(data);
    } catch (err) {
      setError('Failed to load drivers');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      <h1>Drivers</h1>
      <ul>
        {drivers.map(driver => (
          <li key={driver.id}>
            {driver.firstName} {driver.lastName}
          </li>
        ))}
      </ul>
    </div>
  );
};

export default DriversPage;
```

---

## 5. Building UI Components

### 5.1 Common Components

**Button Component:**
```tsx
// src/components/common/Button.tsx
interface ButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
  variant?: 'primary' | 'secondary' | 'danger';
  disabled?: boolean;
  type?: 'button' | 'submit';
}

const Button = ({
  children,
  onClick,
  variant = 'primary',
  disabled = false,
  type = 'button',
}: ButtonProps) => {
  const baseClasses = 'px-4 py-2 rounded font-medium transition';
  const variantClasses = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700',
    secondary: 'bg-gray-200 text-gray-800 hover:bg-gray-300',
    danger: 'bg-red-600 text-white hover:bg-red-700',
  };

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`${baseClasses} ${variantClasses[variant]} ${
        disabled ? 'opacity-50 cursor-not-allowed' : ''
      }`}
    >
      {children}
    </button>
  );
};

export default Button;
```

**Card Component:**
```tsx
// src/components/common/Card.tsx
interface CardProps {
  title?: string;
  children: React.ReactNode;
  className?: string;
}

const Card = ({ title, children, className = '' }: CardProps) => {
  return (
    <div className={`bg-white rounded-lg shadow p-6 ${className}`}>
      {title && <h3 className="text-lg font-semibold mb-4">{title}</h3>}
      {children}
    </div>
  );
};

export default Card;
```

**Modal Component:**
```tsx
// src/components/common/Modal.tsx
import { X } from 'lucide-react';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}

const Modal = ({ isOpen, onClose, title, children }: ModalProps) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black bg-opacity-50"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b">
          <h2 className="text-xl font-semibold">{title}</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
          >
            <X size={24} />
          </button>
        </div>

        {/* Content */}
        <div className="p-4">{children}</div>
      </div>
    </div>
  );
};

export default Modal;
```

### 5.2 Layout Components

**Sidebar:**
```tsx
// src/components/layout/Sidebar.tsx
import { Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, Users, Bus, MapPin } from 'lucide-react';

const Sidebar = () => {
  const location = useLocation();

  const menuItems = [
    { path: '/', label: 'Dashboard', icon: LayoutDashboard },
    { path: '/drivers', label: 'Drivers', icon: Users },
    { path: '/buses', label: 'Buses', icon: Bus },
    { path: '/trips', label: 'Trips', icon: MapPin },
  ];

  return (
    <aside className="w-64 bg-gray-900 text-white h-screen">
      <div className="p-4">
        <h1 className="text-2xl font-bold">AppBasi Admin</h1>
      </div>

      <nav className="mt-8">
        {menuItems.map(item => {
          const Icon = item.icon;
          const isActive = location.pathname === item.path;

          return (
            <Link
              key={item.path}
              to={item.path}
              className={`flex items-center px-4 py-3 hover:bg-gray-800 ${
                isActive ? 'bg-gray-800 border-l-4 border-blue-500' : ''
              }`}
            >
              <Icon size={20} className="mr-3" />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>
    </aside>
  );
};

export default Sidebar;
```

**Main Layout:**
```tsx
// src/components/layout/MainLayout.tsx
import Sidebar from './Sidebar';
import Navbar from './Navbar';

interface MainLayoutProps {
  children: React.ReactNode;
}

const MainLayout = ({ children }: MainLayoutProps) => {
  return (
    <div className="flex h-screen">
      <Sidebar />

      <div className="flex-1 flex flex-col overflow-hidden">
        <Navbar />

        <main className="flex-1 overflow-y-auto bg-gray-100 p-6">
          {children}
        </main>
      </div>
    </div>
  );
};

export default MainLayout;
```

---

## 6. State Management & React Hooks

### 6.1 useState - Managing Component State

```tsx
import { useState } from 'react';

const Counter = () => {
  // Declare state variable
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
      <button onClick={() => setCount(count - 1)}>Decrement</button>
      <button onClick={() => setCount(0)}>Reset</button>
    </div>
  );
};
```

**Multiple State Variables:**
```tsx
const LoginForm = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    try {
      await authService.login(email, password);
      // Success - redirect
    } catch (err) {
      setError('Login failed');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email"
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
      />
      {error && <p className="text-red-600">{error}</p>}
      <button type="submit" disabled={isLoading}>
        {isLoading ? 'Loading...' : 'Login'}
      </button>
    </form>
  );
};
```

### 6.2 useEffect - Side Effects

```tsx
import { useState, useEffect } from 'react';

const DriversList = () => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);

  // Runs once when component mounts
  useEffect(() => {
    loadDrivers();
  }, []);  // Empty dependency array = run once

  const loadDrivers = async () => {
    setLoading(true);
    const data = await driverService.getAll();
    setDrivers(data);
    setLoading(false);
  };

  return <div>...</div>;
};
```

**With Dependencies:**
```tsx
const DriverDetail = ({ driverId }: { driverId: number }) => {
  const [driver, setDriver] = useState<Driver | null>(null);

  // Runs when driverId changes
  useEffect(() => {
    loadDriver();
  }, [driverId]);  // Re-run when driverId changes

  const loadDriver = async () => {
    const data = await driverService.getById(driverId);
    setDriver(data);
  };

  return <div>...</div>;
};
```

**Cleanup:**
```tsx
useEffect(() => {
  // Setup WebSocket connection
  const ws = new WebSocket('ws://localhost:8000/ws');

  ws.onmessage = (event) => {
    console.log(event.data);
  };

  // Cleanup function (runs when component unmounts)
  return () => {
    ws.close();
  };
}, []);
```

### 6.3 Custom Hooks

```tsx
// src/hooks/useDrivers.ts
import { useState, useEffect } from 'react';
import { driverService, Driver } from '../services/driverService';

export const useDrivers = () => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDrivers();
  }, []);

  const loadDrivers = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await driverService.getAll();
      setDrivers(data);
    } catch (err) {
      setError('Failed to load drivers');
    } finally {
      setLoading(false);
    }
  };

  const deleteDriver = async (id: number) => {
    await driverService.delete(id);
    await loadDrivers();  // Reload list
  };

  return { drivers, loading, error, loadDrivers, deleteDriver };
};

// Usage
const DriversPage = () => {
  const { drivers, loading, error, deleteDriver } = useDrivers();

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      {drivers.map(driver => (
        <div key={driver.id}>
          {driver.firstName}
          <button onClick={() => deleteDriver(driver.id)}>Delete</button>
        </div>
      ))}
    </div>
  );
};
```

---

## 7. Routing & Navigation

### 7.1 React Router Setup

**Install:**
```bash
npm install react-router-dom
```

**Basic Setup:**
```tsx
// src/App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import Drivers from './pages/Drivers';
import DriverDetail from './pages/DriverDetail';
import Login from './pages/Login';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<Dashboard />} />
        <Route path="/drivers" element={<Drivers />} />
        <Route path="/drivers/:id" element={<DriverDetail />} />
      </Routes>
    </BrowserRouter>
  );
}
```

### 7.2 Navigation

```tsx
import { Link, useNavigate } from 'react-router-dom';

const Navigation = () => {
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('access_token');
    navigate('/login');
  };

  return (
    <nav>
      {/* Using Link */}
      <Link to="/">Dashboard</Link>
      <Link to="/drivers">Drivers</Link>

      {/* Using navigate function */}
      <button onClick={handleLogout}>Logout</button>
      <button onClick={() => navigate('/profile')}>Profile</button>
    </nav>
  );
};
```

### 7.3 Route Parameters

```tsx
import { useParams } from 'react-router-dom';

const DriverDetail = () => {
  const { id } = useParams<{ id: string }>();
  const [driver, setDriver] = useState<Driver | null>(null);

  useEffect(() => {
    if (id) {
      loadDriver(parseInt(id));
    }
  }, [id]);

  const loadDriver = async (driverId: number) => {
    const data = await driverService.getById(driverId);
    setDriver(data);
  };

  return (
    <div>
      <h1>{driver?.firstName} {driver?.lastName}</h1>
      <p>Email: {driver?.email}</p>
    </div>
  );
};
```

### 7.4 Protected Routes

```tsx
// src/components/ProtectedRoute.tsx
import { Navigate } from 'react-router-dom';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

const ProtectedRoute = ({ children }: ProtectedRouteProps) => {
  const isAuthenticated = !!localStorage.getItem('access_token');

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
};

// Usage in App.tsx
<Route
  path="/"
  element={
    <ProtectedRoute>
      <Dashboard />
    </ProtectedRoute>
  }
/>
```

---

## 8. Forms & Data Validation

### 8.1 Controlled Forms

```tsx
const AddDriverForm = () => {
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    licenseNumber: '',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.firstName) newErrors.firstName = 'First name is required';
    if (!formData.email) newErrors.email = 'Email is required';
    if (formData.email && !/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Invalid email format';
    }
    if (!formData.phone) newErrors.phone = 'Phone is required';

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validate()) return;

    try {
      await driverService.create(formData);
      alert('Driver added successfully!');
      // Reset form
      setFormData({
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        licenseNumber: '',
      });
    } catch (err) {
      alert('Failed to add driver');
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label>First Name</label>
        <input
          type="text"
          name="firstName"
          value={formData.firstName}
          onChange={handleChange}
          className="w-full border rounded px-3 py-2"
        />
        {errors.firstName && (
          <p className="text-red-600 text-sm">{errors.firstName}</p>
        )}
      </div>

      <div>
        <label>Email</label>
        <input
          type="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          className="w-full border rounded px-3 py-2"
        />
        {errors.email && (
          <p className="text-red-600 text-sm">{errors.email}</p>
        )}
      </div>

      <button
        type="submit"
        className="bg-blue-600 text-white px-4 py-2 rounded"
      >
        Add Driver
      </button>
    </form>
  );
};
```

---

## 9. Tables & Data Display

### 9.1 Simple Table

```tsx
interface Driver {
  id: number;
  name: string;
  email: string;
  phone: string;
  status: 'active' | 'inactive';
}

const DriversTable = ({ drivers }: { drivers: Driver[] }) => {
  return (
    <div className="overflow-x-auto">
      <table className="min-w-full bg-white">
        <thead className="bg-gray-100">
          <tr>
            <th className="px-6 py-3 text-left">Name</th>
            <th className="px-6 py-3 text-left">Email</th>
            <th className="px-6 py-3 text-left">Phone</th>
            <th className="px-6 py-3 text-left">Status</th>
            <th className="px-6 py-3 text-left">Actions</th>
          </tr>
        </thead>
        <tbody>
          {drivers.map(driver => (
            <tr key={driver.id} className="border-b hover:bg-gray-50">
              <td className="px-6 py-4">{driver.name}</td>
              <td className="px-6 py-4">{driver.email}</td>
              <td className="px-6 py-4">{driver.phone}</td>
              <td className="px-6 py-4">
                <span
                  className={`px-2 py-1 rounded text-sm ${
                    driver.status === 'active'
                      ? 'bg-green-100 text-green-800'
                      : 'bg-red-100 text-red-800'
                  }`}
                >
                  {driver.status}
                </span>
              </td>
              <td className="px-6 py-4">
                <button className="text-blue-600 mr-2">View</button>
                <button className="text-red-600">Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
```

### 9.2 Search & Filter

```tsx
const DriversPage = () => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');

  const filteredDrivers = drivers.filter(driver => {
    const matchesSearch = driver.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          driver.email.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || driver.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  return (
    <div>
      <div className="mb-4 flex gap-4">
        <input
          type="text"
          placeholder="Search drivers..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="border rounded px-3 py-2"
        />

        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as any)}
          className="border rounded px-3 py-2"
        >
          <option value="all">All Status</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      <DriversTable drivers={filteredDrivers} />
    </div>
  );
};
```

---

## 10. Real-time Updates

### 10.1 Polling (Simple Approach)

```tsx
const LiveTrackingMap = () => {
  const [buses, setBuses] = useState<Bus[]>([]);

  useEffect(() => {
    // Load immediately
    loadBuses();

    // Then refresh every 5 seconds
    const interval = setInterval(loadBuses, 5000);

    // Cleanup
    return () => clearInterval(interval);
  }, []);

  const loadBuses = async () => {
    const data = await busService.getAll();
    setBuses(data);
  };

  return <div>...</div>;
};
```

### 10.2 WebSocket (Advanced)

```tsx
const LiveTracking = () => {
  const [buses, setBuses] = useState<Bus[]>([]);

  useEffect(() => {
    const ws = new WebSocket('ws://localhost:8000/ws/tracking/');

    ws.onopen = () => {
      console.log('WebSocket connected');
    };

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setBuses(data.buses);
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    ws.onclose = () => {
      console.log('WebSocket disconnected');
    };

    // Cleanup
    return () => {
      ws.close();
    };
  }, []);

  return <div>...</div>;
};
```

---

## 11. Authentication & Authorization

### 11.1 Login Flow

```tsx
// src/services/authService.ts
export const authService = {
  async login(username: string, password: string) {
    const response = await api.post('/api/users/login/', {
      username,
      password,
    });

    const { access, refresh } = response.data.tokens;
    localStorage.setItem('access_token', access);
    localStorage.setItem('refresh_token', refresh);

    return response.data;
  },

  logout() {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
  },

  isAuthenticated() {
    return !!localStorage.getItem('access_token');
  },
};

// src/pages/Login.tsx
const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      await authService.login(username, password);
      navigate('/');
    } catch (err) {
      alert('Login failed');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={username}
        onChange={(e) => setUsername(e.target.value)}
        placeholder="Username"
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
      />
      <button type="submit">Login</button>
    </form>
  );
};
```

---

## 12. Common Development Tasks

### 12.1 Adding a New Page

1. Create page component:
```tsx
// src/pages/BusMinders.tsx
const BusMinders = () => {
  return (
    <div>
      <h1>Bus Minders</h1>
    </div>
  );
};

export default BusMinders;
```

2. Add route:
```tsx
// src/App.tsx
<Route path="/bus-minders" element={<BusMinders />} />
```

3. Add to sidebar:
```tsx
// src/components/layout/Sidebar.tsx
const menuItems = [
  // ...
  { path: '/bus-minders', label: 'Bus Minders', icon: Users },
];
```

### 12.2 Adding CRUD Operations

See the comprehensive examples in sections 4.2, 4.3, and 8.1 above.

---

## 13. Best Practices

### 13.1 Code Style

```typescript
// ✅ Good: Descriptive names
const fetchDriverData = async (driverId: number) => { };

// ❌ Bad: Unclear names
const fdd = async (id: number) => { };

// ✅ Good: Extract reusable logic
const useDrivers = () => { };

// ❌ Bad: Duplicate code everywhere
```

### 13.2 Performance

```tsx
// ✅ Good: Memoize expensive calculations
import { useMemo } from 'react';

const filteredData = useMemo(() => {
  return data.filter(item => item.active);
}, [data]);

// ✅ Good: Debounce search
import { useState, useEffect } from 'react';

const [searchTerm, setSearchTerm] = useState('');
const [debouncedTerm, setDebouncedTerm] = useState('');

useEffect(() => {
  const timer = setTimeout(() => {
    setDebouncedTerm(searchTerm);
  }, 300);

  return () => clearTimeout(timer);
}, [searchTerm]);
```

### 13.3 Error Handling

```tsx
// ✅ Always handle errors
try {
  await api.call();
} catch (err) {
  console.error(err);
  showErrorMessage();
}
```

---

## Quick Commands Reference

```bash
npm create vite@latest         # Create project
npm install                     # Install dependencies
npm run dev                     # Start dev server
npm run build                   # Build for production
npm run preview                 # Preview production build
```

---

## Useful Resources

- **React Docs:** https://react.dev/
- **Vite Docs:** https://vitejs.dev/
- **TypeScript:** https://www.typescriptlang.org/docs/
- **Tailwind CSS:** https://tailwindcss.com/docs
- **React Router:** https://reactrouter.com/

---

**Document Version:** 1.0
**Last Updated:** October 2024
**Maintainer:** Development Team
