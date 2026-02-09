import axios from 'axios';
import axiosInstance from './axiosConfig';
import { config } from '../config/environment';

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface SignupData {
  username: string;
  email: string;
  password: string;
  password_confirm: string;
  first_name: string;
  last_name: string;
  user_type: string;
  phone_number?: string;
}

export interface AuthResponse {
  user: {
    id: string;
    username: string;
    email: string;
    first_name: string;
    last_name: string;
    role: string;
  };
  tokens: {
    access: string;
    refresh: string;
  };
  message: string;
}

/**
 * Login user
 * Note: Uses raw axios (not axiosInstance) to avoid auth interceptor during login
 */
export async function login(credentials: LoginCredentials): Promise<AuthResponse> {
  const response = await axios.post(`${config.apiBaseUrl}/api/users/login/`, credentials);
  return response.data;
}

/**
 * Register new admin - DISABLED FOR SECURITY
 * Admin accounts can only be created by existing administrators
 * Note: Backend endpoint is also disabled
 */
export async function signup(data: SignupData): Promise<AuthResponse> {
  throw new Error('Admin registration is disabled. Contact your administrator to create an account.');
}

/**
 * Logout user
 */
export async function logout(refreshToken: string): Promise<void> {
  await axiosInstance.post('/users/logout/', { refresh_token: refreshToken });
}

/**
 * Get user profile
 */
export async function getUserProfile() {
  const response = await axiosInstance.get('/users/profile/detail/');
  return response.data;
}

/**
 * Refresh access token
 * Note: Uses raw axios to avoid infinite loop in token refresh interceptor
 */
export async function refreshToken(refreshToken: string) {
  const response = await axios.post(`${config.apiBaseUrl}/api/users/token/refresh/`, {
    refresh: refreshToken,
  });
  return response.data;
}

/**
 * Store authentication data in localStorage
 */
export function storeAuthData(authResponse: AuthResponse) {
  localStorage.setItem('adminToken', authResponse.tokens.access);
  localStorage.setItem('adminRefreshToken', authResponse.tokens.refresh);
  localStorage.setItem('adminUser', JSON.stringify(authResponse.user));
}

/**
 * Clear authentication data from localStorage
 */
export function clearAuthData() {
  localStorage.removeItem('adminToken');
  localStorage.removeItem('adminRefreshToken');
  localStorage.removeItem('adminUser');
}

/**
 * Get stored user data
 */
export function getStoredUser() {
  const userStr = localStorage.getItem('adminUser');
  return userStr ? JSON.parse(userStr) : null;
}

/**
 * Check if user is authenticated
 */
export function isAuthenticated(): boolean {
  return !!localStorage.getItem('adminToken');
}
