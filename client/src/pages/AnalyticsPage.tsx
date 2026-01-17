import React, { useState, useEffect } from 'react';
import {
  TrendingUp,
  Users,
  Bus,
  Clock,
  MapPin,
  Activity,
  AlertCircle,
  CheckCircle,
  ArrowUp,
  ArrowDown,
  RefreshCw,
} from 'lucide-react';
import { analyticsService } from '../services/analyticsService';
import type {
  AnalyticsPeriod,
  FullAnalytics,
  TripAnalyticsDay,
  BusPerformance,
} from '../services/analyticsService';

interface MetricCardData {
  title: string;
  value: string | number;
  change: number;
  changeLabel: string;
  icon: React.ReactNode;
  color: string;
}

export default function AnalyticsPage() {
  const [selectedPeriod, setSelectedPeriod] = useState<AnalyticsPeriod>('month');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Analytics data state
  const [metrics, setMetrics] = useState<MetricCardData[]>([]);
  const [tripAnalytics, setTripAnalytics] = useState<TripAnalyticsDay[]>([]);
  const [busPerformance, setBusPerformance] = useState<BusPerformance[]>([]);
  const [attendanceStats, setAttendanceStats] = useState({
    present_today: 0,
    absent_today: 0,
    attendance_rate: 0,
  });
  const [routeEfficiency, setRouteEfficiency] = useState({
    avg_distance: 0,
    fuel_efficiency: 0,
    cost_per_trip: 0,
    data_sources: {
      avg_distance: '',
      fuel_efficiency: '',
      cost_per_trip: '',
    },
  });
  const [safetyAlerts, setSafetyAlerts] = useState({
    active_alerts: 0,
    resolved_today: 0,
    safety_score: 0,
  });

  const fetchAnalytics = async () => {
    setLoading(true);
    setError(null);

    const result = await analyticsService.getFullAnalytics(selectedPeriod);

    if (result.success && result.data) {
      const data = result.data;

      // Transform metrics to card format
      const metricsData: MetricCardData[] = [
        {
          title: 'Total Trips',
          value: data.metrics.total_trips.value.toLocaleString(),
          change: data.metrics.total_trips.change,
          changeLabel: data.metrics.total_trips.change_label,
          icon: <MapPin className="w-6 h-6" />,
          color: 'blue',
        },
        {
          title: 'Active Users',
          value: data.metrics.active_users.value.toLocaleString(),
          change: data.metrics.active_users.change,
          changeLabel: data.metrics.active_users.change_label,
          icon: <Users className="w-6 h-6" />,
          color: 'green',
        },
        {
          title: 'Fleet Utilization',
          value: `${data.metrics.fleet_utilization.value}%`,
          change: data.metrics.fleet_utilization.change,
          changeLabel: data.metrics.fleet_utilization.change_label,
          icon: <Bus className="w-6 h-6" />,
          color: 'purple',
        },
        {
          title: 'Avg Trip Duration',
          value: `${data.metrics.avg_trip_duration.value} min`,
          change: data.metrics.avg_trip_duration.change,
          changeLabel: data.metrics.avg_trip_duration.change_label,
          icon: <Clock className="w-6 h-6" />,
          color: 'orange',
        },
      ];

      setMetrics(metricsData);
      setTripAnalytics(data.trip_analytics);
      setBusPerformance(data.bus_performance);
      setAttendanceStats(data.attendance);
      setRouteEfficiency(data.route_efficiency);
      setSafetyAlerts(data.safety);
    } else {
      setError(result.error?.message || 'Failed to load analytics data');
    }

    setLoading(false);
  };

  useEffect(() => {
    fetchAnalytics();
  }, [selectedPeriod]);

  const getColorClasses = (color: string) => {
    const colors: { [key: string]: { bg: string; text: string; iconBg: string } } = {
      blue: { bg: 'bg-blue-50', text: 'text-blue-600', iconBg: 'bg-blue-100' },
      green: { bg: 'bg-green-50', text: 'text-green-600', iconBg: 'bg-green-100' },
      purple: { bg: 'bg-purple-50', text: 'text-purple-600', iconBg: 'bg-purple-100' },
      orange: { bg: 'bg-orange-50', text: 'text-orange-600', iconBg: 'bg-orange-100' },
    };
    return colors[color] || colors.blue;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <div className="flex flex-col items-center gap-4">
          <RefreshCw className="w-8 h-8 animate-spin text-blue-600" />
          <p className="text-slate-600">Loading analytics...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <div className="flex flex-col items-center gap-4 text-center">
          <AlertCircle className="w-12 h-12 text-red-500" />
          <p className="text-slate-900 font-medium">Failed to load analytics</p>
          <p className="text-slate-600">{error}</p>
          <button
            onClick={fetchAnalytics}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-8 flex flex-col md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 mb-2">Analytics & Reports</h1>
          <p className="text-slate-600">Track performance and gain insights into your operations</p>
        </div>

        {/* Period Selector */}
        <div className="mt-4 md:mt-0 flex gap-2">
          <button
            onClick={() => setSelectedPeriod('week')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              selectedPeriod === 'week'
                ? 'bg-blue-600 text-white'
                : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-50'
            }`}
          >
            Week
          </button>
          <button
            onClick={() => setSelectedPeriod('month')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              selectedPeriod === 'month'
                ? 'bg-blue-600 text-white'
                : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-50'
            }`}
          >
            Month
          </button>
          <button
            onClick={() => setSelectedPeriod('year')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              selectedPeriod === 'year'
                ? 'bg-blue-600 text-white'
                : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-50'
            }`}
          >
            Year
          </button>
          <button
            onClick={fetchAnalytics}
            className="px-3 py-2 rounded-lg text-sm font-medium bg-white text-slate-700 border border-slate-200 hover:bg-slate-50 transition-colors"
            title="Refresh data"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {metrics.map((metric, index) => {
          const colorClasses = getColorClasses(metric.color);
          const isPositive = metric.change > 0;

          return (
            <div key={index} className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <div className={`p-2 rounded-lg ${colorClasses.iconBg} ${colorClasses.text}`}>
                  {metric.icon}
                </div>
                <div className={`flex items-center gap-1 text-sm font-medium ${
                  isPositive ? 'text-green-600' : 'text-red-600'
                }`}>
                  {isPositive ? <ArrowUp size={16} /> : <ArrowDown size={16} />}
                  {Math.abs(metric.change)}%
                </div>
              </div>
              <h3 className="text-sm font-medium text-slate-600 mb-1">{metric.title}</h3>
              <p className="text-3xl font-bold text-slate-900 mb-1">{metric.value}</p>
              <p className="text-xs text-slate-500">{metric.changeLabel}</p>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        {/* Trip Analytics Chart */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-slate-900">Weekly Trip Analytics</h2>
            <Activity className="w-5 h-5 text-blue-600" />
          </div>

          <div className="space-y-4">
            {tripAnalytics.length > 0 ? (
              tripAnalytics.map((day, index) => {
                const total = day.completed + day.cancelled + day.delayed;
                if (total === 0) {
                  return (
                    <div key={index}>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-medium text-slate-700">{day.day}</span>
                        <span className="text-sm text-slate-600">No trips</span>
                      </div>
                      <div className="w-full h-8 rounded-lg bg-slate-100"></div>
                    </div>
                  );
                }
                const completedPercent = (day.completed / total) * 100;
                const delayedPercent = (day.delayed / total) * 100;
                const cancelledPercent = (day.cancelled / total) * 100;

                return (
                  <div key={index}>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium text-slate-700">{day.day}</span>
                      <span className="text-sm text-slate-600">{total} trips</span>
                    </div>
                    <div className="flex w-full h-8 rounded-lg overflow-hidden">
                      <div
                        className="bg-green-500 flex items-center justify-center text-xs text-white font-medium"
                        style={{ width: `${completedPercent}%` }}
                      >
                        {day.completed > 0 && day.completed}
                      </div>
                      <div
                        className="bg-yellow-500 flex items-center justify-center text-xs text-white font-medium"
                        style={{ width: `${delayedPercent}%` }}
                      >
                        {day.delayed > 0 && day.delayed}
                      </div>
                      <div
                        className="bg-red-500 flex items-center justify-center text-xs text-white font-medium"
                        style={{ width: `${cancelledPercent}%` }}
                      >
                        {day.cancelled > 0 && day.cancelled}
                      </div>
                    </div>
                  </div>
                );
              })
            ) : (
              <div className="text-center py-8 text-slate-500">
                No trip data available for this period
              </div>
            )}
          </div>

          <div className="flex items-center justify-center gap-6 mt-6 pt-6 border-t border-slate-200">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-green-500"></div>
              <span className="text-xs text-slate-600">Completed</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
              <span className="text-xs text-slate-600">Delayed</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-red-500"></div>
              <span className="text-xs text-slate-600">Cancelled</span>
            </div>
          </div>
        </div>

        {/* Bus Performance */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-slate-900">Top Performing Buses</h2>
            <TrendingUp className="w-5 h-5 text-green-600" />
          </div>

          <div className="space-y-4">
            {busPerformance.length > 0 ? (
              busPerformance.map((bus, index) => (
                <div
                  key={bus.bus_id}
                  className="flex items-center justify-between p-4 rounded-lg bg-slate-50 hover:bg-slate-100 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-blue-100 text-blue-600 font-bold text-sm">
                      #{index + 1}
                    </div>
                    <div>
                      <p className="font-medium text-slate-900">{bus.bus_number}</p>
                      <p className="text-xs text-slate-600">{bus.trips} trips</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="text-right">
                      <p className="text-sm font-medium text-green-600">{bus.on_time}%</p>
                      <p className="text-xs text-slate-600">On-time</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-medium text-yellow-600">{bus.rating.toFixed(1)}</p>
                      <p className="text-xs text-slate-600">Rating</p>
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-8 text-slate-500">
                No bus performance data available
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Additional Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Student Attendance */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-slate-900">Student Attendance</h3>
            <CheckCircle className="w-5 h-5 text-green-600" />
          </div>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Present Today</span>
              <span className="text-lg font-bold text-green-600">{attendanceStats.present_today}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Absent</span>
              <span className="text-lg font-bold text-red-600">{attendanceStats.absent_today}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Attendance Rate</span>
              <span className="text-lg font-bold text-blue-600">{attendanceStats.attendance_rate}%</span>
            </div>
          </div>
        </div>

        {/* Route Efficiency */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-slate-900">Route Efficiency</h3>
            <MapPin className="w-5 h-5 text-purple-600" />
          </div>
          <div className="space-y-3">
            <div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-slate-600">Avg Distance</span>
                <span className="text-lg font-bold text-slate-900">{routeEfficiency.avg_distance} km</span>
              </div>
              {routeEfficiency.data_sources?.avg_distance && (
                <p className="text-xs text-slate-400 mt-1">Source: {routeEfficiency.data_sources.avg_distance}</p>
              )}
            </div>
            <div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-slate-600">Fuel Efficiency</span>
                <span className="text-lg font-bold text-green-600">{routeEfficiency.fuel_efficiency} km/L</span>
              </div>
              {routeEfficiency.data_sources?.fuel_efficiency && (
                <p className="text-xs text-slate-400 mt-1">Source: {routeEfficiency.data_sources.fuel_efficiency}</p>
              )}
            </div>
            <div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-slate-600">Cost per Trip</span>
                <span className="text-lg font-bold text-orange-600">${routeEfficiency.cost_per_trip.toFixed(2)}</span>
              </div>
              {routeEfficiency.data_sources?.cost_per_trip && (
                <p className="text-xs text-slate-400 mt-1">Source: {routeEfficiency.data_sources.cost_per_trip}</p>
              )}
            </div>
          </div>
        </div>

        {/* Incidents & Alerts */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-slate-900">Safety & Alerts</h3>
            <AlertCircle className="w-5 h-5 text-yellow-600" />
          </div>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Active Alerts</span>
              <span className="text-lg font-bold text-yellow-600">{safetyAlerts.active_alerts}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Resolved Today</span>
              <span className="text-lg font-bold text-green-600">{safetyAlerts.resolved_today}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Safety Score</span>
              <span className="text-lg font-bold text-blue-600">{safetyAlerts.safety_score}%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
