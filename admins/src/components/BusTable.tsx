import React from 'react';
import { Eye } from 'lucide-react';
import { Bus } from '../types/bus';

interface BusTableProps {
  buses: Bus[];
  onViewDetails: (bus: Bus) => void;
}

const BusTable: React.FC<BusTableProps> = ({ buses, onViewDetails }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Active':
        return 'bg-green-100 text-green-800';
      case 'Inactive':
        return 'bg-gray-100 text-gray-800';
      case 'Maintenance':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getCapacityColor = (current: number, total: number) => {
    const percentage = (current / total) * 100;
    if (percentage >= 90) return 'text-red-600';
    if (percentage >= 75) return 'text-yellow-600';
    return 'text-green-600';
  };

  return (
    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Bus ID</th>
              <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Route</th>
              <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Driver</th>
              <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Capacity</th>
              <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Students Onboard</th>
              <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Status</th>
              <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {buses.map((bus, index) => (
              <tr 
                key={bus.id} 
                className={`hover:bg-gray-50 transition-colors duration-150 ${
                  index % 2 === 0 ? 'bg-white' : 'bg-gray-25'
                }`}
              >
                <td className="px-6 py-4 text-sm font-medium text-gray-900">{bus.id}</td>
                <td className="px-6 py-4 text-sm text-blue-600 hover:text-blue-800 cursor-pointer">
                  {bus.route}
                </td>
                <td className="px-6 py-4 text-sm text-gray-700">{bus.driver}</td>
                <td className="px-6 py-4 text-sm text-gray-700">{bus.capacity}</td>
                <td className={`px-6 py-4 text-sm font-medium ${getCapacityColor(bus.studentsOnboard, bus.capacity)}`}>
                  {bus.studentsOnboard}
                </td>
                <td className="px-6 py-4">
                  <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(bus.status)}`}>
                    {bus.status}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center space-x-2">
                    <button 
                      onClick={() => onViewDetails(bus)}
                      className="text-blue-600 hover:text-blue-800 text-sm font-medium flex items-center space-x-1 px-2 py-1 rounded hover:bg-blue-50 transition-colors duration-150"
                    >
                      <Eye size={14} />
                      <span>View Details</span>
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default BusTable;