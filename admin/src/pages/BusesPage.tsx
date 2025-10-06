import React, { useState } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2, UserPlus, Users } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import { getBuses, createBus, updateBus, deleteBus, assignDriver, assignMinder, assignChildren } from '../services/busApi';
import { getDrivers } from '../services/driverApi';
import { getBusMinders } from '../services/busMinderApi';
import { getChildren } from '../services/childApi';
import type { Bus, Driver, Minder, Child } from '../types';

export default function BusesPage() {
  const [buses, setBuses] = useState<Bus[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [minders, setMinders] = useState<Minder[]>([]);
  const [children, setChildren] = useState<Child[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedBus, setSelectedBus] = useState<Bus | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [formData, setFormData] = useState<Partial<Bus>>({});
  const [assignData, setAssignData] = useState({ driverId: '', minderId: '', childrenIds: [] as string[] });

  // Fetch all data from backend
  React.useEffect(() => {
    loadAllData();
  }, []);

  async function loadAllData() {
    try {
      const [busesRes, driversRes, mindersRes, childrenRes] = await Promise.all([
        getBuses(),
        getDrivers(),
        getBusMinders(),
        getChildren()
      ]);
      setBuses(busesRes.data);
      setDrivers(driversRes.data);
      setMinders(mindersRes.data);
      setChildren(childrenRes.data);
    } catch (error) {
      console.error('Failed to load data:', error);
    }
  }

  const filteredBuses = buses.filter((bus) => {
    const matchesSearch =
      bus.busNumber.toLowerCase().includes(searchTerm.toLowerCase()) ||
      bus.licensePlate.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesSearch;
  });

  const handleCreate = () => {
    setSelectedBus(null);
    setFormData({
      busNumber: '',
      licensePlate: '',
      capacity: 40,
      model: '',
      year: new Date().getFullYear(),
      assignedChildrenIds: [],
      status: 'active',
    });
    setShowModal(true);
  };

  const handleEdit = (bus: Bus) => {
    setSelectedBus(bus);
    setFormData(bus);
    setShowModal(true);
  };

  const handleView = (bus: Bus) => {
    setSelectedBus(bus);
    setShowDetailModal(true);
  };

  const handleAssign = (bus: Bus) => {
    setSelectedBus(bus);
    setAssignData({
      driverId: bus.driverId || '',
      minderId: bus.minderId || '',
      childrenIds: bus.assignedChildrenIds,
    });
    setShowAssignModal(true);
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this bus?')) {
      try {
        await deleteBus(id);
        loadAllData();
      } catch (error) {
        alert('Failed to delete bus');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (selectedBus) {
        // Update existing bus
        const response = await updateBus(selectedBus.id, formData);
        if (response.status === 200 || response.status === 201) {
          alert('Bus updated successfully');
          loadBuses();
          setShowModal(false);
        }
      } else {
        // Create new bus
        const response = await createBus(formData);
        if (response.status === 200 || response.status === 201) {
          alert('Bus created successfully');
          loadBuses();
          setShowModal(false);
        }
      }
    } catch (error) {
      alert(selectedBus ? 'Failed to update bus' : 'Failed to create bus');
    }
  };

  const handleAssignSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedBus) return;

    try {
      // Assign driver if selected
      if (assignData.driverId) {
        await assignDriver(selectedBus.id, assignData.driverId);
      }

      // Assign minder if selected
      if (assignData.minderId) {
        await assignMinder(selectedBus.id, assignData.minderId);
      }

      // Assign children if selected
      if (assignData.childrenIds.length > 0) {
        await assignChildren(selectedBus.id, assignData.childrenIds);
      }

      loadBuses();
      setShowAssignModal(false);
    } catch (error) {
      alert('Failed to assign staff/children');
    }
  };

  const toggleChildAssignment = (childId: string) => {
    setAssignData((prev) => ({
      ...prev,
      childrenIds: prev.childrenIds.includes(childId)
        ? prev.childrenIds.filter((id) => id !== childId)
        : [...prev.childrenIds, childId],
    }));
  };

  const getDriverName = (driverId?: string) => {
    if (!driverId) return 'Not Assigned';
    const driver = drivers.find((d) => d.id === driverId);
    return driver ? `${driver.firstName} ${driver.lastName}` : 'Unknown';
  };

  const getMinderName = (minderId?: string) => {
    if (!minderId) return 'Not Assigned';
    const minder = minders.find((m) => m.id === minderId);
    return minder ? `${minder.firstName} ${minder.lastName}` : 'Unknown';
  };

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900 mb-4 md:mb-0">Buses</h1>
        <Button onClick={handleCreate}>
          <Plus size={20} className="mr-2 inline" />
          Add Bus
        </Button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 mb-6 p-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
          <input
            type="text"
            placeholder="Search by bus number or license plate..."
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
                  Bus Number
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  License Plate
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Driver
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Minder
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Children
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
              {filteredBuses.map((bus) => (
                <tr key={bus.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="font-medium text-slate-900">{bus.busNumber}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{bus.licensePlate}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {getDriverName(bus.driverId)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {getMinderName(bus.minderId)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {bus.assignedChildrenCount || 0}/{bus.capacity}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 py-1 text-xs font-medium rounded-full ${
                        bus.status === 'active'
                          ? 'bg-green-100 text-green-800'
                          : bus.status === 'maintenance'
                          ? 'bg-yellow-100 text-yellow-800'
                          : 'bg-slate-100 text-slate-800'
                      }`}
                    >
                      {bus.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => handleAssign(bus)}
                        className="p-2 hover:bg-green-50 rounded-lg text-green-600"
                        title="Assign Staff & Children"
                      >
                        <Users size={18} />
                      </button>
                      <button
                        onClick={() => handleView(bus)}
                        className="p-2 hover:bg-blue-50 rounded-lg text-blue-600"
                      >
                        <Eye size={18} />
                      </button>
                      <button
                        onClick={() => handleEdit(bus)}
                        className="p-2 hover:bg-slate-100 rounded-lg text-slate-600"
                      >
                        <Edit size={18} />
                      </button>
                      <button
                        onClick={() => handleDelete(bus.id)}
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
        title={selectedBus ? 'Edit Bus' : 'Add New Bus'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Bus Number"
              value={formData.busNumber || ''}
              onChange={(e) => setFormData({ ...formData, busNumber: e.target.value })}
              required
            />
            <Input
              label="License Plate"
              value={formData.licensePlate || ''}
              onChange={(e) => setFormData({ ...formData, licensePlate: e.target.value })}
              required
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Model"
              value={formData.model || ''}
              onChange={(e) => setFormData({ ...formData, model: e.target.value })}
              required
            />
            <Input
              label="Year"
              type="number"
              value={formData.year || ''}
              onChange={(e) => setFormData({ ...formData, year: parseInt(e.target.value) })}
              required
            />
          </div>
          <Input
            label="Capacity"
            type="number"
            value={formData.capacity || ''}
            onChange={(e) => setFormData({ ...formData, capacity: parseInt(e.target.value) })}
            required
          />
          <Select
            label="Status"
            value={formData.status || ''}
            onChange={(e) =>
              setFormData({ ...formData, status: e.target.value as Bus['status'] })
            }
            options={[
              { value: 'active', label: 'Active' },
              { value: 'maintenance', label: 'Maintenance' },
              { value: 'inactive', label: 'Inactive' },
            ]}
          />
          <Input
            label="Last Maintenance"
            type="date"
            value={formData.lastMaintenance || ''}
            onChange={(e) => setFormData({ ...formData, lastMaintenance: e.target.value })}
          />
          <div className="flex justify-end gap-3 pt-4">
            <Button type="button" variant="secondary" onClick={() => setShowModal(false)}>
              Cancel
            </Button>
            <Button type="submit">{selectedBus ? 'Update' : 'Create'}</Button>
          </div>
        </form>
      </Modal>

      <Modal
        isOpen={showAssignModal}
        onClose={() => setShowAssignModal(false)}
        title={`Assign Staff & Children to ${selectedBus?.busNumber}`}
        size="lg"
      >
        <form onSubmit={handleAssignSubmit} className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Driver"
              value={assignData.driverId}
              onChange={(e) => setAssignData({ ...assignData, driverId: e.target.value })}
              options={[
                { value: '', label: 'Not Assigned' },
                ...drivers.map((d) => ({
                  value: d.id,
                  label: `${d.firstName} ${d.lastName}`,
                })),
              ]}
            />
            <Select
              label="Bus Minder"
              value={assignData.minderId}
              onChange={(e) => setAssignData({ ...assignData, minderId: e.target.value })}
              options={[
                { value: '', label: 'Not Assigned' },
                ...minders.map((m) => ({
                  value: m.id,
                  label: `${m.firstName} ${m.lastName}`,
                })),
              ]}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-3">
              Assigned Children ({assignData.childrenIds.length}/{selectedBus?.capacity})
            </label>
            <div className="max-h-64 overflow-y-auto border border-slate-300 rounded-lg">
              {children.map((child) => (
                <label
                  key={child.id}
                  className="flex items-center p-3 hover:bg-slate-50 border-b border-slate-200 last:border-b-0 cursor-pointer"
                >
                  <input
                    type="checkbox"
                    checked={assignData.childrenIds.includes(child.id)}
                    onChange={() => toggleChildAssignment(child.id)}
                    className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                  />
                  <div className="ml-3">
                    <p className="text-sm font-medium text-slate-900">
                      {child.firstName} {child.lastName}
                    </p>
                    <p className="text-xs text-slate-600">
                      {child.grade} - {child.address}
                    </p>
                  </div>
                </label>
              ))}
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-4">
            <Button type="button" variant="secondary" onClick={() => setShowAssignModal(false)}>
              Cancel
            </Button>
            <Button type="submit">Save Assignments</Button>
          </div>
        </form>
      </Modal>

      <Modal isOpen={showDetailModal} onClose={() => setShowDetailModal(false)} title="Bus Details">
        {selectedBus && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-slate-700">Bus Number</p>
                <p className="text-base text-slate-900">{selectedBus.busNumber}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">License Plate</p>
                <p className="text-base text-slate-900">{selectedBus.licensePlate}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Model</p>
                <p className="text-base text-slate-900">{selectedBus.model}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Year</p>
                <p className="text-base text-slate-900">{selectedBus.year}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Capacity</p>
                <p className="text-base text-slate-900">{selectedBus.capacity}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Status</p>
                <p className="text-base text-slate-900">{selectedBus.status}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Driver</p>
                <p className="text-base text-slate-900">{getDriverName(selectedBus.driverId)}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Bus Minder</p>
                <p className="text-base text-slate-900">{getMinderName(selectedBus.minderId)}</p>
              </div>
              {selectedBus.lastMaintenance && (
                <div>
                  <p className="text-sm font-medium text-slate-700">Last Maintenance</p>
                  <p className="text-base text-slate-900">{selectedBus.lastMaintenance}</p>
                </div>
              )}
              <div className="col-span-2">
                <p className="text-sm font-medium text-slate-700 mb-2">
                  Assigned Children ({selectedBus.assignedChildrenCount || 0})
                </p>
                <div className="space-y-2">
                  {selectedBus.assignedChildrenIds && selectedBus.assignedChildrenIds.length > 0 ? (
                    selectedBus.assignedChildrenIds.map((childId) => {
                      const child = childrenService.getById(childId);
                      return child ? (
                        <div key={child.id} className="p-3 bg-slate-50 rounded-lg">
                          <p className="font-medium text-slate-900">
                            {child.firstName} {child.lastName}
                          </p>
                          <p className="text-sm text-slate-600">{child.grade}</p>
                        </div>
                      ) : null;
                    })
                  ) : (
                    <p className="text-slate-600">No children assigned</p>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
