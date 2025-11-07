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
