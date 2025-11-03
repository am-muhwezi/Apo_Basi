import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api/children/';

// List all children with pagination support
export async function getChildren(params?: { limit?: number; offset?: number }) {
  return axios.get(`${API_BASE_URL}`, { params });
}

// Get single child
export async function getChild(id: string) {
  return axios.get(`${API_BASE_URL}${id}/`);
}

// Create new child
export async function createChild(data: {
  firstName: string;
  lastName: string;
  grade: string;
  age?: number;
  status?: string;
  parentId: string;
  assignedBusId?: string;
}) {
  return axios.post(`${API_BASE_URL}`, data);
}

// Update child
export async function updateChild(id: string, data: {
  firstName?: string;
  lastName?: string;
  grade?: string;
  age?: number;
  status?: string;
  parentId?: string;
  assignedBusId?: string;
}) {
  return axios.put(`${API_BASE_URL}${id}/`, data);
}

// Delete child
export async function deleteChild(id: string) {
  return axios.delete(`${API_BASE_URL}${id}/`);
}
