import React, { useState, useEffect } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2, UserCircle, Bus as BusIcon, CheckCircle, Users, Phone, CreditCard } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import FormError from '../components/common/FormError';
import { useDrivers } from '../hooks/useDrivers';
import { driverService } from '../services/driverService';
import { useToast } from '../contexts/ToastContext';
import { useConfirm } from '../contexts/ConfirmContext';
import type { Driver } from '../types';

export default function DriversPage() {
  const toast = useToast();
  const confirm = useConfirm();
  const [formError, setFormError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const { drivers, loading, hasMore, totalCount, loadDrivers, loadMore: loadMoreDrivers } = useDrivers({ search: searchTerm });
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [formData, setFormData] = useState<Partial<Driver>>({});

  React.useEffect(() => { loadDrivers(); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    const timer = setTimeout(() => loadDrivers(), 400);
    return () => clearTimeout(timer);
  }, [searchTerm]); // eslint-disable-line react-hooks/exhaustive-deps

  const filteredDrivers = drivers; // search is server-side

  const handleCreate = () => {
    setSelectedDriver(null);
    setFormError(null);
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
    setFormError(null);
    setFormData(driver);
    setShowModal(true);
  };

  const handleView = (driver: Driver) => {
    setSelectedDriver(driver);
    setShowDetailModal(true);
  };

  const handleDelete = async (id: string) => {
    const confirmed = await confirm({
      title: 'Delete Driver',
      message: 'Are you sure you want to delete this driver? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      variant: 'danger',
    });

    if (confirmed) {
      const result = await driverService.deleteDriver(id);
      if (result.success) {
        toast.success('Driver deleted successfully');
        loadDrivers();
      } else {
        toast.error(result.error?.message || 'Failed to delete driver');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    let result;
    if (selectedDriver) {
      result = await driverService.updateDriver(selectedDriver.id, formData);
    } else {
      result = await driverService.createDriver(formData);
    }

    if (result.success) {
      toast.success(`Driver ${selectedDriver ? 'updated' : 'created'} successfully`);
      loadDrivers();
      setShowModal(false);
    } else {
      setFormError(result.error?.message || `Failed to ${selectedDriver ? 'update' : 'create'} driver`);
    }
  };

  // Calculate stats
  const totalDrivers = drivers.length;
  const activeDrivers = drivers.filter((d) => d.status === 'active').length;
  const assignedDrivers = drivers.filter((d) => d.assignedBusNumber).length;

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
        <div className="flex gap-3">
          <div className="relative flex-1">
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
      </div>

      {/* Drivers Table - Desktop */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden hidden md:block">
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
              {filteredDrivers.length === 0 && !loading && (
                <tr>
                  <td colSpan={7} className="px-6 py-16 text-center">
                    <p className="text-slate-500 font-medium">
                      {searchTerm ? 'No drivers match your search' : 'No drivers yet'}
                    </p>
                    {!searchTerm && (
                      <p className="text-slate-400 text-sm mt-1">Click "Add Driver" to get started</p>
                    )}
                  </td>
                </tr>
              )}
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
                    {driver.assignedBusNumber || 'Not Assigned'}
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
        <div className="p-4 border-t border-slate-200">
          <div className="flex flex-col items-center gap-3">
            <span className="text-sm text-slate-600">
              Loaded {drivers.length} of {totalCount} drivers
            </span>
            {hasMore && (
              <Button
                onClick={loadMoreDrivers}
                disabled={loading}
                variant="secondary"
                size="sm"
              >
                {loading ? 'Loading...' : 'Load More'}
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Drivers Cards - Mobile */}
      <div className="md:hidden space-y-4">
        {filteredDrivers.length === 0 && !loading && (
          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-12 text-center">
            <p className="text-slate-500 font-medium">
              {searchTerm ? 'No drivers match your search' : 'No drivers yet'}
            </p>
            {!searchTerm && (
              <p className="text-slate-400 text-sm mt-1">Click "Add Driver" to get started</p>
            )}
          </div>
        )}
        {filteredDrivers.map((driver) => (
          <div key={driver.id} className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="flex items-start justify-between mb-3">
              <div>
                <h3 className="font-semibold text-slate-900 text-lg">
                  {driver.firstName} {driver.lastName}
                </h3>
                <p className="text-sm text-slate-600">{driver.email}</p>
              </div>
              <span
                className={`px-2 py-1 text-xs font-medium rounded-full ${
                  driver.status === 'active'
                    ? 'bg-green-100 text-green-800'
                    : 'bg-slate-100 text-slate-800'
                }`}
              >
                {driver.status}
              </span>
            </div>

            <div className="space-y-2 mb-4">
              <div className="flex items-center gap-2 text-sm">
                <Phone className="w-4 h-4 text-slate-400" />
                <span className="text-slate-600">Phone:</span>
                <span className="font-medium text-slate-900">{driver.phone}</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <CreditCard className="w-4 h-4 text-slate-400" />
                <span className="text-slate-600">License:</span>
                <span className="font-medium text-slate-900">{driver.licenseNumber}</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <BusIcon className="w-4 h-4 text-slate-400" />
                <span className="text-slate-600">Bus:</span>
                <span className="font-medium text-slate-900">{driver.assignedBusNumber || 'Not Assigned'}</span>
              </div>
            </div>

            <div className="flex gap-2 pt-3 border-t border-slate-200">
              <button
                onClick={() => handleView(driver)}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
              >
                <Eye size={18} />
                <span className="text-sm font-medium">View</span>
              </button>
              <button
                onClick={() => handleEdit(driver)}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-slate-50 text-slate-600 rounded-lg hover:bg-slate-100 transition-colors"
              >
                <Edit size={18} />
                <span className="text-sm font-medium">Edit</span>
              </button>
              <button
                onClick={() => handleDelete(driver.id)}
                className="px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
              >
                <Trash2 size={18} />
              </button>
            </div>
          </div>
        ))}

        {/* Pagination - Mobile */}
        {filteredDrivers.length > 0 && (
          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="flex flex-col items-center gap-3">
              <span className="text-sm text-slate-600">
                Loaded {drivers.length} of {totalCount} drivers
              </span>
              {hasMore && (
                <Button
                  onClick={loadMoreDrivers}
                  disabled={loading}
                  variant="secondary"
                  size="sm"
                  className="w-full"
                >
                  {loading ? 'Loading...' : 'Load More'}
                </Button>
              )}
            </div>
          </div>
        )}
      </div>

      <Modal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        title={selectedDriver ? 'Edit Driver' : 'Add New Driver'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <FormError message={formError} onDismiss={() => setFormError(null)} />
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
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
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
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
                  {selectedDriver.assignedBusNumber || 'Not Assigned'}
                </p>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
