export interface Child {
  id: string;
  firstName: string;
  lastName: string;
  grade: string;
  age: number;
  parentId: string;
  parentName?: string;
  busId?: string;
  assignedBusId?: string;
  assignedBusNumber?: string;
  photoUrl?: string;
  address?: string;  // Optional - inherits from parent if not provided
  emergencyContact?: string;  // Optional - inherits from parent if not provided
  medicalInfo?: string;
  status: 'active' | 'inactive';  // Enrollment status
  locationStatus?: 'home' | 'at-school' | 'on-bus' | 'picked-up' | 'dropped-off';  // Real-time tracking status
  createdAt?: string;
}

export interface Parent {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: string;
  emergencyContact?: string;
  childrenIds: string[];
  childrenCount?: number;
  status: 'active' | 'inactive';
  createdAt?: string;
}

export interface Bus {
  id: string;
  busNumber: string;
  licensePlate: string;
  capacity: number;
  model?: string;
  year?: number;
  driverId?: number;
  driverName?: string;
  minderId?: number;
  minderName?: string;
  assignedChildrenCount?: number;
  assignedChildrenIds?: string[];
  status?: 'active' | 'maintenance' | 'inactive';
  isActive?: boolean;
  lastMaintenance?: string;
  currentLocation?: string;
  latitude?: string;
  longitude?: string;
  lastUpdated?: string;
  createdAt?: string;
}

export interface Driver {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  licenseNumber: string;
  licenseExpiry: string;
  assignedBusId?: string;
  assignedBusNumber?: string;
  photoUrl?: string;
  status: 'active' | 'inactive';
  createdAt: string;
}

export interface Minder {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  assignedBusId?: string;
  assignedBusNumber?: string;
  photoUrl?: string;
  status: 'active' | 'inactive';
  createdAt: string;
}

export interface Trip {
  id: string;
  busId: string;
  busNumber: string;
  driverId: string;
  driverName: string;
  minderId?: string;
  minderName?: string;
  route: string;
  type: 'pickup' | 'dropoff';
  status: 'scheduled' | 'in-progress' | 'completed' | 'cancelled';
  scheduledTime: string;
  startTime?: string;
  endTime?: string;
  currentLocation?: Location;
  stops: Stop[];
  childrenIds: string[];
  children?: Array<{
    id: string;
    name: string;
    address: string;
    latitude: number | null;
    longitude: number | null;
  }>;
  totalStudents?: number;
  studentsCompleted?: number;
  studentsAbsent?: number;
  studentsPending?: number;
  createdAt: string;
}

export interface Location {
  latitude: number;
  longitude: number;
  timestamp: string;
}

export interface Stop {
  id: string;
  address: string;
  location: Location;
  childrenIds: string[];
  scheduledTime: string;
  actualTime?: string;
  status: 'pending' | 'completed' | 'skipped';
}

export interface Admin {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  role: 'super-admin' | 'admin' | 'viewer';
  permissions: Permission[];
  status: 'active' | 'inactive';
  lastLogin?: string;
  createdAt: string;
}

export type Permission =
  | 'manage-children'
  | 'manage-parents'
  | 'manage-buses'
  | 'manage-drivers'
  | 'manage-minders'
  | 'manage-trips'
  | 'manage-admins'
  | 'view-reports';

export interface BusRoute {
  id: string;
  name: string;
  routeCode: string;
  description?: string;
  defaultBusId?: string;
  defaultBusNumber?: string;
  defaultDriverId?: string;
  defaultDriverName?: string;
  defaultMinderId?: string;
  defaultMinderName?: string;
  schedule?: Record<string, any>;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  activeAssignmentsCount?: number;
  assignedChildrenCount?: number;
}

export type AssignmentType =
  | 'driver_to_bus'
  | 'minder_to_bus'
  | 'child_to_bus'
  | 'bus_to_route'
  | 'driver_to_route'
  | 'minder_to_route'
  | 'child_to_route';

export type AssignmentStatus = 'active' | 'expired' | 'cancelled' | 'pending';

export interface Assignment {
  id: string;
  assignmentType: AssignmentType;
  status: AssignmentStatus;
  assigneeType: string;
  assigneeId: number;
  assigneeName?: string;
  assigneeDetails?: Record<string, any>;
  assignedToType: string;
  assignedToId: number;
  assignedToName?: string;
  assignedToDetails?: Record<string, any>;
  effectiveDate: string;
  expiryDate?: string;
  assignedById?: number;
  assignedByName?: string;
  assignedAt: string;
  reason?: string;
  notes?: string;
  metadata?: Record<string, any>;
  isCurrentlyActive: boolean;
  updatedAt: string;
}

export interface AssignmentHistory {
  id: string;
  assignmentId: string;
  action: 'created' | 'updated' | 'cancelled' | 'expired';
  performedById?: number;
  performedByName?: string;
  performedAt: string;
  changes: Record<string, any>;
  notes?: string;
}

export interface AssignmentFormData {
  assignmentType: AssignmentType;
  assigneeId: number;
  assignedToId: number;
  effectiveDate: string;
  expiryDate?: string;
  status?: AssignmentStatus;
  reason?: string;
  notes?: string;
}

export interface RouteFormData {
  name: string;
  routeCode: string;
  description?: string;
  defaultBusId?: string;
  defaultDriverId?: string;
  defaultMinderId?: string;
  schedule?: Record<string, any>;
  isActive: boolean;
}
