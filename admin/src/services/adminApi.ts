import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api/admins/';

// List all admins with pagination support
export async function getAdmins(params?: { limit?: number; offset?: number }) {
  return axios.get(`${API_BASE_URL}`, { params });
}

// Get single admin
export async function getAdmin(id: string | number) {
  return axios.get(`${API_BASE_URL}${id}/`);
}

// Create admin
export async function createAdmin(data: {
  firstName: string;
  lastName: string;
  email?: string;
  phone: string;
  role?: 'super-admin' | 'admin' | 'viewer';
  status?: 'active' | 'inactive';
}) {
  return axios.post(`${API_BASE_URL}`, data);
}

// Update admin
export async function updateAdmin(id: string | number, data: {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  role?: 'super-admin' | 'admin' | 'viewer';
  status?: 'active' | 'inactive';
}) {
  return axios.put(`${API_BASE_URL}${id}/`, data);
}

// Delete admin
export async function deleteAdmin(id: string | number) {
  return axios.delete(`${API_BASE_URL}${id}/`);
}
