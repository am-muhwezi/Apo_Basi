/**
 * Bus Service Layer
 *
 * This layer contains business logic and error handling for bus operations.
 * It sits between the API layer and the hooks/UI layer.
 *
 * Architecture:
 * - Calls busApi functions
 * - Handles errors and transforms them into user-friendly messages
 * - Performs business logic (data transformation, validation)
 * - Returns consistent ApiResponse objects
 *
 * Junior Dev Guide:
 * - Always wrap API calls in try/catch
 * - Return ApiResponse<T> for consistent error handling
 * - Transform backend data if needed (e.g., snake_case to camelCase)
 * - Add business validation here (e.g., capacity checks)
 */

import * as busApi from './busApi';
import type { Bus } from '../types';
import type {
  ApiResponse,
  PaginationParams,
  BusCreateData,
  BusUpdateData,
} from '../types/api';
import { AxiosError } from 'axios';

/**
 * Helper function to extract error message from axios error
 */
function getErrorMessage(error: unknown): string {
  if (error instanceof AxiosError) {
    // Handle DRF error responses
    if (error.response?.data) {
      const data = error.response.data;

      // Check for detail field (common in DRF)
      if (data.detail) {
        return data.detail;
      }

      // Check for field-specific errors
      if (typeof data === 'object') {
        const firstError = Object.values(data)[0];
        if (Array.isArray(firstError) && firstError.length > 0) {
          return firstError[0];
        }
      }

      // Check for error or message field
      if (data.error) {
        return data.error;
      }
      if (data.message) {
        return data.message;
      }
    }

    // Return status-based message
    if (error.response?.status === 404) {
      return 'Resource not found';
    }
    if (error.response?.status === 403) {
      return 'Permission denied';
    }
    if (error.response?.status === 401) {
      return 'Authentication required';
    }
    if (error.response?.status >= 500) {
      return 'Server error. Please try again later.';
    }

    return error.message || 'Network error';
  }

  if (error instanceof Error) {
    return error.message;
  }

  return 'An unexpected error occurred';
}

class BusService {
  /**
   * Load all buses with pagination
   *
   * Example usage:
   * const result = await busService.loadBuses({ limit: 20, offset: 0 });
   * if (result.success) {
   * } else {
   * }
   */
  async loadBuses(params?: PaginationParams): Promise<
    ApiResponse<{
      buses: Bus[];
      count: number;
      hasNext: boolean;
      hasPrevious: boolean;
    }>
  > {
    try {
      const response = await busApi.getBuses(params);
      const { results, count, next, previous } = response.data;

      return {
        success: true,
        data: {
          buses: results || [],
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
   * Get a single bus by ID
   */
  async getBus(id: string): Promise<ApiResponse<Bus>> {
    try {
      const response = await busApi.getBus(id);
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
   * Create a new bus
   *
   * Includes business validation:
   * - Capacity must be positive
   * - Year must be valid
   */
  async createBus(formData: Partial<Bus>): Promise<ApiResponse<Bus>> {
    try {
      // Business validation
      if (formData.capacity && formData.capacity <= 0) {
        return {
          success: false,
          error: {
            message: 'Capacity must be greater than 0',
          },
        };
      }

      if (formData.year) {
        const currentYear = new Date().getFullYear();
        if (formData.year < 1990 || formData.year > currentYear + 2) {
          return {
            success: false,
            error: {
              message: `Year must be between 1990 and ${currentYear + 2}`,
            },
          };
        }
      }

      // Transform to API format
      const busData: BusCreateData = {
        busNumber: formData.busNumber!,
        licensePlate: formData.licensePlate!,
        capacity: formData.capacity!,
        model: formData.model,
        year: formData.year,
        status: formData.status || 'active',
        lastMaintenance: formData.lastMaintenance,
      };

      const response = await busApi.createBus(busData);
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
   * Update an existing bus
   */
  async updateBus(id: string, formData: Partial<Bus>): Promise<ApiResponse<Bus>> {
    try {
      // Business validation (same as create)
      if (formData.capacity !== undefined && formData.capacity <= 0) {
        return {
          success: false,
          error: {
            message: 'Capacity must be greater than 0',
          },
        };
      }

      if (formData.year) {
        const currentYear = new Date().getFullYear();
        if (formData.year < 1990 || formData.year > currentYear + 2) {
          return {
            success: false,
            error: {
              message: `Year must be between 1990 and ${currentYear + 2}`,
            },
          };
        }
      }

      const response = await busApi.updateBus(id, formData);
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
   * Delete a bus
   */
  async deleteBus(id: string): Promise<ApiResponse<void>> {
    try {
      await busApi.deleteBus(id);
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

  /**
   * Assign a driver to a bus
   */
  async assignDriver(busId: string, driverId: string): Promise<ApiResponse<any>> {
    try {
      const response = await busApi.assignDriver(busId, driverId);
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
   * Assign a minder to a bus
   */
  async assignMinder(busId: string, minderId: string): Promise<ApiResponse<any>> {
    try {
      const response = await busApi.assignMinder(busId, minderId);
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
   * Assign children to a bus
   *
   * Includes business validation:
   * - Check if number of children exceeds bus capacity
   */
  async assignChildren(
    busId: string,
    childrenIds: string[],
    busCapacity?: number
  ): Promise<ApiResponse<any>> {
    try {
      // Business validation
      if (busCapacity && childrenIds.length > busCapacity) {
        return {
          success: false,
          error: {
            message: `Cannot assign ${childrenIds.length} children to a bus with capacity ${busCapacity}`,
          },
        };
      }

      const response = await busApi.assignChildren(busId, childrenIds);
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
   * Get children assigned to a bus
   */
  async getBusChildren(busId: string): Promise<ApiResponse<any>> {
    try {
      const response = await busApi.getBusChildren(busId);
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
}

// Export singleton instance
export const busService = new BusService();
