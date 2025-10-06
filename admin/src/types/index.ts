export interface Child {
  id: string;
  firstName: string;
  lastName: string;
  grade: string;
  age: number;
  parentId: string;
  busId?: string;
  photoUrl?: string;
  address: string;
  emergencyContact: string;
  medicalInfo?: string;
  status: 'active' | 'inactive';
  createdAt: string;
}

export interface Parent {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: string;
  childrenIds: string[];
  status: 'active' | 'inactive';
  createdAt: string;
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
  photoUrl?: string;
  certifications?: string[];
  status: 'active' | 'inactive';
  createdAt: string;
}

export interface Trip {
  id: string;
  busId: string;
  driverId: string;
  minderId?: string;
  route: string;
  type: 'pickup' | 'dropoff';
  status: 'scheduled' | 'in-progress' | 'completed' | 'cancelled';
  scheduledTime: string;
  startTime?: string;
  endTime?: string;
  currentLocation?: Location;
  stops: Stop[];
  childrenIds: string[];
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
