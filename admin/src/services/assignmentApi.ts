import axiosInstance from './axiosConfig';

// Assignment endpoints
export async function getAssignments(params?: Record<string, any>) {
  return axiosInstance.get('/assignments/list/', { params });
}

export async function getAssignment(id: string) {
  return axiosInstance.get(`/assignments/list/${id}/`);
}

export async function createAssignment(data: any) {
  return axiosInstance.post('/assignments/list/', data);
}

export async function updateAssignment(id: string, data: any) {
  return axiosInstance.put(`/assignments/list/${id}/`, data);
}

export async function deleteAssignment(id: string) {
  return axiosInstance.delete(`/assignments/list/${id}/`);
}

export async function cancelAssignment(id: string, reason: string) {
  return axiosInstance.post(`/assignments/list/${id}/cancel/`, { reason });
}

export async function getAssignmentHistory(id: string) {
  return axiosInstance.get(`/assignments/list/${id}/history/`);
}

export async function bulkAssignChildrenToBus(busId: number, childrenIds: number[], effectiveDate?: string) {
  return axiosInstance.post('/assignments/list/bulk_assign_children_to_bus/', {
    busId,
    childrenIds,
    effectiveDate
  });
}

export async function bulkAssignChildrenToRoute(routeId: number, childrenIds: number[], effectiveDate?: string) {
  return axiosInstance.post('/assignments/list/bulk_assign_children_to_route/', {
    routeId,
    childrenIds,
    effectiveDate
  });
}

export async function getBusUtilization() {
  return axiosInstance.get('/assignments/list/bus_utilization/');
}

export async function transferAssignment(assignmentId: number, newAssignedToId: number, newAssignedToType: string, reason?: string) {
  return axiosInstance.post('/assignments/list/transfer/', {
    assignmentId,
    newAssignedToId,
    newAssignedToType,
    reason
  });
}

// Route endpoints
export async function getRoutes() {
  return axiosInstance.get('/assignments/routes/');
}

export async function getRoute(id: string) {
  return axiosInstance.get(`/assignments/routes/${id}/`);
}

export async function createRoute(data: any) {
  return axiosInstance.post('/assignments/routes/', data);
}

export async function updateRoute(id: string, data: any) {
  return axiosInstance.put(`/assignments/routes/${id}/`, data);
}

export async function deleteRoute(id: string) {
  return axiosInstance.delete(`/assignments/routes/${id}/`);
}

export async function getRouteAssignments(id: string) {
  return axiosInstance.get(`/assignments/routes/${id}/assignments/`);
}

export async function getRouteStatistics(id: string) {
  return axiosInstance.get(`/assignments/routes/${id}/statistics/`);
}

// History endpoints
export async function getAllHistory(params?: Record<string, any>) {
  return axiosInstance.get('/assignments/history/', { params });
}

export async function getHistoryEntry(id: string) {
  return axiosInstance.get(`/assignments/history/${id}/`);
}
