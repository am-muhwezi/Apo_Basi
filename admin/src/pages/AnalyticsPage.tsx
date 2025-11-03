import React, { useState, useEffect } from 'react';
import {
  BarChart3,
  TrendingUp,
  Users,
  Bus,
  Clock,
  MapPin,
  Calendar,
  Activity,
  DollarSign,
  AlertCircle,
  CheckCircle,
  ArrowUp,
  ArrowDown,
} from 'lucide-react';

interface MetricCard {
  title: string;
  value: string | number;
  change: number;
  changeLabel: string;
  icon: React.ReactNode;
  color: string;
}

export default function AnalyticsPage() {
  const [selectedPeriod, setSelectedPeriod] = useState<'week' | 'month' | 'year'>('month');
  const [loading, setLoading] = useState(false);

  // Mock data - replace with actual API calls
  const metrics: MetricCard[] = [
    {
      title: 'Total Trips',
      value: '1,234',
      change: 12.5,
      changeLabel: 'vs last month',
      icon: <MapPin className="w-6 h-6" />,
      color: 'blue',
    },
    {
      title: 'Active Users',
      value: '856',
      change: 8.2,
      changeLabel: 'vs last month',
      icon: <Users className="w-6 h-6" />,
      color: 'green',
    },
    {
      title: 'Fleet Utilization',
      value: '87%',
      change: 5.3,
      changeLabel: 'vs last month',
      icon: <Bus className="w-6 h-6" />,
      color: 'purple',
    },
    {
      title: 'Avg Trip Duration',
      value: '42 min',
      change: -3.1,
      changeLabel: 'vs last month',
      icon: <Clock className="w-6 h-6" />,
      color: 'orange',
    },
  ];

  const tripAnalytics = [
    { day: 'Mon', completed: 45, cancelled: 2, delayed: 3 },
    { day: 'Tue', completed: 52, cancelled: 1, delayed: 5 },
    { day: 'Wed', completed: 48, cancelled: 3, delayed: 2 },
    { day: 'Thu', completed: 55, cancelled: 1, delayed: 4 },
    { day: 'Fri', completed: 50, cancelled: 2, delayed: 3 },
    { day: 'Sat', completed: 20, cancelled: 0, delayed: 1 },
    { day: 'Sun', completed: 15, cancelled: 0, delayed: 0 },
  ];

  const busPerformance = [
    { busNumber: 'BUS-001', trips: 45, onTime: 95, rating: 4.8 },
    { busNumber: 'BUS-002', trips: 42, onTime: 92, rating: 4.6 },
    { busNumber: 'BUS-003', trips: 38, onTime: 88, rating: 4.5 },
    { busNumber: 'BUS-004', trips: 35, onTime: 90, rating: 4.7 },
    { busNumber: 'BUS-005', trips: 32, onTime: 85, rating: 4.4 },
  ];

  const getColorClasses = (color: string) => {
    const colors: { [key: string]: { bg: string; text: string; iconBg: string } } = {
      blue: { bg: 'bg-blue-50', text: 'text-blue-600', iconBg: 'bg-blue-100' },
      green: { bg: 'bg-green-50', text: 'text-green-600', iconBg: 'bg-green-100' },
      purple: { bg: 'bg-purple-50', text: 'text-purple-600', iconBg: 'bg-purple-100' },
      orange: { bg: 'bg-orange-50', text: 'text-orange-600', iconBg: 'bg-orange-100' },
    };
    return colors[color] || colors.blue;
  };

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
            {tripAnalytics.map((day, index) => {
              const total = day.completed + day.cancelled + day.delayed;
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
            })}
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
            {busPerformance.map((bus, index) => (
              <div
                key={index}
                className="flex items-center justify-between p-4 rounded-lg bg-slate-50 hover:bg-slate-100 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-blue-100 text-blue-600 font-bold text-sm">
                    #{index + 1}
                  </div>
                  <div>
                    <p className="font-medium text-slate-900">{bus.busNumber}</p>
                    <p className="text-xs text-slate-600">{bus.trips} trips</p>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <div className="text-right">
                    <p className="text-sm font-medium text-green-600">{bus.onTime}%</p>
                    <p className="text-xs text-slate-600">On-time</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-medium text-yellow-600">⭐ {bus.rating}</p>
                    <p className="text-xs text-slate-600">Rating</p>
                  </div>
                </div>
              </div>
            ))}
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
              <span className="text-lg font-bold text-green-600">742</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Absent</span>
              <span className="text-lg font-bold text-red-600">28</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Attendance Rate</span>
              <span className="text-lg font-bold text-blue-600">96.4%</span>
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
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Avg Distance</span>
              <span className="text-lg font-bold text-slate-900">18.5 km</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Fuel Efficiency</span>
              <span className="text-lg font-bold text-green-600">12.3 km/L</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Cost per Trip</span>
              <span className="text-lg font-bold text-orange-600">$45.20</span>
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
              <span className="text-lg font-bold text-yellow-600">3</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Resolved Today</span>
              <span className="text-lg font-bold text-green-600">12</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Safety Score</span>
              <span className="text-lg font-bold text-blue-600">98.5%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
