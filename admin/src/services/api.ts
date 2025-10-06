
// API service for DRF backend integration
import axios from 'axios';

// Base URL for DRF backend (adjust as needed for your environment)
const API_BASE_URL = 'http://localhost:8000/';

/**
 * Registers a new parent via DRF backend.
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
	return axios.post(`${API_BASE_URL}/register/`, data);
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
	return axios.post(`${API_BASE_URL}api/admins/create-bus/`, data);
}
