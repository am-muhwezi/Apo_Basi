import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api/drivers/';

// List all drivers with pagination support
export async function getDrivers(params?: { limit?: number; offset?: number }) {
  return axios.get(`${API_BASE_URL}`, { params });
}

// Get single driver
export async function getDriver(id: string) {
  return axios.get(`${API_BASE_URL}${id}/`);
}

// Create a new driver
export async function createDriver(data: {
  firstName: string;
  lastName: string;
  email?: string;
  phone: string;
  licenseNumber: string;
  licenseExpiry?: string;
  status?: string;
  assignedBusId?: string;
}) {
  return axios.post(`${API_BASE_URL}`, data);
}

// Update driver
export async function updateDriver(id: string, data: {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  licenseNumber?: string;
  licenseExpiry?: string;
  status?: string;
  assignedBusId?: string;
}) {
  return axios.put(`${API_BASE_URL}${id}/`, data);
}

// Delete driver
export async function deleteDriver(id: string) {
  return axios.delete(`${API_BASE_URL}${id}/`);
}

// Legacy export for backward compatibility
export async function fetchDrivers() {
  return getDrivers();
}
