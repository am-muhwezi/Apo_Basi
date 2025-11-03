import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api/trips/';

/**
 * Trip API Service - Manages trips and stops
 * Backend uses camelCase, frontend uses camelCase
 */

// List all trips with pagination support
export async function getTrips(params?: {
  status?: string;
  bus_id?: number;
  driver_id?: number;
  type?: 'pickup' | 'dropoff';
  limit?: number;
  offset?: number;
}) {
  return axios.get(`${API_BASE_URL}`, { params });
}

// Get single trip
export async function getTrip(id: string | number) {
  return axios.get(`${API_BASE_URL}${id}/`);
}

// Create trip
export async function createTrip(data: {
  busId: number;
  driverId: number;
  minderId?: number;
  route: string;
  type: 'pickup' | 'dropoff';
  status?: 'scheduled' | 'in-progress' | 'completed' | 'cancelled';
  scheduledTime: string;
  startTime?: string;
  endTime?: string;
  childrenIds?: number[];
  stops?: Array<{
    address: string;
    latitude: number;
    longitude: number;
    childrenIds?: number[];
    scheduledTime: string;
    status?: 'pending' | 'completed' | 'skipped';
    order: number;
  }>;
}) {
  return axios.post(`${API_BASE_URL}`, data);
}

// Update trip
export async function updateTrip(id: string | number, data: {
  busId?: number;
  driverId?: number;
  minderId?: number;
  route?: string;
  type?: 'pickup' | 'dropoff';
  status?: 'scheduled' | 'in-progress' | 'completed' | 'cancelled';
  scheduledTime?: string;
  startTime?: string;
  endTime?: string;
  childrenIds?: number[];
  stops?: Array<{
    address: string;
    latitude: number;
    longitude: number;
    childrenIds?: number[];
    scheduledTime: string;
    status?: 'pending' | 'completed' | 'skipped';
    order: number;
  }>;
}) {
  return axios.put(`${API_BASE_URL}${id}/`, data);
}

// Delete trip
export async function deleteTrip(id: string | number) {
  return axios.delete(`${API_BASE_URL}${id}/`);
}

// Start a trip
export async function startTrip(id: string | number) {
  return axios.post(`${API_BASE_URL}${id}/start/`);
}

// Complete a trip
export async function completeTrip(id: string | number) {
  return axios.post(`${API_BASE_URL}${id}/complete/`);
}

// Cancel a trip
export async function cancelTrip(id: string | number) {
  return axios.post(`${API_BASE_URL}${id}/cancel/`);
}

// Update trip location
export async function updateTripLocation(id: string | number, data: {
  latitude: number;
  longitude: number;
}) {
  return axios.post(`${API_BASE_URL}${id}/update-location/`, data);
}

// Get stops for a trip
export async function getTripStops(tripId: string | number) {
  return axios.get(`${API_BASE_URL}${tripId}/stops/`);
}

// Create stop for a trip
export async function createStop(tripId: string | number, data: {
  address: string;
  latitude: number;
  longitude: number;
  childrenIds?: number[];
  scheduledTime: string;
  status?: 'pending' | 'completed' | 'skipped';
  order: number;
}) {
  return axios.post(`${API_BASE_URL}${tripId}/stops/`, data);
}

// Update stop
export async function updateStop(stopId: string | number, data: {
  address?: string;
  latitude?: number;
  longitude?: number;
  childrenIds?: number[];
  scheduledTime?: string;
  actualTime?: string;
  status?: 'pending' | 'completed' | 'skipped';
  order?: number;
}) {
  return axios.put(`${API_BASE_URL}stops/${stopId}/`, data);
}

// Delete stop
export async function deleteStop(stopId: string | number) {
  return axios.delete(`${API_BASE_URL}stops/${stopId}/`);
}

// Complete a stop
export async function completeStop(stopId: string | number) {
  return axios.post(`${API_BASE_URL}stops/${stopId}/complete/`);
}

// Skip a stop
export async function skipStop(stopId: string | number) {
  return axios.post(`${API_BASE_URL}stops/${stopId}/skip/`);
}
