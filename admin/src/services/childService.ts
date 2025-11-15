/**
 * Child Service Layer
 *
 * Business logic and error handling for child operations.
 *
 * Architecture:
 * - Calls childApi functions
 * - Handles errors and transforms them into user-friendly messages
 * - Returns consistent ApiResponse objects
 */

import * as childApi from './childApi';
import type { Child } from '../types';
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

class ChildService {
  /**
   * Load all children with pagination
   */
  async loadChildren(params?: PaginationParams): Promise<
    ApiResponse<{
      children: Child[];
      count: number;
      hasNext: boolean;
      hasPrevious: boolean;
    }>
  > {
    try {
      const response = await childApi.getChildren(params);
      const { results, count, next, previous } = response.data;

      return {
        success: true,
        data: {
          children: results || [],
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
   * Get a single child by ID
   */
  async getChild(id: string): Promise<ApiResponse<Child>> {
    try {
      const response = await childApi.getChild(id);
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
   * Create new child
   */
  async createChild(formData: Partial<Child>): Promise<ApiResponse<Child>> {
    try {
      const response = await childApi.createChild({
        firstName: formData.firstName!,
        lastName: formData.lastName!,
        grade: formData.grade!,
        age: formData.age,
        status: formData.status || 'active',
        parentId: formData.parentId!,
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
   * Update existing child
   */
  async updateChild(id: string, formData: Partial<Child>): Promise<ApiResponse<Child>> {
    try {
      const response = await childApi.updateChild(id, formData);
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
   * Delete child
   */
  async deleteChild(id: string): Promise<ApiResponse<void>> {
    try {
      await childApi.deleteChild(id);
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

export const childService = new ChildService();
