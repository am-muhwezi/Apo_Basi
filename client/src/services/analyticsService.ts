import { AxiosError } from 'axios';
import * as analyticsApi from './analyticsApi';
import type {
  AnalyticsPeriod,
  FullAnalytics,
  KeyMetrics,
  TripAnalyticsDay,
  BusPerformance,
  AttendanceStats,
  RouteEfficiency,
  SafetyAlerts,
} from './analyticsApi';

export type { AnalyticsPeriod, FullAnalytics, KeyMetrics, TripAnalyticsDay, BusPerformance, AttendanceStats, RouteEfficiency, SafetyAlerts };

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    message: string;
    statusCode?: number;
  };
}

function handleError(error: unknown): { message: string; statusCode?: number } {
  if (error instanceof AxiosError) {
    if (error.response) {
      return {
        message: error.response.data?.error || error.response.data?.detail || 'An error occurred',
        statusCode: error.response.status,
      };
    }
    if (error.request) {
      return { message: 'Network error. Please check your connection.' };
    }
  }
  return { message: 'An unexpected error occurred' };
}

export const analyticsService = {
  /**
   * Fetch all analytics data in a single call
   */
  async getFullAnalytics(period: AnalyticsPeriod = 'month'): Promise<ApiResponse<FullAnalytics>> {
    try {
      const response = await analyticsApi.getAnalytics(period);
      return { success: true, data: response.data };
    } catch (error) {
      return { success: false, error: handleError(error) };
    }
  },

  /**
   * Fetch key metrics only
   */
  async getKeyMetrics(period: AnalyticsPeriod = 'month'): Promise<ApiResponse<KeyMetrics>> {
    try {
      const response = await analyticsApi.getKeyMetrics(period);
      return { success: true, data: response.data };
    } catch (error) {
      return { success: false, error: handleError(error) };
    }
  },

  /**
   * Fetch trip analytics
   */
  async getTripAnalytics(period: AnalyticsPeriod = 'month'): Promise<ApiResponse<TripAnalyticsDay[]>> {
    try {
      const response = await analyticsApi.getTripAnalytics(period);
      return { success: true, data: response.data };
    } catch (error) {
      return { success: false, error: handleError(error) };
    }
  },

  /**
   * Fetch bus performance data
   */
  async getBusPerformance(period: AnalyticsPeriod = 'month', limit: number = 5): Promise<ApiResponse<BusPerformance[]>> {
    try {
      const response = await analyticsApi.getBusPerformance(period, limit);
      return { success: true, data: response.data };
    } catch (error) {
      return { success: false, error: handleError(error) };
    }
  },

  /**
   * Fetch attendance stats
   */
  async getAttendanceStats(period: AnalyticsPeriod = 'month'): Promise<ApiResponse<AttendanceStats>> {
    try {
      const response = await analyticsApi.getAttendanceStats(period);
      return { success: true, data: response.data };
    } catch (error) {
      return { success: false, error: handleError(error) };
    }
  },

  /**
   * Fetch route efficiency
   */
  async getRouteEfficiency(period: AnalyticsPeriod = 'month'): Promise<ApiResponse<RouteEfficiency>> {
    try {
      const response = await analyticsApi.getRouteEfficiency(period);
      return { success: true, data: response.data };
    } catch (error) {
      return { success: false, error: handleError(error) };
    }
  },

  /**
   * Fetch safety alerts
   */
  async getSafetyAlerts(period: AnalyticsPeriod = 'month'): Promise<ApiResponse<SafetyAlerts>> {
    try {
      const response = await analyticsApi.getSafetyAlerts(period);
      return { success: true, data: response.data };
    } catch (error) {
      return { success: false, error: handleError(error) };
    }
  },
};
