import React, { useState, useMemo } from 'react';
import { Search, Filter, Download } from 'lucide-react';
import BusTable from './BusTable';
import BusDetailsModal from './BusDetailsModal';
import { Bus, BusFilters } from '../types/bus';
import { mockBuses } from '../data/mockBuses';

const BusesView: React.FC = () => {
  const [selectedBus, setSelectedBus] = useState<Bus | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [filters, setFilters] = useState<BusFilters>({
    search: '',
    status: '',
    route: ''
  });

  const filteredBuses = useMemo(() => {
    return mockBuses.filter((bus: Bus) => {
      const matchesSearch = bus.id.toLowerCase().includes(filters.search.toLowerCase()) ||
                           bus.driver.toLowerCase().includes(filters.search.toLowerCase()) ||
                           bus.route.toLowerCase().includes(filters.search.toLowerCase());
      
      const matchesStatus = !filters.status || bus.status === filters.status;
      const matchesRoute = !filters.route || bus.route === filters.route;
      
      return matchesSearch && matchesStatus && matchesRoute;
    });
  }, [filters]);

  const uniqueRoutes = Array.from(new Set(mockBuses.map(bus => bus.route)));
  const uniqueStatuses = Array.from(new Set(mockBuses.map(bus => bus.status)));

  const handleViewDetails = (bus: Bus) => {
    setSelectedBus(bus);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedBus(null);
  };

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Buses</h1>
        <p className="text-gray-600">Manage and track your school's bus fleet in real-time.</p>
      </div>

      {/* Search and Filters */}
      <div className="mb-6 flex flex-col lg:flex-row lg:items-center lg:justify-between space-y-4 lg:space-y-0 lg:space-x-4">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Search buses..."
            value={filters.search}
            onChange={(e) => setFilters({ ...filters, search: e.target.value })}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
          />
        </div>
        
        <div className="flex items-center space-x-3">
          <select
            value={filters.status}
            onChange={(e) => setFilters({ ...filters, status: e.target.value })}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="">All Statuses</option>
            {uniqueStatuses.map(status => (
              <option key={status} value={status}>{status}</option>
            ))}
          </select>
          
          <select
            value={filters.route}
            onChange={(e) => setFilters({ ...filters, route: e.target.value })}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="">All Routes</option>
            {uniqueRoutes.map(route => (
              <option key={route} value={route}>{route}</option>
            ))}
          </select>
          
          <button className="flex items-center space-x-2 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors duration-200">
            <Filter size={16} />
            <span>Filter</span>
          </button>
          
          <button className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            <Download size={16} />
            <span>Export</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Total Buses</h3>
          <p className="text-2xl font-bold text-gray-900">{mockBuses.length}</p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Active Buses</h3>
          <p className="text-2xl font-bold text-green-600">
            {mockBuses.filter(bus => bus.status === 'Active').length}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Students Onboard</h3>
          <p className="text-2xl font-bold text-blue-600">
            {mockBuses.reduce((total, bus) => total + bus.studentsOnboard, 0)}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Total Capacity</h3>
          <p className="text-2xl font-bold text-purple-600">
            {mockBuses.reduce((total, bus) => total + bus.capacity, 0)}
          </p>
        </div>
      </div>

      {/* Results count */}
      <div className="mb-4">
        <p className="text-sm text-gray-600">
          Showing {filteredBuses.length} of {mockBuses.length} buses
        </p>
      </div>

      {/* Bus Table */}
      <BusTable buses={filteredBuses} onViewDetails={handleViewDetails} />

      {/* Bus Details Modal */}
      <BusDetailsModal 
        bus={selectedBus}
        isOpen={isModalOpen}
        onClose={handleCloseModal}
      />
    </div>
  );
};

export default BusesView;