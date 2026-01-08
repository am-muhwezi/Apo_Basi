/**
 * Parent API Layer
 *
 * This layer handles all HTTP requests related to parents.
 * It uses the configured axios instance with auth interceptors.
 *
 * Architecture:
 * - Uses axiosInstance (no hardcoded URLs)
 * - Strongly typed with API types
 * - Returns raw axios responses (error handling in service layer)
 *
 * Junior Dev Guide:
 * - Always use axiosInstance, not raw axios
 * - All URLs are relative (baseURL is in axiosConfig)
 * - Don't handle business logic here (that's for service layer)
 * - Let errors bubble up (service layer catches them)
 */

import axiosInstance from './axiosConfig';
import type { AxiosResponse } from 'axios';
import type {
  PaginatedResponse,
  PaginationParams,
  ParentCreateData,
  ParentUpdateData,
} from '../types/api';
import type { Parent } from '../types';

/**
 * Fetch all parents with pagination support
 * GET /api/parents/
 */
export async function getParents(
  params?: PaginationParams
): Promise<AxiosResponse<PaginatedResponse<Parent>>> {
  return axiosInstance.get('/parents/', { params });
}

/**
 * Fetch a single parent by ID
 * GET /api/parents/:id/
 */
export async function getParent(id: string): Promise<AxiosResponse<Parent>> {
  return axiosInstance.get(`/parents/${id}/`);
}

/**
 * Create a new parent
 * POST /api/parents/
 *
 * Example:
 * const newParent = {
 *   firstName: 'John',
 *   lastName: 'Doe',
 *   email: 'john.doe@example.com',
 *   phone: '1234567890',
 *   address: '123 Main St',
 *   emergencyContact: '0987654321',
 *   status: 'active'
 * };
 * await createParent(newParent);
 */
export async function createParent(
  data: ParentCreateData
): Promise<AxiosResponse<Parent>> {
  return axiosInstance.post('/parents/', data);
}

/**
 * Update an existing parent
 * PUT /api/parents/:id/
 */
export async function updateParent(
  id: string,
  data: ParentUpdateData
): Promise<AxiosResponse<Parent>> {
  return axiosInstance.put(`/parents/${id}/`, data);
}

/**
 * Partially update a parent
 * PATCH /api/parents/:id/
 */
export async function patchParent(
  id: string,
  data: ParentUpdateData
): Promise<AxiosResponse<Parent>> {
  return axiosInstance.patch(`/parents/${id}/`, data);
}

/**
 * Delete a parent
 * DELETE /api/parents/:id/
 * @param id Parent ID
 * @param params Optional query parameters (e.g., { action: 'keep_children' })
 */
export async function deleteParent(
  id: string,
  params?: Record<string, string>
): Promise<AxiosResponse<any>> {
  return axiosInstance.delete(`/parents/${id}/`, { params });
}

/**
 * Get children for a specific parent
 * GET /api/parents/:id/children/
 */
export async function getParentChildren(parentId: string): Promise<AxiosResponse<any>> {
  return axiosInstance.get(`/parents/${parentId}/children/`);
}
