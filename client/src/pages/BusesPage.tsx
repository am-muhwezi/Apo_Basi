import React, { useState, useEffect } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2, Users, Bus as BusIcon, AlertTriangle, CheckCircle, UserCircle, UserCheck, MapPin } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import FormError from '../components/common/FormError';
import { useBuses } from '../hooks/useBuses';
import { useDrivers } from '../hooks/useDrivers';
import { useMinders } from '../hooks/useMinders';
import { useChildren } from '../hooks/useChildren';
import { useToast } from '../contexts/ToastContext';
import { useConfirm } from '../contexts/ConfirmContext';
import type { Bus, BusRoute } from '../types';
import { assignmentService } from '../services/assignmentService';

export default function BusesPage() {
  const toast = useToast();
  const confirm = useConfirm();
  const [formError, setFormError] = useState<string | null>(null);
  const [assignError, setAssignError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const { buses, loadBuses, createBus, updateBus, deleteBus, hasMore: busesHasMore, loadMore: loadMoreBuses, loading: busesLoading, totalCount: busesTotal } = useBuses({ search: searchTerm });

  // Lazy load drivers, minders, children only when needed
  const { drivers, loadDrivers, hasMore: driversHasMore, loadMore: loadMoreDrivers } = useDrivers();
  const { minders, loadMinders, hasMore: mindersHasMore, loadMore: loadMoreMinders } = useMinders();
  const { children, loadChildren, hasMore: childrenHasMore, loadMore: loadMoreChildren } = useChildren();

  const [dataLoaded, setDataLoaded] = useState(false);
  const [routes, setRoutes] = useState<BusRoute[]>([]);

  useEffect(() => {
    const timer = setTimeout(() => loadBuses(), searchTerm ? 400 : 0);
    return () => clearTimeout(timer);
  }, [searchTerm]); // eslint-disable-line react-hooks/exhaustive-deps
  const [selectedBus, setSelectedBus] = useState<Bus | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [formData, setFormData] = useState<Partial<Bus>>({});
  const [assignData, setAssignData] = useState({ driverId: '', minderId: '', childrenIds: [] as string[], routeId: '' });

  const filteredBuses = buses; // search is server-side

  const handleCreate = () => {
    setSelectedBus(null);
    setFormError(null);
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
    setFormError(null);
    setFormData(bus);
    setShowModal(true);
  };

  const handleView = (bus: Bus) => {
    setSelectedBus(bus);
    setShowDetailModal(true);
  };

  const handleAssign = async (bus: Bus) => {
    setSelectedBus(bus);
    setAssignError(null);
    setAssignData({
      driverId: bus.driverId?.toString() || '',
      minderId: bus.minderId?.toString() || '',
      childrenIds: bus.assignedChildrenIds?.map(String) || [],
      routeId: bus.routeId?.toString() || '',
    });

    // Load drivers, minders, children, routes only once
    if (!dataLoaded) {
      const [, , , loadedRoutes] = await Promise.all([
        loadDrivers(),
        loadMinders(),
        loadChildren(),
        assignmentService.loadRoutes().catch(() => [] as BusRoute[]),
      ]);
      setRoutes(loadedRoutes as BusRoute[]);
      setDataLoaded(true);
    }

    setShowAssignModal(true);
  };

  const handleDelete = async (id: string) => {
    const confirmed = await confirm({
      title: 'Delete Bus',
      message: 'Are you sure you want to delete this bus? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      variant: 'danger',
    });

    if (confirmed) {
      const result = await deleteBus(id);
      if (result.success) {
        toast.success('Bus deleted successfully');
      } else {
        toast.error(result.error?.message || 'Failed to delete bus');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    if (selectedBus) {
      const result = await updateBus(selectedBus.id, formData);
      if (result.success) {
        toast.success('Bus updated successfully');
        setShowModal(false);
      } else {
        setFormError(result.error?.message || 'Failed to update bus');
      }
    } else {
      const result = await createBus(formData);
      if (result.success) {
        toast.success('Bus created successfully');
        setShowModal(false);
      } else {
        setFormError(result.error?.message || 'Failed to create bus');
      }
    }
  };

  const handleAssignSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setAssignError(null);
    if (!selectedBus) return;

    // ── Conflict detection ──────────────────────────────────────────────────
    const warnings: string[] = [];

    // Normalise all IDs to strings for comparison (API returns numbers, selects hold strings)
    const selectedBusId = String(selectedBus.id);

    if (assignData.driverId) {
      const driver = drivers.find(d => String(d.id) === assignData.driverId);
      if (driver?.assignedBusId && String(driver.assignedBusId) !== selectedBusId) {
        warnings.push(
          `Driver "${driver.firstName} ${driver.lastName}" is currently assigned to bus ${driver.assignedBusNumber}. They will be reassigned to this bus.`
        );
      }
    }

    if (assignData.minderId) {
      const minder = minders.find(m => String(m.id) === assignData.minderId);
      if (minder?.assignedBusId && String(minder.assignedBusId) !== selectedBusId) {
        warnings.push(
          `Bus Assistant "${minder.firstName} ${minder.lastName}" is currently assigned to bus ${minder.assignedBusNumber}. They will be reassigned to this bus.`
        );
      }
    }

    if (assignData.routeId && selectedBus.routeId && String(selectedBus.routeId) !== assignData.routeId) {
      const newRoute = routes.find(r => String(r.id) === assignData.routeId);
      warnings.push(
        `This bus is currently on route "${selectedBus.routeName}". It will be moved to "${newRoute?.name || assignData.routeId}".`
      );
    }

    // Children being newly added who are already on a different bus
    const currentChildIds = new Set((selectedBus.assignedChildrenIds || []).map(String));
    for (const childId of assignData.childrenIds) {
      if (!currentChildIds.has(childId)) {
        const child = children.find(c => String(c.id) === childId);
        if (child?.assignedBusId && String(child.assignedBusId) !== selectedBusId) {
          warnings.push(
            `"${child.firstName} ${child.lastName}" is currently on bus ${child.assignedBusNumber}. They will be moved to this bus.`
          );
        }
      }
    }

    if (warnings.length > 0) {
      const confirmed = await confirm({
        title: 'Reassignment Conflicts Detected',
        message: warnings.join('\n\n') + '\n\nExisting assignments will be cancelled. Do you want to proceed?',
        confirmText: 'Yes, Reassign',
        cancelText: 'Cancel',
        variant: 'warning',
      });
      if (!confirmed) return;
    }
    // ────────────────────────────────────────────────────────────────────────

    const today = new Date().toISOString().split('T')[0];
    const busId = parseInt(selectedBus.id);

    try {
      // All run sequentially to avoid DB contention.
      // Each call goes through the central Assignment API — single source of truth.
      if (assignData.driverId) {
        await assignmentService.createAssignment({
          assignmentType: 'driver_to_bus',
          assigneeId: parseInt(assignData.driverId),
          assignedToId: busId,
          effectiveDate: today,
          status: 'active',
        });
      }

      if (assignData.minderId) {
        await assignmentService.createAssignment({
          assignmentType: 'minder_to_bus',
          assigneeId: parseInt(assignData.minderId),
          assignedToId: busId,
          effectiveDate: today,
          status: 'active',
        });
      }

      if (assignData.childrenIds.length > 0) {
        await assignmentService.bulkAssignChildrenToBus(
          busId,
          assignData.childrenIds.map(Number),
        );
      }

      if (assignData.routeId) {
        await assignmentService.createAssignment({
          assignmentType: 'bus_to_route',
          assigneeId: busId,
          assignedToId: parseInt(assignData.routeId),
          effectiveDate: today,
          status: 'active',
        });
      }

      // Reload buses so all updated assignment fields (driverName, routeName, etc.) refresh
      await loadBuses();
      toast.success('Assignments saved successfully');
      setShowAssignModal(false);
    } catch (err: any) {
      const errData = err?.response?.data;
      let msg = errData?.message || errData?.detail || err?.message || 'Failed to save assignments';
      // DRF validation errors arrive as { field: ["msg", ...], ... }
      if (!errData?.message && !errData?.detail && errData && typeof errData === 'object') {
        const firstField = Object.values(errData)[0];
        if (Array.isArray(firstField) && firstField.length > 0) {
          msg = String(firstField[0]);
        } else if (typeof firstField === 'string') {
          msg = firstField;
        }
      }
      setAssignError(msg);
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


  // Calculate stats
  const totalBuses = buses.length;
  const activeBuses = buses.filter((b) => b.status === 'active').length;
  const maintenanceBuses = buses.filter((b) => b.status === 'maintenance').length;
  const totalCapacity = buses.reduce((sum, b) => sum + (b.capacity || 0), 0);

  if (busesLoading && buses.length === 0) {
    return (
      <div>
        <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
          <div className="h-8 w-24 bg-slate-200 rounded animate-pulse mb-4 md:mb-0" />
          <div className="h-10 w-28 bg-slate-200 rounded-lg animate-pulse" />
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
              <div className="h-9 w-9 bg-slate-200 rounded-lg animate-pulse mb-3" />
              <div className="h-4 w-24 bg-slate-200 rounded animate-pulse mb-2" />
              <div className="h-7 w-12 bg-slate-200 rounded animate-pulse" />
            </div>
          ))}
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-4 border-b border-slate-200">
            <div className="h-10 bg-slate-100 rounded-lg animate-pulse" />
          </div>
          <div className="divide-y divide-slate-200">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="px-6 py-4 flex gap-4">
                <div className="h-4 w-20 bg-slate-200 rounded animate-pulse" />
                <div className="h-4 w-28 bg-slate-200 rounded animate-pulse" />
                <div className="h-4 w-24 bg-slate-200 rounded animate-pulse" />
                <div className="h-4 w-24 bg-slate-200 rounded animate-pulse" />
                <div className="h-4 w-12 bg-slate-200 rounded animate-pulse ml-auto" />
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

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
        <div className="flex gap-2">
          <div className="relative flex-1">
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
      </div>

      {/* Buses Table - Desktop */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden hidden md:block">
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
                  Bus Assistant
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Route
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
              {filteredBuses.length === 0 && !busesLoading && (
                <tr>
                  <td colSpan={8} className="px-6 py-16 text-center">
                    <p className="text-slate-500 font-medium">
                      {searchTerm ? 'No buses match your search' : 'No buses yet'}
                    </p>
                    {!searchTerm && (
                      <p className="text-slate-400 text-sm mt-1">Click "Add Bus" to get started</p>
                    )}
                  </td>
                </tr>
              )}
              {filteredBuses.map((bus) => (
                <tr key={bus.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="font-medium text-slate-900">{bus.busNumber}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{bus.licensePlate}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {bus.driverName || 'Not Assigned'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {bus.minderName || 'Not Assigned'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {bus.routeName || <span className="text-slate-400 italic text-xs">No route</span>}
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
        <div className="p-4 border-t border-slate-200">
          <div className="flex flex-col items-center gap-3">
            <span className="text-sm text-slate-600">
              Loaded {buses.length} of {busesTotal} buses
            </span>
            {busesHasMore && (
              <Button
                onClick={loadMoreBuses}
                disabled={busesLoading}
                variant="secondary"
                size="sm"
              >
                {busesLoading ? 'Loading...' : 'Load More'}
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Buses Cards - Mobile */}
      <div className="md:hidden space-y-4">
        {filteredBuses.length === 0 && !busesLoading && (
          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-12 text-center">
            <p className="text-slate-500 font-medium">
              {searchTerm ? 'No buses match your search' : 'No buses yet'}
            </p>
            {!searchTerm && (
              <p className="text-slate-400 text-sm mt-1">Click "Add Bus" to get started</p>
            )}
          </div>
        )}
        {filteredBuses.map((bus) => (
          <div key={bus.id} className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="flex items-start justify-between mb-3">
              <div>
                <h3 className="font-semibold text-slate-900 text-lg">{bus.busNumber}</h3>
                <p className="text-sm text-slate-600">{bus.licensePlate}</p>
              </div>
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
            </div>

            <div className="space-y-2 mb-4">
              <div className="flex items-center gap-2 text-sm">
                <UserCircle className="w-4 h-4 text-slate-400" />
                <span className="text-slate-600">Driver:</span>
                <span className="font-medium text-slate-900">{bus.driverName || 'Not Assigned'}</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <UserCheck className="w-4 h-4 text-slate-400" />
                <span className="text-slate-600">Bus Assistant:</span>
                <span className="font-medium text-slate-900">{bus.minderName || 'Not Assigned'}</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <MapPin className="w-4 h-4 text-slate-400" />
                <span className="text-slate-600">Route:</span>
                <span className="font-medium text-slate-900">{bus.routeName || <span className="text-slate-400 italic">No route</span>}</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <Users className="w-4 h-4 text-slate-400" />
                <span className="text-slate-600">Capacity:</span>
                <span className="font-medium text-slate-900">{bus.assignedChildrenCount || 0}/{bus.capacity}</span>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2 pt-3 border-t border-slate-200">
              <button
                onClick={() => handleAssign(bus)}
                className="flex items-center justify-center gap-2 px-3 py-2 bg-green-50 text-green-600 rounded-lg hover:bg-green-100 transition-colors"
              >
                <Users size={16} />
                <span className="text-sm font-medium">Assign</span>
              </button>
              <button
                onClick={() => handleView(bus)}
                className="flex items-center justify-center gap-2 px-3 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
              >
                <Eye size={16} />
                <span className="text-sm font-medium">View</span>
              </button>
              <button
                onClick={() => handleEdit(bus)}
                className="flex items-center justify-center gap-2 px-3 py-2 bg-slate-50 text-slate-600 rounded-lg hover:bg-slate-100 transition-colors"
              >
                <Edit size={16} />
                <span className="text-sm font-medium">Edit</span>
              </button>
              <button
                onClick={() => handleDelete(bus.id)}
                className="flex items-center justify-center gap-2 px-3 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
              >
                <Trash2 size={16} />
                <span className="text-sm font-medium">Delete</span>
              </button>
            </div>
          </div>
        ))}

        {/* Pagination - Mobile */}
        {filteredBuses.length > 0 && (
          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="flex flex-col items-center gap-3">
              <span className="text-sm text-slate-600">
                Loaded {buses.length} of {busesTotal} buses
              </span>
              {busesHasMore && (
                <Button
                  onClick={loadMoreBuses}
                  disabled={busesLoading}
                  variant="secondary"
                  size="sm"
                  className="w-full"
                >
                  {busesLoading ? 'Loading...' : 'Load More'}
                </Button>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Create/Edit Modal */}
      <Modal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        title={selectedBus ? 'Edit Bus' : 'Add New Bus'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <FormError message={formError} onDismiss={() => setFormError(null)} />
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
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
          <FormError message={assignError} onDismiss={() => setAssignError(null)} />
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
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
              label="Bus Assistant"
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

          <Select
            label="Route"
            value={assignData.routeId}
            onChange={(e) => setAssignData({ ...assignData, routeId: e.target.value })}
            options={[
              { value: '', label: 'No route assigned' },
              ...routes.map((r) => ({
                value: r.id,
                label: r.name,
              })),
            ]}
          />

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
                      {child.grade} - {child.school}
                    </p>
                  </div>
                </label>
              ))}
              {childrenHasMore && (
                <div className="p-2 text-center border-t border-slate-200">
                  <button
                    type="button"
                    onClick={loadMoreChildren}
                    className="text-sm text-blue-600 hover:text-blue-700"
                  >
                    Load More Children
                  </button>
                </div>
              )}
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
                <p className="text-base text-slate-900">{selectedBus.driverName || 'Not Assigned'}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Bus Assistant</p>
                <p className="text-base text-slate-900">{selectedBus.minderName || 'Not Assigned'}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Route</p>
                <p className="text-base text-slate-900">{selectedBus.routeName || 'No route assigned'}</p>
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
