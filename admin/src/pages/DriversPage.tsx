import React, { useState } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2, UserCircle, Bus as BusIcon, CheckCircle, Users } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import { driverService } from '../services/driverService';
import { assignmentService } from '../services/assignmentService';
import type { Driver, Bus, Assignment } from '../types';

export default function DriversPage() {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [buses, setBuses] = useState<Bus[]>([]);
  const [assignments, setAssignments] = useState<Assignment[]>([]);

  // Fetch drivers, buses, and assignments from backend on mount
  React.useEffect(() => {
    loadDrivers();
    loadBuses();
    loadAssignments();
  }, []);

  async function loadDrivers() {
    try {
      const data = await driverService.loadDrivers();
      setDrivers(data);
    } catch (error) {
      console.error('Failed to load drivers:', error);
    }
  }

  async function loadBuses() {
    try {
      const data = await driverService.loadBuses();
      setBuses(data);
    } catch (error) {
      console.error('Failed to load buses:', error);
    }
  }

  async function loadAssignments() {
    try {
      const data = await assignmentService.loadAssignments({ assignmentType: 'driver_to_bus' });
      setAssignments(data);
    } catch (error) {
      console.error('Failed to load assignments:', error);
    }
  }
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [formData, setFormData] = useState<Partial<Driver>>({});

  const filteredDrivers = drivers.filter((driver) => {
    const matchesSearch =
      driver.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      driver.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      driver.email.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesSearch;
  });

  const handleCreate = () => {
    setSelectedDriver(null);
    setFormData({
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      licenseNumber: '',
      licenseExpiry: '',
      status: 'active',
    });
    setShowModal(true);
  };

  const handleEdit = (driver: Driver) => {
    setSelectedDriver(driver);
    setFormData(driver);
    setShowModal(true);
  };

  const handleView = (driver: Driver) => {
    setSelectedDriver(driver);
    setShowDetailModal(true);
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this driver?')) {
      try {
        await driverService.deleteDriver(id);
        loadDrivers();
      } catch (error) {
        alert('Failed to delete driver');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (selectedDriver) {
        await driverService.updateDriver(selectedDriver.id, formData);
      } else {
        await driverService.createDriver(formData);
      }
      loadDrivers();
      setShowModal(false);
    } catch (error) {
      alert(`Failed to ${selectedDriver ? 'update' : 'create'} driver`);
    }
  };

  const getAssignedBus = (driverId: string): string => {
    // Find active assignment for this driver
    const assignment = assignments.find(
      (a) => a.assigneeId === Number(driverId) && a.status === 'active'
    );

    if (!assignment) return 'Not Assigned';

    // Return the assigned bus name from assignment (backend provides this)
    return assignment.assignedToName || 'Unknown';
  };

  // Calculate stats
  const totalDrivers = drivers.length;
  const activeDrivers = drivers.filter((d) => d.status === 'active').length;
  const assignedDrivers = drivers.filter((d) => {
    const assignment = assignments.find(
      (a) => a.assigneeId === Number(d.id) && a.status === 'active'
    );
    return assignment !== undefined;
  }).length;

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900 mb-4 md:mb-0">Drivers</h1>
        <Button onClick={handleCreate}>
          <Plus size={20} className="mr-2 inline" />
          Add Driver
        </Button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-blue-100 rounded-lg">
              <UserCircle className="w-5 h-5 text-blue-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Drivers</h3>
          <p className="text-2xl font-bold text-slate-900">{totalDrivers}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-green-100 rounded-lg">
              <CheckCircle className="w-5 h-5 text-green-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Active</h3>
          <p className="text-2xl font-bold text-slate-900">{activeDrivers}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-purple-100 rounded-lg">
              <BusIcon className="w-5 h-5 text-purple-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Assigned to Buses</h3>
          <p className="text-2xl font-bold text-slate-900">{assignedDrivers}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-orange-100 rounded-lg">
              <Users className="w-5 h-5 text-orange-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Available</h3>
          <p className="text-2xl font-bold text-slate-900">{totalDrivers - assignedDrivers}</p>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 mb-6 p-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
          <input
            type="text"
            placeholder="Search by name or email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Email
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Phone
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  License Number
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Assigned Bus
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {filteredDrivers.map((driver) => (
                <tr key={driver.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="font-medium text-slate-900">
                      {driver.firstName} {driver.lastName}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{driver.email}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{driver.phone}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {driver.licenseNumber}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {getAssignedBus(driver.id)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 py-1 text-xs font-medium rounded-full ${
                        driver.status === 'active'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-slate-100 text-slate-800'
                      }`}
                    >
                      {driver.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => handleView(driver)}
                        className="p-2 hover:bg-blue-50 rounded-lg text-blue-600"
                      >
                        <Eye size={18} />
                      </button>
                      <button
                        onClick={() => handleEdit(driver)}
                        className="p-2 hover:bg-slate-100 rounded-lg text-slate-600"
                      >
                        <Edit size={18} />
                      </button>
                      <button
                        onClick={() => handleDelete(driver.id)}
                        className="p-2 hover:bg-red-50 rounded-lg text-red-600"
                      >
                        <Trash2 size={18} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <Modal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        title={selectedDriver ? 'Edit Driver' : 'Add New Driver'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="First Name"
              value={formData.firstName || ''}
              onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
              required
            />
            <Input
              label="Last Name"
              value={formData.lastName || ''}
              onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
              required
            />
          </div>
          <Input
            label="Email"
            type="email"
            value={formData.email || ''}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            required
          />
          <Input
            label="Phone"
            value={formData.phone || ''}
            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
            required
          />
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="License Number"
              value={formData.licenseNumber || ''}
              onChange={(e) => setFormData({ ...formData, licenseNumber: e.target.value })}
              required
            />
            <Input
              label="License Expiry"
              type="date"
              value={formData.licenseExpiry || ''}
              onChange={(e) => setFormData({ ...formData, licenseExpiry: e.target.value })}
              required
            />
          </div>
          <Select
            label="Status"
            value={formData.status || ''}
            onChange={(e) => setFormData({ ...formData, status: e.target.value as 'active' | 'inactive' })}
            options={[
              { value: 'active', label: 'Active' },
              { value: 'inactive', label: 'Inactive' },
            ]}
          />
          <div className="flex justify-end gap-3 pt-4">
            <Button type="button" variant="secondary" onClick={() => setShowModal(false)}>
              Cancel
            </Button>
            <Button type="submit">{selectedDriver ? 'Update' : 'Create'}</Button>
          </div>
        </form>
      </Modal>

      <Modal
        isOpen={showDetailModal}
        onClose={() => setShowDetailModal(false)}
        title="Driver Details"
      >
        {selectedDriver && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-slate-700">Name</p>
                <p className="text-base text-slate-900">
                  {selectedDriver.firstName} {selectedDriver.lastName}
                </p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Status</p>
                <p className="text-base text-slate-900">{selectedDriver.status}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Email</p>
                <p className="text-base text-slate-900">{selectedDriver.email}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Phone</p>
                <p className="text-base text-slate-900">{selectedDriver.phone}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">License Number</p>
                <p className="text-base text-slate-900">{selectedDriver.licenseNumber}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">License Expiry</p>
                <p className="text-base text-slate-900">{selectedDriver.licenseExpiry}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Assigned Bus</p>
                <p className="text-base text-slate-900">
                  {getAssignedBus(selectedDriver.id)}
                </p>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
