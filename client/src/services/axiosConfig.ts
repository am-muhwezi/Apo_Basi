import axios from 'axios';
import { refreshToken } from './authApi';
import { config } from '../config/environment';

const API_BASE_URL = `${config.apiBaseUrl}/api`;

// Create axios instance with centralized configuration
const axiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: config.apiTimeout,
});

// Request interceptor to add auth token
axiosInstance.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('adminToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle token refresh
axiosInstance.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // If error is 401 and we haven't retried yet
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshTokenStr = localStorage.getItem('adminRefreshToken');

        if (!refreshTokenStr) {
          // No refresh token, redirect to login
          localStorage.clear();
          window.location.href = '/';
          return Promise.reject(error);
        }

        // Try to refresh the token
        const response = await refreshToken(refreshTokenStr);
        const newAccessToken = response.access;

        // Update stored token
        localStorage.setItem('adminToken', newAccessToken);

        // Retry original request with new token
        originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
        return axiosInstance(originalRequest);
      } catch (refreshError) {
        // Refresh failed, clear storage and redirect to login
        localStorage.clear();
        window.location.href = '/';
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);

export default axiosInstance;
