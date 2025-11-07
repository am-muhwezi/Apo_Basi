import axiosInstance from './axiosConfig';

// List all admins with pagination support
export async function getAdmins(params?: { limit?: number; offset?: number }) {
  return axiosInstance.get('/admins/', { params });
}

// Get single admin
export async function getAdmin(id: string | number) {
  return axiosInstance.get(`/admins/${id}/`);
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
  return axiosInstance.post('/admins/', data);
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
  return axiosInstance.put(`/admins/${id}/`, data);
}

// Delete admin
export async function deleteAdmin(id: string | number) {
  return axiosInstance.delete(`/admins/${id}/`);
}
