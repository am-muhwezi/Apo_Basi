/**
 * Centralized Environment Configuration
 *
 * Single source of truth for all environment-specific settings.
 * All environment variables should be defined here.
 *
 * Usage:
 * import { config } from '@/config/environment';
 */

export const config = {
  // API Configuration
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000',
  apiTimeout: 30000, // 30 seconds

  // Feature Flags
  enableDebugLogs: import.meta.env.DEV,

  // Pagination Defaults
  defaultPageSize: 20,
  maxPageSize: 100,
} as const;

/**
 * Validates that required environment variables are set
 * Call this in main.tsx to fail fast if config is invalid
 */
export function validateConfig(): void {
  if (!config.apiBaseUrl) {
    throw new Error('VITE_API_BASE_URL is required but not set');
  }

  if (config.enableDebugLogs) {
  }
}
