import axiosInstance from './axiosConfig';

// List all parents with pagination support
export async function getParents(params?: { limit?: number; offset?: number }) {
  return axiosInstance.get('/parents/', { params });
}

// Get single parent
export async function getParent(id: string) {
  return axiosInstance.get(`/parents/${id}/`);
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
  return axiosInstance.post('/parents/', data);
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
  return axiosInstance.put(`/parents/${id}/`, data);
}

// Delete parent
export async function deleteParent(id: string) {
  return axiosInstance.delete(`/parents/${id}/`);
}
