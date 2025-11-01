import React, { useState } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2, Users, Bus as BusIcon, AlertTriangle, CheckCircle } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import { useBuses } from '../hooks/useBuses';
import { useDrivers } from '../hooks/useDrivers';
import { useMinders } from '../hooks/useMinders';
import { useChildren } from '../hooks/useChildren';
import { assignmentService } from '../services/assignmentService';
import type { Bus, Assignment } from '../types';

export default function BusesPage() {
  const { buses, createBus, updateBus, deleteBus, assignDriver, assignMinder, assignChildren } = useBuses();
  const { drivers } = useDrivers();
  const { minders } = useMinders();
  const { children } = useChildren();
  const [assignments, setAssignments] = useState<Assignment[]>([]);

  // Load assignments
  React.useEffect(() => {
    loadAssignments();
  }, []);

  async function loadAssignments() {
    try {
      const driverAssignments = await assignmentService.loadAssignments({ assignmentType: 'driver_to_bus' });
      const minderAssignments = await assignmentService.loadAssignments({ assignmentType: 'minder_to_bus' });
      setAssignments([...driverAssignments, ...minderAssignments]);
    } catch (error) {
      console.error('Failed to load assignments:', error);
    }
  }

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedBus, setSelectedBus] = useState<Bus | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [formData, setFormData] = useState<Partial<Bus>>({});
  const [assignData, setAssignData] = useState({ driverId: '', minderId: '', childrenIds: [] as string[] });

  const filteredBuses = buses.filter((bus) => {
    const matchesSearch =
      bus.busNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      bus.licensePlate?.toLowerCase().includes(searchTerm.toLowerCase());
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
      driverId: bus.driverId?.toString() || '',
      minderId: bus.minderId?.toString() || '',
      childrenIds: bus.assignedChildrenIds || [],
    });
    setShowAssignModal(true);
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this bus?')) {
      const result = await deleteBus(id);
      if (result.success) {
        alert('Bus deleted successfully');
      } else {
        alert(result.error || 'Failed to delete bus');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedBus) {
      const result = await updateBus(selectedBus.id, formData);
      if (result.success) {
        alert('Bus updated successfully');
        setShowModal(false);
      } else {
        alert(result.error || 'Failed to update bus');
      }
    } else {
      const result = await createBus(formData);
      if (result.success) {
        alert('Bus created successfully');
        setShowModal(false);
      } else {
        alert(result.error || 'Failed to create bus');
      }
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

      alert('Assignments saved successfully');
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

  const getDriverName = (busId: string): string => {
    // Find active driver assignment for this bus
    const assignment = assignments.find(
      (a) => a.assignmentType === 'driver_to_bus' && a.assignedToId === Number(busId) && a.status === 'active'
    );
    return assignment?.assigneeName || 'Not Assigned';
  };

  const getMinderName = (busId: string): string => {
    // Find active minder assignment for this bus
    const assignment = assignments.find(
      (a) => a.assignmentType === 'minder_to_bus' && a.assignedToId === Number(busId) && a.status === 'active'
    );
    return assignment?.assigneeName || 'Not Assigned';
  };

  // Calculate stats
  const totalBuses = buses.length;
  const activeBuses = buses.filter((b) => b.status === 'active').length;
  const maintenanceBuses = buses.filter((b) => b.status === 'maintenance').length;
  const totalCapacity = buses.reduce((sum, b) => sum + (b.capacity || 0), 0);

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900 mb-4 md:mb-0">Buses</h1>
        <Button onClick={handleCreate}>
          <Plus size={20} className="mr-2 inline" />
          Add Bus
        </Button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-blue-100 rounded-lg">
              <BusIcon className="w-5 h-5 text-blue-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Buses</h3>
          <p className="text-2xl font-bold text-slate-900">{totalBuses}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-green-100 rounded-lg">
              <CheckCircle className="w-5 h-5 text-green-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Active</h3>
          <p className="text-2xl font-bold text-slate-900">{activeBuses}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-yellow-100 rounded-lg">
              <AlertTriangle className="w-5 h-5 text-yellow-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Maintenance</h3>
          <p className="text-2xl font-bold text-slate-900">{maintenanceBuses}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Users className="w-5 h-5 text-purple-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Capacity</h3>
          <p className="text-2xl font-bold text-slate-900">{totalCapacity}</p>
        </div>
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
                    {getDriverName(bus.id)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {getMinderName(bus.id)}
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

      {/* Create/Edit Modal */}
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

      {/* Assignment Modal */}
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
              Assigned Children ({assignData.childrenIds.length}/{selectedBus?.capacity || 0})
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

      {/* Detail Modal */}
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
                <p className="text-base text-slate-900">{getDriverName(selectedBus.id)}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Bus Minder</p>
                <p className="text-base text-slate-900">{getMinderName(selectedBus.id)}</p>
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
                      const child = children.find(c => c.id === childId.toString());
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
