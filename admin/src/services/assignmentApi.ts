import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api/assignments/';

// Assignment endpoints
export async function getAssignments(params?: Record<string, any>) {
  return axios.get(`${API_BASE_URL}list/`, { params });
}

export async function getAssignment(id: string) {
  return axios.get(`${API_BASE_URL}list/${id}/`);
}

export async function createAssignment(data: any) {
  return axios.post(`${API_BASE_URL}list/`, data);
}

export async function updateAssignment(id: string, data: any) {
  return axios.put(`${API_BASE_URL}list/${id}/`, data);
}

export async function deleteAssignment(id: string) {
  return axios.delete(`${API_BASE_URL}list/${id}/`);
}

export async function cancelAssignment(id: string, reason: string) {
  return axios.post(`${API_BASE_URL}list/${id}/cancel/`, { reason });
}

export async function getAssignmentHistory(id: string) {
  return axios.get(`${API_BASE_URL}list/${id}/history/`);
}

export async function bulkAssignChildrenToBus(busId: number, childrenIds: number[], effectiveDate?: string) {
  return axios.post(`${API_BASE_URL}list/bulk-assign-children-to-bus/`, {
    busId,
    childrenIds,
    effectiveDate
  });
}

export async function bulkAssignChildrenToRoute(routeId: number, childrenIds: number[], effectiveDate?: string) {
  return axios.post(`${API_BASE_URL}list/bulk-assign-children-to-route/`, {
    routeId,
    childrenIds,
    effectiveDate
  });
}

export async function getBusUtilization() {
  return axios.get(`${API_BASE_URL}list/bus-utilization/`);
}

export async function transferAssignment(assignmentId: number, newAssignedToId: number, newAssignedToType: string, reason?: string) {
  return axios.post(`${API_BASE_URL}list/transfer/`, {
    assignmentId,
    newAssignedToId,
    newAssignedToType,
    reason
  });
}

// Route endpoints
export async function getRoutes() {
  return axios.get(`${API_BASE_URL}routes/`);
}

export async function getRoute(id: string) {
  return axios.get(`${API_BASE_URL}routes/${id}/`);
}

export async function createRoute(data: any) {
  return axios.post(`${API_BASE_URL}routes/`, data);
}

export async function updateRoute(id: string, data: any) {
  return axios.put(`${API_BASE_URL}routes/${id}/`, data);
}

export async function deleteRoute(id: string) {
  return axios.delete(`${API_BASE_URL}routes/${id}/`);
}

export async function getRouteAssignments(id: string) {
  return axios.get(`${API_BASE_URL}routes/${id}/assignments/`);
}

export async function getRouteStatistics(id: string) {
  return axios.get(`${API_BASE_URL}routes/${id}/statistics/`);
}

// History endpoints
export async function getAllHistory(params?: Record<string, any>) {
  return axios.get(`${API_BASE_URL}history/`, { params });
}

export async function getHistoryEntry(id: string) {
  return axios.get(`${API_BASE_URL}history/${id}/`);
}
