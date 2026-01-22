import * as parentApi from './parentApi';
import type { Parent } from '../types';
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

class ParentService {
  /**
   * Checks if a phone or email exists as a driver, minder, or parent.
   * Returns { exists: boolean, role: 'driver'|'minder'|'parent'|null }
   */
  async checkPhoneOrEmailExists(phone?: string, email?: string) {
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

  /**
   * Load all parents from DRF API with pagination
   */
  async loadParents(params?: PaginationParams): Promise<
    ApiResponse<{
      parents: Parent[];
      count: number;
      hasNext: boolean;
      hasPrevious: boolean;
    }>
  > {
    try {
      const response = await parentApi.getParents(params);
      const { results, count, next, previous } = response.data;

      return {
        success: true,
        data: {
          parents: results || [],
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
   * Get single parent by ID
   */
  async getParent(id: string): Promise<ApiResponse<Parent>> {
    try {
      const response = await parentApi.getParent(id);
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
   * Create new parent
   */
  async createParent(formData: Partial<Parent>): Promise<ApiResponse<Parent>> {
    try {
      const parentData = {
        firstName: formData.firstName!,
        lastName: formData.lastName!,
        email: formData.email,
        phone: formData.phone!,
        address: formData.address,
        emergencyContact: formData.emergencyContact,
        status: formData.status || 'active',
      };

      const response = await parentApi.createParent(parentData);
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
   * Update existing parent
   */
  async updateParent(id: string, formData: Partial<Parent>): Promise<ApiResponse<Parent>> {
    try {
      const parentData = {
        firstName: formData.firstName,
        lastName: formData.lastName,
        email: formData.email,
        phone: formData.phone,
        address: formData.address,
        emergencyContact: formData.emergencyContact,
        status: formData.status,
      };

      const response = await parentApi.updateParent(id, parentData);
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
   * Delete parent - returns children info if any exist
   * @param id Parent ID
   * @param action 'keep_children' | 'delete_children' | undefined
   */
  async deleteParent(id: string, action?: 'keep_children' | 'delete_children'): Promise<ApiResponse<any>> {
    try {
      const params = action ? { action } : undefined;
      const response = await parentApi.deleteParent(id, params);
      return {
        success: true,
        data: response.data,
      };
    } catch (error) {
      if (error instanceof AxiosError && error.response?.status === 400) {
        const data = error.response.data;
        if (data.requiresConfirmation) {
          // Return children info for confirmation dialog
          return {
            success: false,
            error: {
              message: data.message,
              requiresConfirmation: true,
              children: data.children,
              childrenCount: data.childrenCount,
            },
          };
        }
      }
      return {
        success: false,
        error: {
          message: getErrorMessage(error),
        },
      };
    }
  }
}

export const parentService = new ParentService();
