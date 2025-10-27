import React from 'react';
import { X, MapPin, Clock, Users, AlertTriangle, CheckCircle } from 'lucide-react';
import { Bus } from '../types/bus';

interface BusDetailsModalProps {
  bus: Bus | null;
  isOpen: boolean;
  onClose: () => void;
}

const BusDetailsModal: React.FC<BusDetailsModalProps> = ({ bus, isOpen, onClose }) => {
  if (!isOpen || !bus) return null;

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'Active':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'Maintenance':
        return <AlertTriangle className="w-5 h-5 text-yellow-500" />;
      default:
        return <AlertTriangle className="w-5 h-5 text-gray-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Active':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'Inactive':
        return 'bg-gray-100 text-gray-800 border-gray-200';
      case 'Maintenance':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-2xl font-bold text-gray-900">Bus Details</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <X size={24} />
          </button>
        </div>

        <div className="p-6 space-y-6">
          {/* Bus Header */}
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-xl font-semibold text-gray-900">{bus.id}</h3>
              <p className="text-gray-600">{bus.route}</p>
            </div>
            <div className={`flex items-center space-x-2 px-4 py-2 rounded-lg border ${getStatusColor(bus.status)}`}>
              {getStatusIcon(bus.status)}
              <span className="font-medium">{bus.status}</span>
            </div>
          </div>

          {/* Key Metrics */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="bg-blue-50 p-4 rounded-lg">
              <div className="flex items-center space-x-2 mb-2">
                <Users className="w-5 h-5 text-blue-600" />
                <span className="text-sm font-medium text-blue-600">Capacity</span>
              </div>
              <p className="text-2xl font-bold text-blue-900">{bus.capacity}</p>
            </div>
            <div className="bg-green-50 p-4 rounded-lg">
              <div className="flex items-center space-x-2 mb-2">
                <Users className="w-5 h-5 text-green-600" />
                <span className="text-sm font-medium text-green-600">Onboard</span>
              </div>
              <p className="text-2xl font-bold text-green-900">{bus.studentsOnboard}</p>
            </div>
            <div className="bg-purple-50 p-4 rounded-lg">
              <div className="flex items-center space-x-2 mb-2">
                <MapPin className="w-5 h-5 text-purple-600" />
                <span className="text-sm font-medium text-purple-600">Route</span>
              </div>
              <p className="text-lg font-bold text-purple-900">{bus.route}</p>
            </div>
            <div className="bg-orange-50 p-4 rounded-lg">
              <div className="flex items-center space-x-2 mb-2">
                <Clock className="w-5 h-5 text-orange-600" />
                <span className="text-sm font-medium text-orange-600">Utilization</span>
              </div>
              <p className="text-lg font-bold text-orange-900">
                {Math.round((bus.studentsOnboard / bus.capacity) * 100)}%
              </p>
            </div>
          </div>

          {/* Driver Information */}
          <div className="bg-gray-50 p-4 rounded-lg">
            <h4 className="font-semibold text-gray-900 mb-3">Driver Information</h4>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-gray-600">Name:</span>
                <span className="font-medium text-gray-900">{bus.driver}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">License:</span>
                <span className="font-medium text-gray-900">CDL-{bus.id.slice(-3)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Experience:</span>
                <span className="font-medium text-gray-900">5+ years</span>
              </div>
            </div>
          </div>

          {/* Route Details */}
          <div className="bg-gray-50 p-4 rounded-lg">
            <h4 className="font-semibold text-gray-900 mb-3">Route Details</h4>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-gray-600">Morning Start:</span>
                <span className="font-medium text-gray-900">7:00 AM</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Afternoon Start:</span>
                <span className="font-medium text-gray-900">3:30 PM</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Total Stops:</span>
                <span className="font-medium text-gray-900">12</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Distance:</span>
                <span className="font-medium text-gray-900">15.2 miles</span>
              </div>
            </div>
          </div>

          {/* Last Updated */}
          <div className="border-t border-gray-200 pt-4">
            <div className="flex items-center space-x-2 text-sm text-gray-600">
              <Clock size={16} />
              <span>Last updated: {formatDate(bus.lastUpdated)}</span>
            </div>
          </div>
        </div>

        <div className="flex justify-end space-x-3 p-6 border-t border-gray-200">
          <button
            onClick={onClose}
            className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors duration-200"
          >
            Close
          </button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            Edit Bus
          </button>
        </div>
      </div>
    </div>
  );
};

export default BusDetailsModal;