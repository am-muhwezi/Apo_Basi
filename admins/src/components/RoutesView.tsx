import React from 'react';
import { MapPin, Clock, Users, Bus } from 'lucide-react';

const RoutesView: React.FC = () => {
  const routes = [
    {
      id: 'Route A',
      busId: 'Bus 101',
      driver: 'Ethan Carter',
      students: 32,
      stops: 12,
      distance: '15.2 miles',
      duration: '45 minutes',
      startTime: '7:00 AM',
      status: 'Active'
    },
    {
      id: 'Route B',
      busId: 'Bus 102',
      driver: 'Olivia Bennett',
      students: 28,
      stops: 10,
      distance: '12.8 miles',
      duration: '40 minutes',
      startTime: '7:05 AM',
      status: 'Active'
    },
    {
      id: 'Route C',
      busId: 'Bus 103',
      driver: 'Noah Thompson',
      students: 35,
      stops: 14,
      distance: '18.5 miles',
      duration: '50 minutes',
      startTime: '6:55 AM',
      status: 'Active'
    },
    {
      id: 'Route D',
      busId: 'Bus 104',
      driver: 'Ava Harper',
      students: 40,
      stops: 16,
      distance: '20.1 miles',
      duration: '55 minutes',
      startTime: '6:50 AM',
      status: 'Active'
    },
    {
      id: 'Route E',
      busId: 'Bus 105',
      driver: 'Liam Foster',
      students: 30,
      stops: 11,
      distance: '14.3 miles',
      duration: '42 minutes',
      startTime: '7:10 AM',
      status: 'Active'
    }
  ];

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Routes</h1>
        <p className="text-gray-600">Manage and optimize school bus routes for efficient transportation.</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <div className="flex items-center space-x-3 mb-2">
            <MapPin className="w-5 h-5 text-blue-600" />
            <h3 className="text-sm font-medium text-gray-600">Total Routes</h3>
          </div>
          <p className="text-2xl font-bold text-gray-900">{routes.length}</p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <div className="flex items-center space-x-3 mb-2">
            <Users className="w-5 h-5 text-green-600" />
            <h3 className="text-sm font-medium text-gray-600">Total Students</h3>
          </div>
          <p className="text-2xl font-bold text-green-600">
            {routes.reduce((total, route) => total + route.students, 0)}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <div className="flex items-center space-x-3 mb-2">
            <MapPin className="w-5 h-5 text-purple-600" />
            <h3 className="text-sm font-medium text-gray-600">Total Stops</h3>
          </div>
          <p className="text-2xl font-bold text-purple-600">
            {routes.reduce((total, route) => total + route.stops, 0)}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <div className="flex items-center space-x-3 mb-2">
            <Clock className="w-5 h-5 text-orange-600" />
            <h3 className="text-sm font-medium text-gray-600">Avg Duration</h3>
          </div>
          <p className="text-2xl font-bold text-orange-600">47 min</p>
        </div>
      </div>

      {/* Routes Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {routes.map((route) => (
          <div key={route.id} className="bg-white rounded-xl border border-gray-200 p-6 hover:shadow-lg transition-shadow duration-200">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-3">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <MapPin className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">{route.id}</h3>
                  <p className="text-sm text-gray-600">{route.busId}</p>
                </div>
              </div>
              <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                {route.status}
              </span>
            </div>

            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="flex items-center space-x-2">
                <Users className="w-4 h-4 text-gray-500" />
                <span className="text-sm text-gray-600">{route.students} students</span>
              </div>
              <div className="flex items-center space-x-2">
                <MapPin className="w-4 h-4 text-gray-500" />
                <span className="text-sm text-gray-600">{route.stops} stops</span>
              </div>
              <div className="flex items-center space-x-2">
                <Clock className="w-4 h-4 text-gray-500" />
                <span className="text-sm text-gray-600">{route.duration}</span>
              </div>
              <div className="flex items-center space-x-2">
                <Bus className="w-4 h-4 text-gray-500" />
                <span className="text-sm text-gray-600">{route.distance}</span>
              </div>
            </div>

            <div className="border-t border-gray-200 pt-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-900">Driver: {route.driver}</p>
                  <p className="text-sm text-gray-600">Starts at {route.startTime}</p>
                </div>
                <button className="text-blue-600 hover:text-blue-800 text-sm font-medium px-3 py-1 rounded hover:bg-blue-50 transition-colors duration-150">
                  View Details
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="mt-8 bg-white rounded-xl border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Route Management</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="flex items-center space-x-3 p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors duration-200">
            <MapPin className="w-5 h-5 text-blue-600" />
            <span className="font-medium text-gray-900">Create New Route</span>
          </button>
          <button className="flex items-center space-x-3 p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors duration-200">
            <Clock className="w-5 h-5 text-purple-600" />
            <span className="font-medium text-gray-900">Optimize Routes</span>
          </button>
          <button className="flex items-center space-x-3 p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors duration-200">
            <Users className="w-5 h-5 text-green-600" />
            <span className="font-medium text-gray-900">Assign Students</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default RoutesView;