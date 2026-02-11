/**
 * Checks if a phone or email exists as a driver, minder, or parent.
 * Returns { exists: boolean, role: 'driver'|'minder'|'parent'|null }
 */
export async function checkPhoneOrEmailExists(phone?: string, email?: string) {
  try {
    const params = new URLSearchParams();
    if (phone) params.append('phone', phone);
    if (email) params.append('email', email);
    const res = await fetch(`/api/check-user-unique?${params.toString()}`);
    if (!res.ok) return { exists: false, role: null };
    const data = await res.json();
    return { exists: data.exists, role: data.role };
  } catch {
    return { exists: false, role: null };
  }
}
// ...existing code...
/**
 * Driver Service Layer
 *
 * Business logic and error handling for driver operations.
 *
 * Architecture:
 * - Calls driverApi functions
 * - Handles errors and transforms them into user-friendly messages
 * - Returns consistent ApiResponse objects
 */

import * as driverApi from './driverApi';
import type { Driver } from '../types';
import type { ApiResponse, PaginationParams } from '../types/api';
import { AxiosError } from 'axios';

/**
 * Helper function to extract error message from axios error
 */
function getErrorMessage(error: unknown): string {
  if (error instanceof AxiosError) {
    if (error.response?.data) {
      const data = error.response.data;
      if (data.detail) return data.detail;
      if (typeof data === 'object') {
        for (const value of Object.values(data)) {
          if (Array.isArray(value) && value.length > 0) return String(value[0]);
          if (typeof value === 'string' && value) return value;
        }
      }
      if (data.error) return data.error;
      if (data.message) return data.message;
    }
    if (error.response?.status === 404) return 'Resource not found';
    if (error.response?.status === 403) return 'Permission denied';
    if (error.response?.status === 401) return 'Authentication required';
    if (error.response?.status >= 500) return 'Server error. Please try again later.';
    return error.message || 'Network error';
  }
  if (error instanceof Error) return error.message;
  return 'An unexpected error occurred';
}

class DriverService {
  /**
   * Load all drivers with pagination
   */
  async loadDrivers(params?: PaginationParams): Promise<
    ApiResponse<{
      drivers: Driver[];
      count: number;
      hasNext: boolean;
      hasPrevious: boolean;
    }>
  > {
    try {
      const response = await driverApi.getDrivers(params);
      const { results, count, next, previous } = response.data;

      return {
        success: true,
        data: {
          drivers: results || [],
          count: count || 0,
          hasNext: !!next,
          hasPrevious: !!previous,
        },
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: getErrorMessage(error),
        },
      };
    }
  }

  /**
   * Get a single driver by ID
   */
  async getDriver(id: string): Promise<ApiResponse<Driver>> {
    try {
      const response = await driverApi.getDriver(id);
      return {
        success: true,
        data: response.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: getErrorMessage(error),
        },
      };
    }
  }

  /**
   * Create new driver
   */
  async createDriver(formData: Partial<Driver>): Promise<ApiResponse<Driver>> {
    try {
      const response = await driverApi.createDriver({
        firstName: formData.firstName!,
        lastName: formData.lastName!,
        email: formData.email,
        phone: formData.phone!,
        licenseNumber: formData.licenseNumber!,
        licenseExpiry: formData.licenseExpiry,
        status: formData.status || 'active',
      });
      return {
        success: true,
        data: response.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: getErrorMessage(error),
        },
      };
    }
  }

  /**
   * Update existing driver
   */
  async updateDriver(id: string, formData: Partial<Driver>): Promise<ApiResponse<Driver>> {
    try {
      const response = await driverApi.updateDriver(id, formData);
      return {
        success: true,
        data: response.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: getErrorMessage(error),
        },
      };
    }
  }

  /**
   * Delete driver
   */
  async deleteDriver(id: string): Promise<ApiResponse<void>> {
    try {
      await driverApi.deleteDriver(id);
      return {
        success: true,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: getErrorMessage(error),
        },
      };
    }
  }
}

export const driverService = new DriverService();
