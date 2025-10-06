import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api/parents/';

// List all parents
export async function getParents() {
  return axios.get(`${API_BASE_URL}`);
}

// Get single parent
export async function getParent(id: string) {
  return axios.get(`${API_BASE_URL}${id}/`);
}

// Create new parent
export async function createParent(data: {
  firstName: string;
  lastName: string;
  email?: string;
  phone: string;
  address?: string;
  emergencyContact?: string;
  status?: string;
}) {
  return axios.post(`${API_BASE_URL}`, data);
}

// Update parent
export async function updateParent(id: string, data: {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  address?: string;
  emergencyContact?: string;
  status?: string;
}) {
  return axios.put(`${API_BASE_URL}${id}/`, data);
}

// Delete parent
export async function deleteParent(id: string) {
  return axios.delete(`${API_BASE_URL}${id}/`);
}
