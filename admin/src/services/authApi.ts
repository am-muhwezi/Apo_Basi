import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api';

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
 */
export async function login(credentials: LoginCredentials): Promise<AuthResponse> {
  const response = await axios.post(`${API_BASE_URL}/users/login/`, credentials);
  return response.data;
}

/**
 * Register new admin
 */
export async function signup(data: SignupData): Promise<AuthResponse> {
  const response = await axios.post(`${API_BASE_URL}/admins/register/`, data);
  return response.data;
}

/**
 * Logout user
 */
export async function logout(refreshToken: string): Promise<void> {
  const token = localStorage.getItem('adminToken');
  await axios.post(
    `${API_BASE_URL}/users/logout/`,
    { refresh_token: refreshToken },
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    }
  );
}

/**
 * Get user profile
 */
export async function getUserProfile() {
  const token = localStorage.getItem('adminToken');
  const response = await axios.get(`${API_BASE_URL}/users/profile/detail/`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
  return response.data;
}

/**
 * Refresh access token
 */
export async function refreshToken(refreshToken: string) {
  const response = await axios.post(`${API_BASE_URL}/users/token/refresh/`, {
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
