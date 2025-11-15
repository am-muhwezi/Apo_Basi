/**
 * Bus Minder Service Layer
 *
 * Business logic and error handling for bus minder operations.
 *
 * Architecture:
 * - Calls busMinderApi functions
 * - Handles errors and transforms them into user-friendly messages
 * - Returns consistent ApiResponse objects
 */

import * as busMinderApi from './busMinderApi';
import type { Minder } from '../types';
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
        const firstError = Object.values(data)[0];
        if (Array.isArray(firstError) && firstError.length > 0) {
          return firstError[0];
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

class BusMinderService {
  /**
   * Load all bus minders with pagination
   */
  async loadBusMinders(params?: PaginationParams): Promise<
    ApiResponse<{
      minders: Minder[];
      count: number;
      hasNext: boolean;
      hasPrevious: boolean;
    }>
  > {
    try {
      const response = await busMinderApi.getBusMinders(params);
      const { results, count, next, previous } = response.data;

      return {
        success: true,
        data: {
          minders: results || [],
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
   * Get a single bus minder by ID
   */
  async getBusMinder(id: string): Promise<ApiResponse<Minder>> {
    try {
      const response = await busMinderApi.getBusMinder(id);
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
   * Create new bus minder
   */
  async createBusMinder(formData: Partial<Minder>): Promise<ApiResponse<Minder>> {
    try {
      const response = await busMinderApi.createBusMinder({
        firstName: formData.firstName!,
        lastName: formData.lastName!,
        email: formData.email,
        phone: formData.phone!,
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
   * Update existing bus minder
   */
  async updateBusMinder(id: string, formData: Partial<Minder>): Promise<ApiResponse<Minder>> {
    try {
      const response = await busMinderApi.updateBusMinder(id, formData);
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
   * Delete bus minder
   */
  async deleteBusMinder(id: string): Promise<ApiResponse<void>> {
    try {
      await busMinderApi.deleteBusMinder(id);
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

export const busMinderService = new BusMinderService();
