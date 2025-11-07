/**
 * Driver API Layer
 *
 * Handles all HTTP requests related to drivers.
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
  DriverCreateData,
  DriverUpdateData,
} from '../types/api';
import type { Driver } from '../types';

/**
 * Fetch all drivers with pagination support
 * GET /api/drivers/
 */
export async function getDrivers(
  params?: PaginationParams
): Promise<AxiosResponse<PaginatedResponse<Driver>>> {
  return axiosInstance.get('/drivers/', { params });
}

/**
 * Fetch a single driver by ID
 * GET /api/drivers/:id/
 */
export async function getDriver(id: string): Promise<AxiosResponse<Driver>> {
  return axiosInstance.get(`/drivers/${id}/`);
}

/**
 * Create a new driver
 * POST /api/drivers/
 */
export async function createDriver(data: DriverCreateData): Promise<AxiosResponse<Driver>> {
  return axiosInstance.post('/drivers/', data);
}

/**
 * Update an existing driver
 * PUT /api/drivers/:id/
 */
export async function updateDriver(
  id: string,
  data: DriverUpdateData
): Promise<AxiosResponse<Driver>> {
  return axiosInstance.put(`/drivers/${id}/`, data);
}

/**
 * Delete a driver
 * DELETE /api/drivers/:id/
 */
export async function deleteDriver(id: string): Promise<AxiosResponse<void>> {
  return axiosInstance.delete(`/drivers/${id}/`);
}
