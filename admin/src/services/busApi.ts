import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api/buses/';

/**
 * Bus API Service - Simple, no mapping needed
 * Backend uses camelCase, frontend uses camelCase
 */

// List all buses with pagination support
export async function getBuses(params?: { limit?: number; offset?: number }) {
  return axios.get(`${API_BASE_URL}`, { params });
}

// Get single bus
export async function getBus(id: string) {
  return axios.get(`${API_BASE_URL}${id}/`);
}

// Create bus
export async function createBus(data: {
  busNumber: string;
  licensePlate: string;
  capacity: number;
  model?: string;
  year?: number;
  status?: string;
  lastMaintenance?: string;
}) {
  return axios.post(`${API_BASE_URL}`, data);
}

// Update bus
export async function updateBus(id: string, data: {
  busNumber?: string;
  licensePlate?: string;
  capacity?: number;
  model?: string;
  year?: number;
  status?: string;
  lastMaintenance?: string;
}) {
  return axios.put(`${API_BASE_URL}${id}/`, data);
}

// Delete bus
export async function deleteBus(id: string) {
  return axios.delete(`${API_BASE_URL}${id}/`);
}

// Assign driver to bus
export async function assignDriver(busId: string, driverId: string) {
  return axios.post(`${API_BASE_URL}${busId}/assign-driver/`, { driver_id: driverId });
}

// Assign minder to bus
export async function assignMinder(busId: string, minderId: string) {
  return axios.post(`${API_BASE_URL}${busId}/assign-minder/`, { minder_id: minderId });
}

// Assign children to bus
export async function assignChildren(busId: string, childrenIds: string[]) {
  return axios.post(`${API_BASE_URL}${busId}/assign-children/`, { children_ids: childrenIds });
}

// Get bus children
export async function getBusChildren(busId: string) {
  return axios.get(`${API_BASE_URL}${busId}/children/`);
}
