/**
 * Child API Layer
 *
 * Handles all HTTP requests related to children.
 * Uses configured axios instance with auth interceptors.
 *
 * Architecture:
 * - Uses axiosInstance (no hardcoded URLs)
 * - Strongly typed with API types
 * - Returns raw axios responses (error handling in service layer)
 */

import axiosInstance from './axiosConfig';
import type { AxiosResponse } from 'axios';
import type {
  PaginatedResponse,
  PaginationParams,
  ChildCreateData,
  ChildUpdateData,
} from '../types/api';
import type { Child } from '../types';

/**
 * Fetch all children with pagination support
 * GET /api/children/
 */
export async function getChildren(
  params?: PaginationParams
): Promise<AxiosResponse<PaginatedResponse<Child>>> {
  return axiosInstance.get('/children/', { params });
}

/**
 * Fetch a single child by ID
 * GET /api/children/:id/
 */
export async function getChild(id: string): Promise<AxiosResponse<Child>> {
  return axiosInstance.get(`/children/${id}/`);
}

/**
 * Create a new child
 * POST /api/children/
 */
export async function createChild(data: ChildCreateData): Promise<AxiosResponse<Child>> {
  return axiosInstance.post('/children/', data);
}

/**
 * Update an existing child
 * PUT /api/children/:id/
 */
export async function updateChild(
  id: string,
  data: ChildUpdateData
): Promise<AxiosResponse<Child>> {
  return axiosInstance.put(`/children/${id}/`, data);
}

/**
 * Delete a child
 * DELETE /api/children/:id/
 */
export async function deleteChild(id: string): Promise<AxiosResponse<void>> {
  return axiosInstance.delete(`/children/${id}/`);
}
