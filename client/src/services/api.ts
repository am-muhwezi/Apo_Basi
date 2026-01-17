// API service for DRF backend integration
import axiosInstance from './axiosConfig';
import { config } from '../config/environment';
import axios from 'axios';

/**
 * Registers a new parent via DRF backend.
 * Note: Uses raw axios (not axiosInstance) to avoid auth interceptor during registration
 * @param data - Parent registration fields matching backend requirements
 * @returns Axios response promise
 *
 * Junior Dev Guide:
 * - Always match field names to backend expectations
 * - Use async/await and handle errors in your component
 */
export async function registerParent(data: {
	username: string;
	email: string;
	password: string;
	password_confirm: string;
	first_name: string;
	last_name: string;
	phone_number: string;
}) {
	return axios.post(`${config.apiBaseUrl}/register/`, data);
}

/**
 * Creates a new bus via DRF backend.
 * @param data - Bus creation fields matching backend requirements
 * @returns Axios response promise
 *
 * Junior Dev Guide:
 * - licensePlate maps to number_plate in backend
 * - status is a boolean (is_active)
 * - capacity is required
 *
 * Example usage:
 *
 * import { createBus } from './api';
 *
 * async function handleBusCreate(formData) {
 *   const busData = {
 *     license_plate: formData.licensePlate,
 *     capacity: formData.capacity,
 *     status: formData.status === 'active', // Convert to boolean
 *   };
 *   try {
 *     const response = await createBus(busData);
 *     // response.data.bus contains the created bus
 *     // response.data.message contains the status message
 *   } catch (error) {
 *     // Handle error (show error message)
 *   }
 * }
 */
export async function createBus(data: {
	license_plate: string; // UI field, maps to number_plate
	capacity: number;
	status: boolean; // UI boolean, maps to is_active
}) {
	return axiosInstance.post('/admins/create-bus/', data);
}

/**
 * Fetches attendance statistics for a specific date
 * @param date - Date in YYYY-MM-DD format (optional, defaults to today)
 * @param busId - Filter by specific bus (optional)
 * @returns Attendance statistics
 */
export async function getAttendanceStats(date?: string, busId?: number) {
	const params = new URLSearchParams();
	if (date) params.append('date', date);
	if (busId) params.append('bus_id', busId.toString());

	return axiosInstance.get(`/attendance/stats/?${params.toString()}`);
}

/**
 * Fetches daily attendance report with detailed breakdown by bus
 * @param date - Date in YYYY-MM-DD format (optional, defaults to today)
 * @returns Daily attendance report grouped by bus
 */
export async function getDailyAttendanceReport(date?: string) {
	const params = date ? `?date=${date}` : '';
	return axiosInstance.get(`/attendance/daily-report/${params}`);
}

/**
 * Fetches attendance records with filtering
 * @param filters - Optional filters (date, child_id, bus_id, status)
 * @returns List of attendance records
 */
export async function getAttendanceRecords(filters?: {
	date?: string;
	child_id?: number;
	bus_id?: number;
	status?: string;
}) {
	const params = new URLSearchParams();
	if (filters?.date) params.append('date', filters.date);
	if (filters?.child_id) params.append('child_id', filters.child_id.toString());
	if (filters?.bus_id) params.append('bus_id', filters.bus_id.toString());
	if (filters?.status) params.append('status', filters.status);

	return axiosInstance.get(`/attendance/?${params.toString()}`);
}
