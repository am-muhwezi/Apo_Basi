/**
 * API Type Definitions
 *
 * This file contains all API-related types for request/response handling.
 * Separating API types from domain types improves maintainability.
 */

/**
 * Standard paginated response from Django REST Framework
 */
export interface PaginatedResponse<T> {
  results: T[];
  count: number;
  next: string | null;
  previous: string | null;
}

/**
 * Standard error response structure
 */
export interface ApiError {
  message: string;
  errors?: Record<string, string[]>;
  statusCode?: number;
}

/**
 * Generic API response wrapper
 */
export interface ApiResponse<T = void> {
  success: boolean;
  data?: T;
  error?: ApiError;
}

/**
 * Pagination parameters for API requests
 */
export interface PaginationParams {
  limit?: number;
  offset?: number;
}

// ============================================
// Bus-specific API Types
// ============================================

/**
 * Data required to create a new bus
 */
export interface BusCreateData {
  busNumber: string;
  licensePlate: string;
  capacity: number;
  model?: string;
  year?: number;
  status?: 'active' | 'maintenance' | 'inactive';
  lastMaintenance?: string;
}

/**
 * Data for updating an existing bus (all fields optional)
 */
export interface BusUpdateData extends Partial<BusCreateData> {}

/**
 * Assignment data for drivers
 */
export interface DriverAssignmentData {
  driver_id: string;
}

/**
 * Assignment data for minders
 */
export interface MinderAssignmentData {
  minder_id: string;
}

/**
 * Assignment data for children
 */
export interface ChildrenAssignmentData {
  children_ids: string[];
}

/**
 * Combined assignment data for buses
 */
export interface BusAssignmentData {
  driverId?: string;
  minderId?: string;
  childrenIds?: string[];
}

// ============================================
// Driver-specific API Types
// ============================================

export interface DriverCreateData {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  licenseNumber: string;
  licenseExpiry: string;
  status?: 'active' | 'inactive';
}

export interface DriverUpdateData extends Partial<DriverCreateData> {}

// ============================================
// Minder-specific API Types
// ============================================

export interface MinderCreateData {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  certifications?: string[];
  status?: 'active' | 'inactive';
}

export interface MinderUpdateData extends Partial<MinderCreateData> {}

// ============================================
// Child-specific API Types
// ============================================

export interface ChildCreateData {
  firstName: string;
  lastName: string;
  grade: string;
  age: number;
  parentId: string;
  address: string;
  emergencyContact: string;
  medicalInfo?: string;
  status?: 'active' | 'inactive';
}

export interface ChildUpdateData extends Partial<ChildCreateData> {}

// ============================================
// Assignment-specific API Types
// ============================================

export interface AssignmentCreateData {
  assignmentType: string;
  assigneeId: number;
  assignedToId: number;
  effectiveDate: string;
  expiryDate?: string;
  status?: string;
  reason?: string;
  notes?: string;
}

export interface AssignmentUpdateData extends Partial<AssignmentCreateData> {}

export interface AssignmentFilterParams extends PaginationParams {
  assignmentType?: string;
  status?: string;
  assigneeId?: number;
  assignedToId?: number;
}
