import React from 'react';
import { 
  Bus, 
  Users, 
  Route, 
  AlertTriangle, 
  TrendingUp, 
  Clock,
  CheckCircle,
  XCircle
} from 'lucide-react';
import { mockBuses } from '../data/mockBuses';
import { mockStudents } from '../data/mockStudents';
import { mockNotifications } from '../data/mockNotifications';

const DashboardView: React.FC = () => {
  const activeBuses = mockBuses.filter(bus => bus.status === 'Active').length;
  const totalStudents = mockStudents.length;
  const checkedInStudents = mockStudents.filter(student => student.checkInStatus === 'checked-in').length;
  const pendingNotifications = mockNotifications.filter(notification => !notification.read).length;
  const maintenanceBuses = mockBuses.filter(bus => bus.status === 'Maintenance').length;

  const recentActivity = [
    { id: 1, action: 'Bus 101 completed Route A', time: '8:45 AM', type: 'success' },
    { id: 2, action: 'Student Emma Johnson checked in', time: '8:30 AM', type: 'info' },
    { id: 3, action: 'Bus 106 requires maintenance', time: '8:15 AM', type: 'warning' },
    { id: 4, action: 'Route B experiencing delays', time: '8:00 AM', type: 'warning' },
    { id: 5, action: 'All morning routes started', time: '7:30 AM', type: 'success' }
  ];

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

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Dashboard</h1>
        <p className="text-gray-600">Welcome back! Here's what's happening with your school transportation today.</p>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Bus className="w-6 h-6 text-blue-600" />
            </div>
            <span className="text-sm text-green-600 font-medium">+2 from yesterday</span>
          </div>
          <h3 className="text-sm font-medium text-gray-600 mb-1">Active Buses</h3>
          <p className="text-3xl font-bold text-gray-900">{activeBuses}</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-green-100 rounded-lg">
              <Users className="w-6 h-6 text-green-600" />
            </div>
            <span className="text-sm text-green-600 font-medium">98% attendance</span>
          </div>
          <h3 className="text-sm font-medium text-gray-600 mb-1">Students Checked In</h3>
          <p className="text-3xl font-bold text-gray-900">{checkedInStudents}/{totalStudents}</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Route className="w-6 h-6 text-purple-600" />
            </div>
            <span className="text-sm text-blue-600 font-medium">All operational</span>
          </div>
          <h3 className="text-sm font-medium text-gray-600 mb-1">Active Routes</h3>
          <p className="text-3xl font-bold text-gray-900">7</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-yellow-100 rounded-lg">
              <AlertTriangle className="w-6 h-6 text-yellow-600" />
            </div>
            <span className="text-sm text-red-600 font-medium">{pendingNotifications} unread</span>
          </div>
          <h3 className="text-sm font-medium text-gray-600 mb-1">Alerts</h3>
          <p className="text-3xl font-bold text-gray-900">{maintenanceBuses}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Recent Activity */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-gray-900">Recent Activity</h2>
            <button className="text-blue-600 hover:text-blue-800 text-sm font-medium">
              View All
            </button>
          </div>
          <div className="space-y-4">
            {recentActivity.map((activity) => (
              <div key={activity.id} className="flex items-center space-x-3 p-3 rounded-lg hover:bg-gray-50 transition-colors duration-150">
                {getActivityIcon(activity.type)}
                <div className="flex-1">
                  <p className="text-sm text-gray-900">{activity.action}</p>
                  <p className="text-xs text-gray-500">{activity.time}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Fleet Status */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-gray-900">Fleet Status</h2>
            <TrendingUp className="w-5 h-5 text-green-500" />
          </div>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-green-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                <span className="font-medium text-gray-900">Active</span>
              </div>
              <span className="text-lg font-bold text-green-600">{activeBuses}</span>
            </div>
            <div className="flex items-center justify-between p-4 bg-yellow-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                <span className="font-medium text-gray-900">Maintenance</span>
              </div>
              <span className="text-lg font-bold text-yellow-600">{maintenanceBuses}</span>
            </div>
            <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="w-3 h-3 bg-gray-500 rounded-full"></div>
                <span className="font-medium text-gray-900">Inactive</span>
              </div>
              <span className="text-lg font-bold text-gray-600">
                {mockBuses.filter(bus => bus.status === 'Inactive').length}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mt-8 bg-white rounded-xl border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="flex items-center space-x-3 p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors duration-200">
            <Bus className="w-5 h-5 text-blue-600" />
            <span className="font-medium text-gray-900">Add New Bus</span>
          </button>
          <button className="flex items-center space-x-3 p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors duration-200">
            <Route className="w-5 h-5 text-purple-600" />
            <span className="font-medium text-gray-900">Create Route</span>
          </button>
          <button className="flex items-center space-x-3 p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors duration-200">
            <Users className="w-5 h-5 text-green-600" />
            <span className="font-medium text-gray-900">Add Student</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default DashboardView;