/**
 * Bus Minder API Layer
 *
 * Handles all HTTP requests related to bus minders.
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
  MinderCreateData,
  MinderUpdateData,
} from '../types/api';
import type { Minder } from '../types';

/**
 * Fetch all bus minders with pagination support
 * GET /api/busminders/
 */
export async function getBusMinders(
  params?: PaginationParams
): Promise<AxiosResponse<PaginatedResponse<Minder>>> {
  return axiosInstance.get('/busminders/', { params });
}

/**
 * Fetch a single bus minder by ID
 * GET /api/busminders/:id/
 */
export async function getBusMinder(id: string): Promise<AxiosResponse<Minder>> {
  return axiosInstance.get(`/busminders/${id}/`);
}

/**
 * Create a new bus minder
 * POST /api/busminders/
 */
export async function createBusMinder(data: MinderCreateData): Promise<AxiosResponse<Minder>> {
  return axiosInstance.post('/busminders/', data);
}

/**
 * Update an existing bus minder
 * PUT /api/busminders/:id/
 */
export async function updateBusMinder(
  id: string,
  data: MinderUpdateData
): Promise<AxiosResponse<Minder>> {
  return axiosInstance.put(`/busminders/${id}/`, data);
}

/**
 * Delete a bus minder
 * DELETE /api/busminders/:id/
 */
export async function deleteBusMinder(id: string): Promise<AxiosResponse<void>> {
  return axiosInstance.delete(`/busminders/${id}/`);
}
