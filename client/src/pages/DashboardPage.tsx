import React, { useState, useEffect } from 'react';
import {
  Bus,
  Users,
  Baby,
  AlertTriangle,
  TrendingUp,
  Clock,
  CheckCircle,
  XCircle
} from 'lucide-react';
import { dashboardService, DashboardStats } from '../services/dashboardService';

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  async function loadStats() {
    try {
      const data = await dashboardService.getStats();
      setStats(data);
    } catch (error) {
    } finally {
      setLoading(false);
    }
  }

  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'success':
        return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'warning':
        return <AlertTriangle className="w-4 h-4 text-yellow-500" />;
      case 'error':
        return <XCircle className="w-4 h-4 text-red-500" />;
      default:
        return <Clock className="w-4 h-4 text-blue-500" />;
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-slate-600">Loading dashboard...</div>
      </div>
    );
  }

  if (!stats) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-slate-600">Failed to load dashboard statistics</div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900 mb-2">Dashboard</h1>
        <p className="text-slate-600">Welcome back! Here's what's happening with your school transportation today.</p>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Bus className="w-6 h-6 text-blue-600" />
            </div>
            <span className="text-sm text-green-600 font-medium">
              {stats.buses.active} active
            </span>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Buses</h3>
          <p className="text-3xl font-bold text-slate-900">{stats.buses.total}</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-green-100 rounded-lg">
              <Baby className="w-6 h-6 text-green-600" />
            </div>
            <span className="text-sm text-green-600 font-medium">
              {Math.round((stats.children.active / stats.children.total) * 100) || 0}% active
            </span>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Students Enrolled</h3>
          <p className="text-3xl font-bold text-slate-900">
            {stats.children.active}/{stats.children.total}
          </p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Users className="w-6 h-6 text-purple-600" />
            </div>
            <span className="text-sm text-blue-600 font-medium">
              {stats.children.with_bus} assigned
            </span>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Students on Buses</h3>
          <p className="text-3xl font-bold text-slate-900">{stats.capacity.students_onboard}</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-yellow-100 rounded-lg">
              <AlertTriangle className="w-6 h-6 text-yellow-600" />
            </div>
            <span className="text-sm text-slate-600 font-medium">
              {stats.buses.inactive} inactive
            </span>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Buses in Maintenance</h3>
          <p className="text-3xl font-bold text-slate-900">{stats.buses.maintenance}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Recent Activity */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-slate-900">Recent Activity</h2>
            <button className="text-blue-600 hover:text-blue-800 text-sm font-medium">
              View All
            </button>
          </div>
          <div className="space-y-4">
            {stats.recent_activity.length > 0 ? (
              stats.recent_activity.map((activity) => (
                <div key={activity.id} className="flex items-center space-x-3 p-3 rounded-lg hover:bg-slate-50 transition-colors duration-150">
                  {getActivityIcon(activity.type)}
                  <div className="flex-1">
                    <p className="text-sm text-slate-900">{activity.action}</p>
                    <p className="text-xs text-slate-500">{activity.time}</p>
                  </div>
                </div>
              ))
            ) : (
              <p className="text-sm text-slate-500 text-center py-4">No recent activity</p>
            )}
          </div>
        </div>

        {/* Fleet Status */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-slate-900">Fleet Status</h2>
            <TrendingUp className="w-5 h-5 text-green-500" />
          </div>
          <div className="space-y-4">
            {stats.fleet_status.map((item) => (
              <div
                key={item.status}
                className={`flex items-center justify-between p-4 rounded-lg ${
                  item.color === 'green' ? 'bg-green-50' :
                  item.color === 'yellow' ? 'bg-yellow-50' :
                  'bg-slate-50'
                }`}
              >
                <div className="flex items-center space-x-3">
                  <div className={`w-3 h-3 rounded-full ${
                    item.color === 'green' ? 'bg-green-500' :
                    item.color === 'yellow' ? 'bg-yellow-500' :
                    'bg-slate-500'
                  }`}></div>
                  <span className="font-medium text-slate-900">{item.status}</span>
                </div>
                <span className={`text-lg font-bold ${
                  item.color === 'green' ? 'text-green-600' :
                  item.color === 'yellow' ? 'text-yellow-600' :
                  'text-slate-600'
                }`}>
                  {item.count}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="mt-8 bg-white rounded-xl border border-slate-200 shadow-sm p-6">
        <h2 className="text-lg font-semibold text-slate-900 mb-4">System Overview</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          <div>
            <p className="text-sm font-medium text-slate-600 mb-1">Parents</p>
            <p className="text-2xl font-bold text-slate-900">{stats.users.parents}</p>
          </div>
          <div>
            <p className="text-sm font-medium text-slate-600 mb-1">Drivers</p>
            <p className="text-2xl font-bold text-slate-900">{stats.users.drivers}</p>
          </div>
          <div>
            <p className="text-sm font-medium text-slate-600 mb-1">Bus Minders</p>
            <p className="text-2xl font-bold text-slate-900">{stats.users.minders}</p>
          </div>
          <div>
            <p className="text-sm font-medium text-slate-600 mb-1">Admins</p>
            <p className="text-2xl font-bold text-slate-900">{stats.users.admins}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
