import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api/busminders/';

// List all bus minders with pagination support
export async function getBusMinders(params?: { limit?: number; offset?: number }) {
  return axios.get(`${API_BASE_URL}`, { params });
}

// Get single bus minder
export async function getBusMinder(id: string) {
  return axios.get(`${API_BASE_URL}${id}/`);
}

// Create new bus minder
export async function createBusMinder(data: {
  firstName: string;
  lastName: string;
  email?: string;
  phone: string;
  status?: string;
}) {
  return axios.post(`${API_BASE_URL}`, data);
}

// Update bus minder
export async function updateBusMinder(id: string, data: {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  status?: string;
}) {
  return axios.put(`${API_BASE_URL}${id}/`, data);
}

// Delete bus minder
export async function deleteBusMinder(id: string) {
  return axios.delete(`${API_BASE_URL}${id}/`);
}
