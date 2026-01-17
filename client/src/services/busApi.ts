/**
 * Bus API Layer
 *
 * This layer handles all HTTP requests related to buses.
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
  BusCreateData,
  BusUpdateData,
  DriverAssignmentData,
  MinderAssignmentData,
  ChildrenAssignmentData,
} from '../types/api';
import type { Bus } from '../types';

/**
 * Fetch all buses with pagination support
 * GET /api/buses/
 */
export async function getBuses(
  params?: PaginationParams
): Promise<AxiosResponse<PaginatedResponse<Bus>>> {
  return axiosInstance.get('/buses/', { params });
}

/**
 * Fetch a single bus by ID
 * GET /api/buses/:id/
 */
export async function getBus(id: string): Promise<AxiosResponse<Bus>> {
  return axiosInstance.get(`/buses/${id}/`);
}

/**
 * Create a new bus
 * POST /api/buses/
 *
 * Example:
 * const newBus = {
 *   busNumber: 'BUS-001',
 *   licensePlate: 'ABC123',
 *   capacity: 40,
 *   model: 'Mercedes Sprinter',
 *   year: 2024,
 *   status: 'active'
 * };
 * await createBus(newBus);
 */
export async function createBus(data: BusCreateData): Promise<AxiosResponse<Bus>> {
  return axiosInstance.post('/buses/', data);
}

/**
 * Update an existing bus
 * PUT /api/buses/:id/
 */
export async function updateBus(
  id: string,
  data: BusUpdateData
): Promise<AxiosResponse<Bus>> {
  return axiosInstance.put(`/buses/${id}/`, data);
}

/**
 * Partially update a bus
 * PATCH /api/buses/:id/
 */
export async function patchBus(
  id: string,
  data: BusUpdateData
): Promise<AxiosResponse<Bus>> {
  return axiosInstance.patch(`/buses/${id}/`, data);
}

/**
 * Delete a bus
 * DELETE /api/buses/:id/
 */
export async function deleteBus(id: string): Promise<AxiosResponse<void>> {
  return axiosInstance.delete(`/buses/${id}/`);
}

/**
 * Assign a driver to a bus
 * POST /api/buses/:id/assign-driver/
 */
export async function assignDriver(
  busId: string,
  driverId: string
): Promise<AxiosResponse<any>> {
  const data: DriverAssignmentData = { driver_id: driverId };
  return axiosInstance.post(`/buses/${busId}/assign-driver/`, data);
}

/**
 * Assign a minder to a bus
 * POST /api/buses/:id/assign-minder/
 */
export async function assignMinder(
  busId: string,
  minderId: string
): Promise<AxiosResponse<any>> {
  const data: MinderAssignmentData = { minder_id: minderId };
  return axiosInstance.post(`/buses/${busId}/assign-minder/`, data);
}

/**
 * Assign children to a bus
 * POST /api/buses/:id/assign-children/
 */
export async function assignChildren(
  busId: string,
  childrenIds: string[]
): Promise<AxiosResponse<any>> {
  const data: ChildrenAssignmentData = { children_ids: childrenIds };
  return axiosInstance.post(`/buses/${busId}/assign-children/`, data);
}

/**
 * Get children assigned to a bus
 * GET /api/buses/:id/children/
 */
export async function getBusChildren(busId: string): Promise<AxiosResponse<any>> {
  return axiosInstance.get(`/buses/${busId}/children/`);
}
