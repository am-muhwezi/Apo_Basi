import axiosInstance from './axiosConfig';
import { AxiosResponse } from 'axios';

export type AnalyticsPeriod = 'week' | 'month' | 'year';

export interface MetricData {
  value: number;
  change: number;
  change_label: string;
}

export interface KeyMetrics {
  total_trips: MetricData;
  active_users: MetricData;
  fleet_utilization: MetricData;
  avg_trip_duration: MetricData;
}

export interface TripAnalyticsDay {
  day: string;
  completed: number;
  cancelled: number;
  delayed: number;
}

export interface BusPerformance {
  bus_id: number;
  bus_number: string;
  trips: number;
  on_time: number;
  rating: number;
}

export interface AttendanceStats {
  present_today: number;
  absent_today: number;
  attendance_rate: number;
}

export interface RouteEfficiency {
  avg_distance: number;
  fuel_efficiency: number;
  cost_per_trip: number;
  total_trips: number;
  data_sources: {
    avg_distance: string;
    fuel_efficiency: string;
    cost_per_trip: string;
  };
}

export interface SafetyAlerts {
  active_alerts: number;
  resolved_today: number;
  safety_score: number;
}

export interface FullAnalytics {
  metrics: KeyMetrics;
  trip_analytics: TripAnalyticsDay[];
  bus_performance: BusPerformance[];
  attendance: AttendanceStats;
  route_efficiency: RouteEfficiency;
  safety: SafetyAlerts;
}

/**
 * Get all analytics data in a single call
 */
export async function getAnalytics(period: AnalyticsPeriod = 'month'): Promise<AxiosResponse<FullAnalytics>> {
  return axiosInstance.get('/analytics/', { params: { period } });
}

/**
 * Get key metrics only
 */
export async function getKeyMetrics(period: AnalyticsPeriod = 'month'): Promise<AxiosResponse<KeyMetrics>> {
  return axiosInstance.get('/analytics/metrics/', { params: { period } });
}

/**
 * Get trip analytics grouped by day
 */
export async function getTripAnalytics(period: AnalyticsPeriod = 'month'): Promise<AxiosResponse<TripAnalyticsDay[]>> {
  return axiosInstance.get('/analytics/trips/', { params: { period } });
}

/**
 * Get bus performance data
 */
export async function getBusPerformance(period: AnalyticsPeriod = 'month', limit: number = 5): Promise<AxiosResponse<BusPerformance[]>> {
  return axiosInstance.get('/analytics/buses/', { params: { period, limit } });
}

/**
 * Get attendance statistics
 */
export async function getAttendanceStats(period: AnalyticsPeriod = 'month'): Promise<AxiosResponse<AttendanceStats>> {
  return axiosInstance.get('/analytics/attendance/', { params: { period } });
}

/**
 * Get route efficiency metrics
 */
export async function getRouteEfficiency(period: AnalyticsPeriod = 'month'): Promise<AxiosResponse<RouteEfficiency>> {
  return axiosInstance.get('/analytics/routes/', { params: { period } });
}

/**
 * Get safety alerts data
 */
export async function getSafetyAlerts(period: AnalyticsPeriod = 'month'): Promise<AxiosResponse<SafetyAlerts>> {
  return axiosInstance.get('/analytics/safety/', { params: { period } });
}
