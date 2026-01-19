import React, { useState, useEffect } from 'react';
import {
  Plus,
  Search,
  Eye,
  Edit,
  Trash2,
  X,
  Calendar,
  MapPin,
  Users,
  Bus as BusIcon,
  UserCheck,
  RefreshCw,
  FileText,
  TrendingUp,
  AlertCircle,
} from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import SearchableSelect from '../components/common/SearchableSelect';
import { useToast } from '../contexts/ToastContext';
import { useConfirm } from '../contexts/ConfirmContext';
import { exportService } from '../services/exportService';
import { useBuses } from '../hooks/useBuses';
import { useDrivers } from '../hooks/useDrivers';
import { useMinders } from '../hooks/useMinders';
import { useChildren } from '../hooks/useChildren';
import { assignmentService } from '../services/assignmentService';
import type {
  Assignment,
  BusRoute,
  AssignmentFormData,
  RouteFormData,
  AssignmentType,
  Bus,
  Driver,
  Minder,
  Child,
} from '../types';

type TabType = 'assignments' | 'routes';

export default function AssignmentsPage() {
  const toast = useToast();
  const confirm = useConfirm();
  
  // Use hooks for data (loaded lazily when needed)
  const { buses, loadBuses } = useBuses();
  const { drivers, loadDrivers } = useDrivers();
  const { minders, loadMinders } = useMinders();
  const { children, loadChildren } = useChildren();

  // Track if resources have been loaded (for lazy loading)
  const [resourcesLoaded, setResourcesLoaded] = useState(false);

  // Load resources only when opening create/edit modal
  const loadResourcesForModal = async () => {
    if (!resourcesLoaded) {
      await Promise.all([
        loadBuses(),
        loadDrivers(),
        loadMinders(),
        loadChildren(),
      ]);
      setResourcesLoaded(true);
    }
  };

  // Tab state
  const [activeTab, setActiveTab] = useState<TabType>('assignments');

  // Assignments state
  const [assignments, setAssignments] = useState<Assignment[]>([]);
  const [filteredAssignments, setFilteredAssignments] = useState<Assignment[]>([]);
  const [assignmentSearchTerm, setAssignmentSearchTerm] = useState('');
  const [assignmentTypeFilter, setAssignmentTypeFilter] = useState<string>('all');
  const [assignmentStatusFilter, setAssignmentStatusFilter] = useState<string>('all');

  // Routes state
  const [routes, setRoutes] = useState<BusRoute[]>([]);
  const [filteredRoutes, setFilteredRoutes] = useState<BusRoute[]>([]);
  const [routeSearchTerm, setRouteSearchTerm] = useState('');

  // Modal states
  const [showAssignmentModal, setShowAssignmentModal] = useState(false);
  const [showRouteModal, setShowRouteModal] = useState(false);
  const [showBulkAssignModal, setShowBulkAssignModal] = useState(false);
  const [showUtilizationModal, setShowUtilizationModal] = useState(false);
  const [showViewDetailsModal, setShowViewDetailsModal] = useState(false);
  const [viewingAssignment, setViewingAssignment] = useState<Assignment | null>(null);

  // Form states
  const [currentAssignment, setCurrentAssignment] = useState<Assignment | null>(null);
  const [currentRoute, setCurrentRoute] = useState<BusRoute | null>(null);
  const [isEditMode, setIsEditMode] = useState(false);

  // Form data
  const [assignmentFormData, setAssignmentFormData] = useState<AssignmentFormData>({
    assignmentType: 'child_to_bus',
    assigneeId: 0,
    assignedToId: 0,
    effectiveDate: new Date().toISOString().split('T')[0],
    status: 'active',
  });

  const [routeFormData, setRouteFormData] = useState<RouteFormData>({
    name: '',
    routeCode: '',
    description: '',
    isActive: true,
  });

  // Bulk assign state
  const [bulkAssignData, setBulkAssignData] = useState({
    busId: '',
    childrenIds: [] as number[],
  });

  // Supporting data (buses, drivers, minders, children come from hooks)
  const [busUtilization, setBusUtilization] = useState<any[]>([]);

  // Loading state
  const [isLoading, setIsLoading] = useState(false);
  const [hasMoreAssignments, setHasMoreAssignments] = useState(false);

  // Load data on mount
  useEffect(() => {
    loadAllData();
  }, []);

  // Filter assignments when search or filters change
  useEffect(() => {
    filterAssignments();
  }, [assignments, assignmentSearchTerm, assignmentTypeFilter, assignmentStatusFilter]);

  // Filter routes when search changes
  useEffect(() => {
    filterRoutes();
  }, [routes, routeSearchTerm]);

  async function loadAllData() {
    setIsLoading(true);
    try {
      await Promise.all([
        loadAssignments(),
        loadRoutes(),
      ]);
    } catch (error) {
    } finally {
      setIsLoading(false);
    }
  }

  async function loadAssignments(append = false) {
    try {
      const offset = append ? assignments.length : 0;
      const data = await assignmentService.loadAssignments({ limit: 20, offset });
      
      // Use functional update to ensure we work with latest state
      setAssignments(prevAssignments => {
        if (append) {
          // Filter out any duplicates by ID before appending
          const existingIds = new Set(prevAssignments.map(a => a.id));
          const newAssignments = data.filter(a => !existingIds.has(a.id));
          return [...prevAssignments, ...newAssignments];
        }
        return data;
      });
      
      // Only show "Load More" if we got a full page (20 items)
      // If we got less than 20, we've reached the end
      setHasMoreAssignments(data.length === 20);
    } catch (error) {
    }
  }

  function loadMoreAssignments() {
    if (!isLoading && hasMoreAssignments) {
      loadAssignments(true);
    }
  }

  async function loadRoutes() {
    try {
      const data = await assignmentService.loadRoutes();
      setRoutes(Array.isArray(data) ? data : []);
    } catch (error) {
      setRoutes([]);
    }
  }

  // buses, drivers, minders, children are loaded via hooks

  async function loadBusUtilization() {
    try {
      const data = await assignmentService.getBusUtilization();
      setBusUtilization(data);
      setShowUtilizationModal(true);
    } catch (error) {
    }
  }

  function filterAssignments() {
    let filtered = [...assignments];

    // Filter by search term
    if (assignmentSearchTerm) {
      filtered = filtered.filter(
        (assignment) =>
          assignment.assigneeName?.toLowerCase().includes(assignmentSearchTerm.toLowerCase()) ||
          assignment.assignedToName?.toLowerCase().includes(assignmentSearchTerm.toLowerCase())
      );
    }

    // Filter by type
    if (assignmentTypeFilter !== 'all') {
      filtered = filtered.filter((assignment) => assignment.assignmentType === assignmentTypeFilter);
    }

    // Filter by status
    if (assignmentStatusFilter !== 'all') {
      filtered = filtered.filter((assignment) => assignment.status === assignmentStatusFilter);
    }

    setFilteredAssignments(filtered);
  }

  function filterRoutes() {
    let filtered = [...routes];

    if (routeSearchTerm) {
      filtered = filtered.filter(
        (route) =>
          route.name.toLowerCase().includes(routeSearchTerm.toLowerCase()) ||
          route.routeCode.toLowerCase().includes(routeSearchTerm.toLowerCase())
      );
    }

    setFilteredRoutes(filtered);
  }

  // Assignment CRUD
  async function handleCreateAssignment() {
    // Load resources needed for dropdowns
    await loadResourcesForModal();

    setCurrentAssignment(null);
    setIsEditMode(false);
    setAssignmentFormData({
      assignmentType: 'child_to_bus',
      assigneeId: 0,
      assignedToId: 0,
      effectiveDate: new Date().toISOString().split('T')[0],
      status: 'active',
    });
    setShowAssignmentModal(true);
  }

  async function handleEditAssignment(assignment: Assignment) {
    // Load resources needed for dropdowns
    await loadResourcesForModal();

    setCurrentAssignment(assignment);
    setIsEditMode(true);
    setAssignmentFormData({
      assignmentType: assignment.assignmentType,
      assigneeId: assignment.assigneeId,
      assignedToId: assignment.assignedToId,
      effectiveDate: assignment.effectiveDate,
      expiryDate: assignment.expiryDate,
      status: assignment.status,
      reason: assignment.reason,
      notes: assignment.notes,
    });
    setShowAssignmentModal(true);
  }

  async function handleDeleteAssignment(id: string) {
    const confirmed = await confirm({
      title: 'Delete Assignment',
      message: 'Are you sure you want to delete this assignment? This action cannot be undone.',
      confirmText: 'Delete',
      variant: 'danger'
    });
    
    if (confirmed) {
      try {
        await assignmentService.deleteAssignment(id);
        toast.success('Assignment deleted successfully');
        await loadAssignments();
      } catch (error) {
        toast.error('Failed to delete assignment. Please try again.');
      }
    }
  }

  async function handleCancelAssignment(id: string) {
    const confirmed = await confirm({
      title: 'Cancel Assignment',
      message: 'Are you sure you want to cancel this assignment? Please note the reason for cancellation.',
      confirmText: 'Cancel Assignment',
      variant: 'danger'
    });
    
    if (confirmed) {
      try {
        await assignmentService.cancelAssignment(id, 'Cancelled by admin');
        toast.success('Assignment cancelled successfully');
        await loadAssignments();
      } catch (error) {
        toast.error('Failed to cancel assignment. Please try again.');
      }
    }
  }

  async function handleSubmitAssignment(e: React.FormEvent) {
    e.preventDefault();

    try {
      if (isEditMode && currentAssignment) {
        await assignmentService.updateAssignment(currentAssignment.id, assignmentFormData);
        toast.success('Assignment updated successfully');
      } else {
        await assignmentService.createAssignment(assignmentFormData);
        toast.success('Assignment created successfully');
      }
      await loadAssignments();
      setShowAssignmentModal(false);
    } catch (error) {
      // If backend reported conflicting assignments, offer to cancel and reassign
      // @ts-ignore
      const conflicts = error?.response?.data?.conflicts;
      if (conflicts && conflicts.length) {
        const confirmed = await confirm({
          title: 'Conflicting assignments detected',
          message: `The following conflicts were found:\n${conflicts.join('\n')}\n\nCancel conflicting assignments and proceed?`,
          confirmText: 'Cancel and Reassign',
          variant: 'danger'
        });

        if (confirmed) {
          try {
            await assignmentService.createAssignment({ ...assignmentFormData, auto_cancel_conflicting: true });
            toast.success('Assignment created and conflicting assignments cancelled');
            await loadAssignments();
            setShowAssignmentModal(false);
            return;
          } catch (err) {
            toast.error('Failed to force-create assignment after cancelling conflicts.');
            return;
          }
        }
      }

      toast.error('Failed to save assignment. Please check all fields and try again.');
    }
  }

  // Route CRUD
  async function handleCreateRoute() {
    // Load resources needed for route assignment dropdowns
    await loadResourcesForModal();

    setCurrentRoute(null);
    setIsEditMode(false);
    setRouteFormData({
      name: '',
      routeCode: '',
      description: '',
      isActive: true,
    });
    setShowRouteModal(true);
  }

  async function handleEditRoute(route: BusRoute) {
    // Load resources needed for route assignment dropdowns
    await loadResourcesForModal();

    setCurrentRoute(route);
    setIsEditMode(true);
    setRouteFormData({
      name: route.name,
      routeCode: route.routeCode,
      description: route.description || '',
      defaultBusId: route.defaultBusId,
      defaultDriverId: route.defaultDriverId,
      defaultMinderId: route.defaultMinderId,
      estimatedDuration: route.estimatedDuration,
      totalDistance: route.totalDistance,
      isActive: route.isActive,
    });
    setShowRouteModal(true);
  }

  async function handleDeleteRoute(id: string) {
    const confirmed = await confirm({
      title: 'Delete Route',
      message: 'Are you sure you want to delete this route? This action cannot be undone.',
      confirmText: 'Delete',
      variant: 'danger'
    });
    
    if (confirmed) {
      try {
        await assignmentService.deleteRoute(id);
        toast.success('Route deleted successfully');
        await loadRoutes();
      } catch (error) {
        toast.error('Failed to delete route. Please try again.');
      }
    }
  }

  async function handleSubmitRoute(e: React.FormEvent) {
    e.preventDefault();

    try {
      if (isEditMode && currentRoute) {
        await assignmentService.updateRoute(currentRoute.id, routeFormData);
        toast.success('Route updated successfully');
      } else {
        await assignmentService.createRoute(routeFormData);
        toast.success('Route created successfully');
      }
      await loadRoutes();
      setShowRouteModal(false);
    } catch (error) {
      toast.error('Failed to save route. Please check all fields and try again.');
    }
  }

  // Bulk assign
  async function handleBulkAssign(e: React.FormEvent) {
    e.preventDefault();

    try {
      await assignmentService.bulkAssignChildrenToBus(
        Number(bulkAssignData.busId),
        bulkAssignData.childrenIds
      );
      toast.success(`${bulkAssignData.childrenIds.length} children assigned successfully!`);
      await loadAssignments();
      setShowBulkAssignModal(false);
      setBulkAssignData({ busId: '', childrenIds: [] });
    } catch (error) {
      // Offer to cancel and reassign when conflicts reported by backend
      // @ts-ignore
      const conflicts = error?.response?.data?.conflicts;
      if (conflicts && conflicts.length) {
        const confirmed = await confirm({
          title: 'Conflicting assignments detected',
          message: `Conflicts:\n${conflicts.join('\n')}\n\nCancel conflicting assignments and continue?`,
          confirmText: 'Cancel and Continue',
          variant: 'danger'
        });

        if (confirmed) {
          try {
            await assignmentService.bulkAssignChildrenToBus(Number(bulkAssignData.busId), bulkAssignData.childrenIds, undefined, { auto_cancel_conflicting: true });
            toast.success('Children assigned after cancelling conflicting assignments');
            await loadAssignments();
            setShowBulkAssignModal(false);
            setBulkAssignData({ busId: '', childrenIds: [] });
            return;
          } catch (err) {
            toast.error('Failed to assign children after cancelling conflicts.');
            return;
          }
        }
      }

      toast.error('Failed to assign children. Please check bus capacity and existing assignments.');
    }
  }

  // Calculate stats
  const totalAssignments = assignments.length;
  const activeAssignments = assignments.filter((a) => a.status === 'active').length;
  const expiredAssignments = assignments.filter((a) => a.status === 'expired').length;
  const childAssignments = assignments.filter((a) => a.assignmentType === 'child_to_bus').length;

  const totalRoutes = routes.length;
  const activeRoutes = routes.filter((r) => r.isActive).length;

  const assignmentTypeOptions = [
    { value: 'all', label: 'All Types' },
    { value: 'driver_to_bus', label: 'Driver to Bus' },
    { value: 'minder_to_bus', label: 'Minder to Bus' },
    { value: 'child_to_bus', label: 'Child to Bus' },
    { value: 'bus_to_route', label: 'Bus to Route' },
    { value: 'driver_to_route', label: 'Driver to Route' },
    { value: 'minder_to_route', label: 'Minder to Route' },
    { value: 'child_to_route', label: 'Child to Route' },
  ];

  const assignmentStatusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'active', label: 'Active' },
    { value: 'expired', label: 'Expired' },
    { value: 'cancelled', label: 'Cancelled' },
    { value: 'pending', label: 'Pending' },
  ];

  const getStatusBadgeClass = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'expired':
        return 'bg-gray-100 text-gray-800';
      case 'cancelled':
        return 'bg-red-100 text-red-800';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-slate-100 text-slate-800';
    }
  };

  return (
    <div className="max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:justify-between md:items-center gap-4 mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Assignments & Routes</h1>
        <div className="flex flex-wrap gap-2">
          <Button variant="secondary" size="sm" onClick={loadBusUtilization}>
            <TrendingUp size={18} />
            <span className="hidden sm:inline ml-1">Bus Utilization</span>
          </Button>
          <Button variant="secondary" size="sm" onClick={() => setShowBulkAssignModal(true)}>
            <Users size={18} />
            <span className="hidden sm:inline ml-1">Bulk Assign</span>
          </Button>
          <Button size="sm" onClick={loadAllData}>
            <RefreshCw size={18} />
            <span className="hidden sm:inline ml-1">Refresh</span>
          </Button>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 mb-6 border-b border-slate-200">
        <button
          onClick={() => setActiveTab('assignments')}
          className={`px-6 py-3 font-medium transition-colors ${
            activeTab === 'assignments'
              ? 'text-blue-600 border-b-2 border-blue-600'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          <div className="flex items-center gap-2">
            <FileText size={20} />
            Assignments
          </div>
        </button>
        <button
          onClick={() => setActiveTab('routes')}
          className={`px-6 py-3 font-medium transition-colors ${
            activeTab === 'routes'
              ? 'text-blue-600 border-b-2 border-blue-600'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          <div className="flex items-center gap-2">
            <MapPin size={20} />
            Routes
          </div>
        </button>
      </div>

      {/* ASSIGNMENTS TAB */}
      {activeTab === 'assignments' && (
        <>
          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div className="bg-white rounded-xl p-6 border border-slate-200 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-600 mb-1">Total Assignments</p>
                  <p className="text-3xl font-bold text-slate-900">{totalAssignments}</p>
                </div>
                <div className="bg-blue-100 p-3 rounded-lg">
                  <FileText className="text-blue-600" size={24} />
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl p-6 border border-slate-200 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-600 mb-1">Active</p>
                  <p className="text-3xl font-bold text-green-600">{activeAssignments}</p>
                </div>
                <div className="bg-green-100 p-3 rounded-lg">
                  <UserCheck className="text-green-600" size={24} />
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl p-6 border border-slate-200 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-600 mb-1">Child Assignments</p>
                  <p className="text-3xl font-bold text-purple-600">{childAssignments}</p>
                </div>
                <div className="bg-purple-100 p-3 rounded-lg">
                  <Users className="text-purple-600" size={24} />
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl p-6 border border-slate-200 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-600 mb-1">Expired</p>
                  <p className="text-3xl font-bold text-slate-600">{expiredAssignments}</p>
                </div>
                <div className="bg-slate-100 p-3 rounded-lg">
                  <AlertCircle className="text-slate-600" size={24} />
                </div>
              </div>
            </div>
          </div>

          {/* Search and Filters */}
          <div className="bg-white rounded-xl p-4 mb-6 border border-slate-200">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
              <div className="sm:col-span-2 lg:col-span-1">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
                  <input
                    type="text"
                    placeholder="Search..."
                    value={assignmentSearchTerm}
                    onChange={(e) => setAssignmentSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div>
                <select
                  value={assignmentTypeFilter}
                  onChange={(e) => setAssignmentTypeFilter(e.target.value)}
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  {assignmentTypeOptions.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <select
                  value={assignmentStatusFilter}
                  onChange={(e) => setAssignmentStatusFilter(e.target.value)}
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  {assignmentStatusOptions.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <Button
                  variant="secondary"
                  onClick={() => {
                    try {
                      if (filteredAssignments.length === 0) {
                        toast.error('No assignments to export');
                        return;
                      }
                      exportService.exportAssignmentsReport(filteredAssignments);
                      toast.success(`Exported ${filteredAssignments.length} assignments successfully`);
                    } catch (error) {
                      toast.error('Failed to export assignments. Please try again.');
                    }
                  }}
                  className="w-full"
                  disabled={filteredAssignments.length === 0}
                >
                  <FileText size={20} />
                  <span className="ml-1">Export</span>
                </Button>
              </div>
              <div>
                <Button onClick={handleCreateAssignment} className="w-full">
                  <Plus size={20} />
                  <span className="ml-1">New</span>
                </Button>
              </div>
            </div>
          </div>

          {/* Assignments Table - Desktop */}
          <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden hidden md:block">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-slate-50 border-b border-slate-200">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                      Type
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                      Assignee
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                      Assigned To
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                      Effective Date
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200">
                  {filteredAssignments.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center text-slate-500">
                        No assignments found
                      </td>
                    </tr>
                  ) : (
                    filteredAssignments.map((assignment) => (
                      <tr key={assignment.id} className="hover:bg-slate-50 transition-colors">
                        <td className="px-6 py-4">
                          <span className="text-sm font-medium text-slate-900">
                            {assignment.assignmentType.replace(/_/g, ' ').toUpperCase()}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-slate-900">{assignment.assigneeName || 'N/A'}</div>
                          <div className="text-xs text-slate-500 capitalize">{assignment.assigneeType}</div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-slate-900">{assignment.assignedToName || 'N/A'}</div>
                          <div className="text-xs text-slate-500 capitalize">{assignment.assignedToType}</div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-slate-900">{assignment.effectiveDate}</div>
                          {assignment.expiryDate && (
                            <div className="text-xs text-slate-500">Until: {assignment.expiryDate}</div>
                          )}
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusBadgeClass(
                              assignment.status
                            )}`}
                          >
                            {assignment.status.toUpperCase()}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex gap-2">
                            <button
                              onClick={() => {
                                setViewingAssignment(assignment);
                                setShowViewDetailsModal(true);
                              }}
                              className="text-slate-600 hover:text-slate-800 transition-colors"
                              title="View Details"
                            >
                              <Eye size={18} />
                            </button>
                            <button
                              onClick={() => handleEditAssignment(assignment)}
                              className="text-blue-600 hover:text-blue-800 transition-colors"
                              title="Edit"
                            >
                              <Edit size={18} />
                            </button>
                            {assignment.status === 'active' && (
                              <button
                                onClick={() => handleCancelAssignment(assignment.id)}
                                className="text-orange-600 hover:text-orange-800 transition-colors"
                                title="Cancel"
                              >
                                <X size={18} />
                              </button>
                            )}
                            <button
                              onClick={() => handleDeleteAssignment(assignment.id)}
                              className="text-red-600 hover:text-red-800 transition-colors"
                              title="Delete"
                            >
                              <Trash2 size={18} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
            <div className="p-4 border-t border-slate-200">
              <div className="flex flex-col items-center gap-3">
                <span className="text-sm text-slate-600">
                  Loaded {filteredAssignments.length} of {filteredAssignments.length}{hasMoreAssignments ? '+' : ''} assignments
                </span>
                {hasMoreAssignments && (
                  <Button
                    onClick={loadMoreAssignments}
                    disabled={isLoading}
                    variant="secondary"
                    size="sm"
                  >
                    {isLoading ? 'Loading...' : 'Load More'}
                  </Button>
                )}
              </div>
            </div>
          </div>

          {/* Assignments Cards - Mobile */}
          <div className="md:hidden space-y-4">
            {filteredAssignments.length === 0 ? (
              <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-8 text-center">
                <FileText className="w-12 h-12 text-slate-400 mx-auto mb-2" />
                <p className="text-slate-600">No assignments found</p>
              </div>
            ) : (
              filteredAssignments.map((assignment) => (
                <div key={assignment.id} className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <h3 className="font-semibold text-slate-900 text-sm mb-1">
                        {assignment.assignmentType.replace(/_/g, ' ').toUpperCase()}
                      </h3>
                      <p className="text-xs text-slate-600">{assignment.effectiveDate}</p>
                    </div>
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusBadgeClass(
                        assignment.status
                      )}`}
                    >
                      {assignment.status.toUpperCase()}
                    </span>
                  </div>

                  <div className="space-y-2 mb-4">
                    <div className="bg-slate-50 p-3 rounded-lg">
                      <p className="text-xs text-slate-500 mb-1">Assignee</p>
                      <p className="font-medium text-slate-900 text-sm">{assignment.assigneeName || 'N/A'}</p>
                      <p className="text-xs text-slate-600 capitalize">{assignment.assigneeType}</p>
                    </div>
                    <div className="bg-slate-50 p-3 rounded-lg">
                      <p className="text-xs text-slate-500 mb-1">Assigned To</p>
                      <p className="font-medium text-slate-900 text-sm">{assignment.assignedToName || 'N/A'}</p>
                      <p className="text-xs text-slate-600 capitalize">{assignment.assignedToType}</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-2 pt-3 border-t border-slate-200">
                    <button
                      onClick={() => {
                        setViewingAssignment(assignment);
                        setShowViewDetailsModal(true);
                      }}
                      className="flex items-center justify-center gap-2 px-3 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
                    >
                      <Eye size={16} />
                      <span className="text-sm font-medium">View</span>
                    </button>
                    <button
                      onClick={() => handleEditAssignment(assignment)}
                      className="flex items-center justify-center gap-2 px-3 py-2 bg-slate-50 text-slate-600 rounded-lg hover:bg-slate-100 transition-colors"
                    >
                      <Edit size={16} />
                      <span className="text-sm font-medium">Edit</span>
                    </button>
                    {assignment.status === 'active' && (
                      <button
                        onClick={() => handleCancelAssignment(assignment.id)}
                        className="flex items-center justify-center gap-2 px-3 py-2 bg-orange-50 text-orange-600 rounded-lg hover:bg-orange-100 transition-colors"
                      >
                        <X size={16} />
                        <span className="text-sm font-medium">Cancel</span>
                      </button>
                    )}
                    <button
                      onClick={() => handleDeleteAssignment(assignment.id)}
                      className="flex items-center justify-center gap-2 px-3 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
                    >
                      <Trash2 size={16} />
                      <span className="text-sm font-medium">Delete</span>
                    </button>
                  </div>
                </div>
              ))
            )}

            {/* Pagination - Mobile */}
            {filteredAssignments.length > 0 && (
              <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
                <div className="flex flex-col items-center gap-3">
                  <span className="text-sm text-slate-600">
                    Loaded {filteredAssignments.length} of {filteredAssignments.length}{hasMoreAssignments ? '+' : ''} assignments
                  </span>
                  {hasMoreAssignments && (
                    <Button
                      onClick={loadMoreAssignments}
                      disabled={isLoading}
                      variant="secondary"
                      size="sm"
                      className="w-full"
                    >
                      {isLoading ? 'Loading...' : 'Load More'}
                    </Button>
                  )}
                </div>
              </div>
            )}
          </div>
        </>
      )}

      {/* ROUTES TAB */}
      {activeTab === 'routes' && (
        <>
          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="bg-white rounded-xl p-6 border border-slate-200 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-600 mb-1">Total Routes</p>
                  <p className="text-3xl font-bold text-slate-900">{totalRoutes}</p>
                </div>
                <div className="bg-blue-100 p-3 rounded-lg">
                  <MapPin className="text-blue-600" size={24} />
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl p-6 border border-slate-200 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-600 mb-1">Active Routes</p>
                  <p className="text-3xl font-bold text-green-600">{activeRoutes}</p>
                </div>
                <div className="bg-green-100 p-3 rounded-lg">
                  <UserCheck className="text-green-600" size={24} />
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl p-6 border border-slate-200 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-600 mb-1">Inactive Routes</p>
                  <p className="text-3xl font-bold text-slate-600">{totalRoutes - activeRoutes}</p>
                </div>
                <div className="bg-slate-100 p-3 rounded-lg">
                  <AlertCircle className="text-slate-600" size={24} />
                </div>
              </div>
            </div>
          </div>

          {/* Search */}
          <div className="bg-white rounded-xl p-4 mb-6 border border-slate-200">
            <div className="flex gap-4">
              <div className="flex-1">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
                  <input
                    type="text"
                    placeholder="Search routes..."
                    value={routeSearchTerm}
                    onChange={(e) => setRouteSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <Button onClick={handleCreateRoute}>
                <Plus size={20} />
                New Route
              </Button>
            </div>
          </div>

          {/* Routes Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredRoutes.length === 0 ? (
              <div className="col-span-full text-center py-12 text-slate-500">No routes found</div>
            ) : (
              filteredRoutes.map((route) => (
                <div
                  key={route.id}
                  className="bg-white rounded-xl border border-slate-200 shadow-sm hover:shadow-md transition-shadow overflow-hidden"
                >
                  <div className="p-6">
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex items-center gap-3">
                        <div className="bg-blue-100 p-3 rounded-lg">
                          <MapPin className="text-blue-600" size={24} />
                        </div>
                        <div>
                          <h3 className="font-semibold text-slate-900">{route.name}</h3>
                          <p className="text-sm text-slate-600">{route.routeCode}</p>
                        </div>
                      </div>
                      <span
                        className={`px-3 py-1 rounded-full text-xs font-medium ${
                          route.isActive ? 'bg-green-100 text-green-800' : 'bg-slate-100 text-slate-800'
                        }`}
                      >
                        {route.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </div>

                    {route.description && (
                      <p className="text-sm text-slate-600 mb-4">{route.description}</p>
                    )}

                    <div className="space-y-2 mb-4">
                      {route.defaultBusNumber && (
                        <div className="flex items-center gap-2 text-sm">
                          <BusIcon size={16} className="text-slate-400" />
                          <span className="text-slate-600">Bus: {route.defaultBusNumber}</span>
                        </div>
                      )}
                      {route.defaultDriverName && (
                        <div className="flex items-center gap-2 text-sm">
                          <UserCheck size={16} className="text-slate-400" />
                          <span className="text-slate-600">Driver: {route.defaultDriverName}</span>
                        </div>
                      )}
                      {route.estimatedDuration && (
                        <div className="flex items-center gap-2 text-sm">
                          <Calendar size={16} className="text-slate-400" />
                          <span className="text-slate-600">{route.estimatedDuration} min</span>
                        </div>
                      )}
                    </div>

                    <div className="flex gap-2 pt-4 border-t border-slate-200">
                      <button
                        onClick={() => handleEditRoute(route)}
                        className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
                      >
                        <Edit size={16} />
                        Edit
                      </button>
                      <button
                        onClick={() => handleDeleteRoute(route.id)}
                        className="flex items-center justify-center gap-2 px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </>
      )}

      {/* Assignment Modal - Simplified */}
      <Modal
        isOpen={showAssignmentModal}
        onClose={() => setShowAssignmentModal(false)}
        title={isEditMode ? 'Edit Assignment' : 'Create New Assignment'}
        size="lg"
      >
        <form onSubmit={handleSubmitAssignment} className="space-y-4">
          {/* Assignment Type */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Assignment Type</label>
            <select
              value={assignmentFormData.assignmentType}
              onChange={(e) =>
                setAssignmentFormData({ ...assignmentFormData, assignmentType: e.target.value as AssignmentType })
              }
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            >
              <option value="child_to_bus">Child to Bus</option>
              <option value="driver_to_bus">Driver to Bus</option>
              <option value="minder_to_bus">Bus Minder to Bus</option>
              <option value="bus_to_route">Bus to Route</option>
              <option value="driver_to_route">Driver to Route</option>
              <option value="minder_to_route">Bus Minder to Route</option>
              <option value="child_to_route">Child to Route</option>
            </select>
          </div>

          {/* Context-aware searchable selects based on assignment type */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Left side - Who is being assigned */}
            <div>
              {assignmentFormData.assignmentType === 'driver_to_bus' || assignmentFormData.assignmentType === 'driver_to_route' ? (
                <SearchableSelect
                  label="Select Driver"
                  placeholder="Search for a driver..."
                  options={drivers.map((d) => ({
                    id: d.id,
                    label: `${d.firstName} ${d.lastName}`,
                    sublabel: d.licenseNumber,
                  }))}
                  value={assignmentFormData.assigneeId || null}
                  onChange={(val) => setAssignmentFormData({ ...assignmentFormData, assigneeId: Number(val) })}
                  required
                />
              ) : assignmentFormData.assignmentType === 'minder_to_bus' || assignmentFormData.assignmentType === 'minder_to_route' ? (
                <SearchableSelect
                  label="Select Bus Minder"
                  placeholder="Search for a bus minder..."
                  options={minders.map((m) => ({
                    id: m.id,
                    label: `${m.firstName} ${m.lastName}`,
                    sublabel: m.phone,
                  }))}
                  value={assignmentFormData.assigneeId || null}
                  onChange={(val) => setAssignmentFormData({ ...assignmentFormData, assigneeId: Number(val) })}
                  required
                />
              ) : assignmentFormData.assignmentType === 'child_to_bus' || assignmentFormData.assignmentType === 'child_to_route' ? (
                <SearchableSelect
                  label="Select Child"
                  placeholder="Search for a child..."
                  options={children.map((c) => ({
                    id: c.id,
                    label: `${c.firstName} ${c.lastName}`,
                    sublabel: c.grade,
                  }))}
                  value={assignmentFormData.assigneeId || null}
                  onChange={(val) => setAssignmentFormData({ ...assignmentFormData, assigneeId: Number(val) })}
                  required
                />
              ) : (
                <SearchableSelect
                  label="Select Bus"
                  placeholder="Search for a bus..."
                  options={buses.map((b) => ({
                    id: b.id,
                    label: b.busNumber,
                    sublabel: b.licensePlate,
                  }))}
                  value={assignmentFormData.assigneeId || null}
                  onChange={(val) => setAssignmentFormData({ ...assignmentFormData, assigneeId: Number(val) })}
                  required
                />
              )}
            </div>

            {/* Right side - What they're assigned to */}
            <div>
              {assignmentFormData.assignmentType.includes('_to_bus') ? (
                <SearchableSelect
                  label="Assign to Bus"
                  placeholder="Search for a bus..."
                  options={buses.map((b) => ({
                    id: b.id,
                    label: b.busNumber,
                    sublabel: `Capacity: ${b.capacity}`,
                  }))}
                  value={assignmentFormData.assignedToId || null}
                  onChange={(val) => setAssignmentFormData({ ...assignmentFormData, assignedToId: Number(val) })}
                  required
                />
              ) : (
                <SearchableSelect
                  label="Assign to Route"
                  placeholder="Search for a route..."
                  options={routes.map((r) => ({
                    id: r.id,
                    label: r.name,
                    sublabel: r.routeCode,
                  }))}
                  value={assignmentFormData.assignedToId || null}
                  onChange={(val) => setAssignmentFormData({ ...assignmentFormData, assignedToId: Number(val) })}
                  required
                />
              )}
            </div>
          </div>

          {/* Dates */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Effective Date</label>
              <input
                type="date"
                value={assignmentFormData.effectiveDate}
                onChange={(e) => setAssignmentFormData({ ...assignmentFormData, effectiveDate: e.target.value })}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Expiry Date (Optional)</label>
              <input
                type="date"
                value={assignmentFormData.expiryDate || ''}
                onChange={(e) => setAssignmentFormData({ ...assignmentFormData, expiryDate: e.target.value })}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          {/* Reason */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Reason (Optional)</label>
            <input
              type="text"
              value={assignmentFormData.reason || ''}
              onChange={(e) => setAssignmentFormData({ ...assignmentFormData, reason: e.target.value })}
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Why is this assignment being made..."
            />
          </div>

          <div className="flex gap-3 pt-4">
            <Button type="submit" className="flex-1">
              {isEditMode ? 'Update Assignment' : 'Create Assignment'}
            </Button>
            <Button type="button" variant="secondary" onClick={() => setShowAssignmentModal(false)}>
              Cancel
            </Button>
          </div>
        </form>
      </Modal>

      {/* Route Modal */}
      <Modal
        isOpen={showRouteModal}
        onClose={() => setShowRouteModal(false)}
        title={isEditMode ? 'Edit Route' : 'Create New Route'}
        size="lg"
      >
        <form onSubmit={handleSubmitRoute} className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Route Name</label>
              <input
                type="text"
                value={routeFormData.name}
                onChange={(e) => setRouteFormData({ ...routeFormData, name: e.target.value })}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="e.g., Route A - Downtown"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Route Code</label>
              <input
                type="text"
                value={routeFormData.routeCode}
                onChange={(e) => setRouteFormData({ ...routeFormData, routeCode: e.target.value })}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="e.g., ROUTE_A"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Description</label>
            <textarea
              value={routeFormData.description}
              onChange={(e) => setRouteFormData({ ...routeFormData, description: e.target.value })}
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              rows={3}
              placeholder="Route description..."
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Default Bus</label>
              <select
                value={routeFormData.defaultBusId || ''}
                onChange={(e) => setRouteFormData({ ...routeFormData, defaultBusId: e.target.value })}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">None</option>
                {buses.map((bus) => (
                  <option key={bus.id} value={bus.id}>
                    {bus.busNumber}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Default Driver</label>
              <select
                value={routeFormData.defaultDriverId || ''}
                onChange={(e) => setRouteFormData({ ...routeFormData, defaultDriverId: e.target.value })}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">None</option>
                {drivers.map((driver) => (
                  <option key={driver.id} value={driver.id}>
                    {driver.firstName} {driver.lastName}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Default Minder</label>
              <select
                value={routeFormData.defaultMinderId || ''}
                onChange={(e) => setRouteFormData({ ...routeFormData, defaultMinderId: e.target.value })}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">None</option>
                {minders.map((minder) => (
                  <option key={minder.id} value={minder.id}>
                    {minder.firstName} {minder.lastName}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Duration (minutes)</label>
              <input
                type="number"
                value={routeFormData.estimatedDuration || ''}
                onChange={(e) =>
                  setRouteFormData({ ...routeFormData, estimatedDuration: Number(e.target.value) })
                }
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="45"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Distance (km)</label>
              <input
                type="number"
                step="0.1"
                value={routeFormData.totalDistance || ''}
                onChange={(e) =>
                  setRouteFormData({ ...routeFormData, totalDistance: Number(e.target.value) })
                }
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="15.5"
              />
            </div>
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="isActive"
              checked={routeFormData.isActive}
              onChange={(e) => setRouteFormData({ ...routeFormData, isActive: e.target.checked })}
              className="w-4 h-4 text-blue-600 border-slate-300 rounded focus:ring-blue-500"
            />
            <label htmlFor="isActive" className="text-sm font-medium text-slate-700">
              Active Route
            </label>
          </div>

          <div className="flex gap-3 pt-4">
            <Button type="submit" className="flex-1">
              {isEditMode ? 'Update Route' : 'Create Route'}
            </Button>
            <Button type="button" variant="secondary" onClick={() => setShowRouteModal(false)}>
              Cancel
            </Button>
          </div>
        </form>
      </Modal>

      {/* Bulk Assign Modal */}
      <Modal
        isOpen={showBulkAssignModal}
        onClose={() => setShowBulkAssignModal(false)}
        title="Bulk Assign Children to Bus"
        size="md"
      >
        <form onSubmit={handleBulkAssign} className="space-y-4">
          <div>
            <label htmlFor="bulk-assign-bus" className="block text-sm font-medium text-slate-700 mb-2">
              Select Bus
            </label>
            <select
              id="bulk-assign-bus"
              value={bulkAssignData.busId}
              onChange={(e) => setBulkAssignData({ ...bulkAssignData, busId: e.target.value })}
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            >
              <option value="">Choose a bus...</option>
              {buses.map((bus) => (
                <option key={bus.id} value={bus.id}>
                  {bus.busNumber} - {bus.capacity} capacity
                </option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="bulk-assign-children" className="block text-sm font-medium text-slate-700 mb-2">
              Select Children (Hold Ctrl/Cmd to select multiple)
            </label>
            <select
              id="bulk-assign-children"
              multiple
              value={bulkAssignData.childrenIds.map(String)}
              onChange={(e) => {
                const selected = Array.from(e.target.selectedOptions).map((option) => Number(option.value));
                setBulkAssignData({ ...bulkAssignData, childrenIds: selected });
              }}
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              size={8}
              required
            >
              {children.map((child) => (
                <option key={child.id} value={child.id}>
                  {child.firstName} {child.lastName} - {child.grade}
                </option>
              ))}
            </select>
            <p className="text-xs text-slate-500 mt-2">
              {bulkAssignData.childrenIds.length} children selected
            </p>
          </div>

          <div className="flex gap-3 pt-4">
            <Button type="submit" className="flex-1">
              Assign {bulkAssignData.childrenIds.length} Children
            </Button>
            <Button type="button" variant="secondary" onClick={() => setShowBulkAssignModal(false)}>
              Cancel
            </Button>
          </div>
        </form>
      </Modal>

      {/* Bus Utilization Modal - Modern Design */}
      <Modal
        isOpen={showUtilizationModal}
        onClose={() => setShowUtilizationModal(false)}
        title="🚌 Bus Utilization Overview"
        size="xl"
      >
        {/* Header with Export Button */}
        <div className="mb-6 flex items-center justify-between">
          <p className="text-slate-600">Real-time bus capacity and assignment details</p>
          <Button
            variant="secondary"
            size="sm"
            onClick={() => {
              try {
                if (busUtilization.length === 0) {
                  toast.error('No data to export');
                  return;
                }
                exportService.exportBusUtilizationReport(busUtilization);
                toast.success('Bus utilization report exported successfully');
              } catch (error) {
                toast.error('Failed to export report. Please try again.');
              }
            }}
            className="shadow-sm hover:shadow-md transition-shadow"
          >
            <FileText size={18} />
            <span className="ml-2">Export</span>
          </Button>
        </div>

        <div className="space-y-5">
          {busUtilization.length === 0 ? (
            <div className="text-center py-16">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-100 mb-4">
                <TrendingUp className="w-8 h-8 text-slate-400" />
              </div>
              <p className="text-slate-500 text-lg">No utilization data available</p>
              <p className="text-slate-400 text-sm mt-1">Bus assignments will appear here</p>
            </div>
          ) : (
            busUtilization.map((item) => (
              <div key={item.bus_id} className="group bg-gradient-to-br from-white to-slate-50 rounded-2xl border border-slate-200 overflow-hidden shadow-sm hover:shadow-xl transition-all duration-300">
                {/* Modern Bus Header with Gradient */}
                <div className="bg-gradient-to-r from-blue-600 to-indigo-700 p-6 text-white">
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <div className="flex items-center justify-center w-14 h-14 rounded-xl bg-white/20 backdrop-blur-sm border border-white/30">
                          <Users className="w-7 h-7" />
                        </div>
                        <div>
                          <h4 className="font-bold text-2xl tracking-tight">{item.bus_number}</h4>
                          <p className="text-blue-100 text-sm flex items-center gap-1.5 mt-0.5">
                            <FileText size={14} />
                            {item.license_plate}
                          </p>
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <span
                        className={`inline-flex items-center px-4 py-2.5 rounded-xl text-sm font-bold shadow-lg backdrop-blur-sm ${
                          item.utilization_percentage >= 90
                            ? 'bg-red-500 text-white ring-2 ring-red-300'
                            : item.utilization_percentage >= 70
                            ? 'bg-amber-500 text-white ring-2 ring-amber-300'
                            : 'bg-emerald-500 text-white ring-2 ring-emerald-300'
                        }`}
                      >
                        {item.utilization_percentage}%
                      </span>
                      <p className="text-blue-100 text-xs mt-1.5 font-medium">Capacity</p>
                    </div>
                  </div>

                  {/* Capacity Stats */}
                  <div className="flex items-center gap-6 mb-4">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 rounded-full bg-white shadow-lg"></div>
                      <span className="text-sm font-semibold">
                        {item.assigned_children}/{item.capacity} Seats
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className={`w-2 h-2 rounded-full shadow-lg ${item.available_seats > 0 ? 'bg-green-300' : 'bg-red-300'}`}></div>
                      <span className="text-sm font-medium">
                        {item.available_seats} Available
                      </span>
                    </div>
                  </div>

                  {/* Modern Progress Bar with Glow */}
                  <div className="relative h-3 bg-white/20 rounded-full overflow-hidden backdrop-blur-sm shadow-inner">
                    <div
                      className={`absolute inset-y-0 left-0 rounded-full transition-all duration-700 ease-out ${
                        item.utilization_percentage >= 90
                          ? 'bg-gradient-to-r from-red-400 via-red-500 to-red-600'
                          : item.utilization_percentage >= 70
                          ? 'bg-gradient-to-r from-amber-400 via-amber-500 to-amber-600'
                          : 'bg-gradient-to-r from-emerald-400 via-emerald-500 to-emerald-600'
                      }`}
                      style={{ width: `${item.utilization_percentage}%` }}
                    >
                      <div className="absolute inset-0 bg-white/30 animate-pulse"></div>
                    </div>
                  </div>
                </div>

                {/* Bus Team Cards - Modern Grid */}
                <div className="p-6 grid grid-cols-1 md:grid-cols-3 gap-4">
                  {/* Driver Card */}
                  <div className="group/card relative bg-white p-5 rounded-xl border-2 border-slate-200 hover:border-blue-400 hover:shadow-lg transition-all duration-200">
                    <div className="absolute top-4 right-4">
                      <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-50 to-blue-100 flex items-center justify-center group-hover/card:from-blue-100 group-hover/card:to-blue-200 transition-colors shadow-sm">
                        <Users className="w-5 h-5 text-blue-600" />
                      </div>
                    </div>
                    <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-3">Driver</p>
                    {item.driver ? (
                      <div>
                        <p className="font-bold text-slate-900 mb-2 text-base">
                          {item.driver.first_name} {item.driver.last_name}
                        </p>
                        <p className="text-sm text-slate-600 flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full bg-emerald-500 shadow-sm"></span>
                          {item.driver.phone || 'No contact'}
                        </p>
                      </div>
                    ) : (
                      <p className="text-sm text-slate-400 italic font-medium">Not assigned</p>
                    )}
                  </div>

                  {/* Bus Assistant Card */}
                  <div className="group/card relative bg-white p-5 rounded-xl border-2 border-slate-200 hover:border-purple-400 hover:shadow-lg transition-all duration-200">
                    <div className="absolute top-4 right-4">
                      <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-50 to-purple-100 flex items-center justify-center group-hover/card:from-purple-100 group-hover/card:to-purple-200 transition-colors shadow-sm">
                        <Users className="w-5 h-5 text-purple-600" />
                      </div>
                    </div>
                    <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-3">Assistant</p>
                    {item.minder ? (
                      <div>
                        <p className="font-bold text-slate-900 mb-2 text-base">
                          {item.minder.first_name} {item.minder.last_name}
                        </p>
                        <p className="text-sm text-slate-600 flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full bg-emerald-500 shadow-sm"></span>
                          {item.minder.phone || 'No contact'}
                        </p>
                      </div>
                    ) : (
                      <p className="text-sm text-slate-400 italic font-medium">Not assigned</p>
                    )}
                  </div>

                  {/* Route Card */}
                  <div className="group/card relative bg-white p-5 rounded-xl border-2 border-slate-200 hover:border-emerald-400 hover:shadow-lg transition-all duration-200">
                    <div className="absolute top-4 right-4">
                      <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 flex items-center justify-center group-hover/card:from-emerald-100 group-hover/card:to-emerald-200 transition-colors shadow-sm">
                        <TrendingUp className="w-5 h-5 text-emerald-600" />
                      </div>
                    </div>
                    <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-3">Route</p>
                    {item.route ? (
                      <div>
                        <p className="font-bold text-slate-900 mb-2 text-base">{item.route.name}</p>
                        <p className="text-sm text-slate-600 font-mono bg-slate-50 px-2 py-1 rounded inline-block">{item.route.route_code}</p>
                      </div>
                    ) : (
                      <p className="text-sm text-slate-400 italic font-medium">Not assigned</p>
                    )}
                  </div>
                </div>

                {/* Children List - Modern Table */}
                <div className="px-6 pb-6">
                  <div className="flex items-center justify-between mb-4">
                    <h5 className="font-bold text-lg text-slate-900 flex items-center gap-2">
                      <div className="w-1 h-6 bg-gradient-to-b from-blue-600 to-indigo-600 rounded-full"></div>
                      Children on Board
                      <span className="ml-2 px-3 py-1 bg-gradient-to-r from-blue-500 to-indigo-600 text-white text-xs font-bold rounded-full shadow-sm">
                        {item.children?.length || 0}
                      </span>
                    </h5>
                  </div>

                  {item.children && item.children.length > 0 ? (
                    <>
                      {/* Children Table - Desktop */}
                      <div className="bg-white rounded-xl border-2 border-slate-200 overflow-hidden shadow-sm hidden md:block">
                        <div className="overflow-x-auto">
                          <table className="w-full">
                            <thead>
                              <tr className="bg-gradient-to-r from-slate-100 via-slate-50 to-slate-100">
                                <th className="px-5 py-4 text-left text-xs font-bold text-slate-700 uppercase tracking-wider border-b-2 border-slate-200">
                                  Student
                                </th>
                                <th className="px-5 py-4 text-left text-xs font-bold text-slate-700 uppercase tracking-wider border-b-2 border-slate-200">
                                  Grade
                                </th>
                                <th className="px-5 py-4 text-left text-xs font-bold text-slate-700 uppercase tracking-wider border-b-2 border-slate-200">
                                  Parent
                                </th>
                                <th className="px-5 py-4 text-left text-xs font-bold text-slate-700 uppercase tracking-wider border-b-2 border-slate-200">
                                  Contact
                                </th>
                              </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                              {item.children.map((child, index) => (
                                <tr key={`${item.id}-child-${child.id}-${index}`} className="hover:bg-gradient-to-r hover:from-blue-50 hover:to-indigo-50 transition-colors group/row">
                                  <td className="px-5 py-4">
                                    <div className="flex items-center gap-3">
                                      <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 via-indigo-600 to-purple-600 flex items-center justify-center text-white text-sm font-bold shadow-md group-hover/row:shadow-lg transition-shadow">
                                        {child.first_name.charAt(0)}{child.last_name.charAt(0)}
                                      </div>
                                      <span className="font-bold text-slate-900 text-base">
                                        {child.first_name} {child.last_name}
                                      </span>
                                    </div>
                                  </td>
                                  <td className="px-5 py-4">
                                    <span className="inline-flex px-3 py-1.5 bg-gradient-to-r from-slate-100 to-slate-200 text-slate-700 text-xs font-bold rounded-lg shadow-sm">
                                      {child.grade || 'N/A'}
                                    </span>
                                  </td>
                                  <td className="px-5 py-4 font-semibold text-slate-900">{child.parent_name}</td>
                                  <td className="px-5 py-4 font-mono text-sm text-slate-600 bg-slate-50 group-hover/row:bg-white transition-colors">
                                    {child.parent_phone}
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </div>

                      {/* Children Cards - Mobile */}
                      <div className="md:hidden space-y-3">
                        {item.children.map((child, index) => (
                          <div key={`${item.id}-child-mobile-${child.id}-${index}`} className="bg-white rounded-xl border-2 border-slate-200 p-4 shadow-sm">
                            <div className="flex items-start gap-3 mb-3">
                              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 via-indigo-600 to-purple-600 flex items-center justify-center text-white text-sm font-bold shadow-md flex-shrink-0">
                                {child.first_name.charAt(0)}{child.last_name.charAt(0)}
                              </div>
                              <div className="flex-1">
                                <p className="font-bold text-slate-900 text-base">
                                  {child.first_name} {child.last_name}
                                </p>
                                <span className="inline-flex px-2 py-1 bg-gradient-to-r from-slate-100 to-slate-200 text-slate-700 text-xs font-bold rounded-lg shadow-sm mt-1">
                                  {child.grade || 'N/A'}
                                </span>
                              </div>
                            </div>
                            <div className="space-y-2 pt-3 border-t border-slate-200">
                              <div className="flex items-center gap-2 text-sm">
                                <Users className="w-4 h-4 text-slate-400" />
                                <span className="text-slate-600">Parent:</span>
                                <span className="font-semibold text-slate-900">{child.parent_name}</span>
                              </div>
                              <div className="flex items-center gap-2 text-sm">
                                <Calendar className="w-4 h-4 text-slate-400" />
                                <span className="text-slate-600">Contact:</span>
                                <span className="font-mono text-sm text-slate-600">{child.parent_phone}</span>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </>
                  ) : (
                    <div className="bg-gradient-to-br from-slate-50 to-slate-100 rounded-xl border-2 border-dashed border-slate-300 p-12 text-center">
                      <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-white shadow-md mb-4">
                        <Users className="w-8 h-8 text-slate-400" />
                      </div>
                      <p className="text-slate-600 font-bold text-base">No children assigned</p>
                      <p className="text-slate-400 text-sm mt-2">This bus has no active child assignments</p>
                    </div>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </Modal>

      {/* View Details Modal */}
      <Modal
        isOpen={showViewDetailsModal}
        onClose={() => setShowViewDetailsModal(false)}
        title="Assignment Details"
        size="lg"
      >
        {viewingAssignment && (
          <div className="space-y-4">
            {/* Type and Status */}
            <div className="grid grid-cols-2 gap-4 pb-4 border-b border-slate-200">
              <div>
                <p className="text-sm text-slate-600 mb-1">Assignment Type</p>
                <p className="font-semibold text-slate-900">
                  {viewingAssignment.assignmentType.replace(/_/g, ' ').toUpperCase()}
                </p>
              </div>
              <div>
                <p className="text-sm text-slate-600 mb-1">Status</p>
                <span
                  className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusBadgeClass(
                    viewingAssignment.status
                  )}`}
                >
                  {viewingAssignment.status.toUpperCase()}
                </span>
              </div>
            </div>

            {/* Assignee Info */}
            <div className="pb-4 border-b border-slate-200">
              <h4 className="font-semibold text-slate-900 mb-3">Assignee Information</h4>
              <div className="bg-slate-50 p-4 rounded-lg space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-slate-600">Name:</span>
                  <span className="font-medium">{viewingAssignment.assigneeName || 'N/A'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-slate-600">Type:</span>
                  <span className="font-medium capitalize">{viewingAssignment.assigneeType}</span>
                </div>
                {viewingAssignment.assigneeDetails && (
                  <>
                    {viewingAssignment.assigneeDetails.grade && (
                      <div className="flex justify-between">
                        <span className="text-sm text-slate-600">Grade:</span>
                        <span className="font-medium">{viewingAssignment.assigneeDetails.grade}</span>
                      </div>
                    )}
                    {viewingAssignment.assigneeDetails.licenseNumber && (
                      <div className="flex justify-between">
                        <span className="text-sm text-slate-600">License:</span>
                        <span className="font-medium">{viewingAssignment.assigneeDetails.licenseNumber}</span>
                      </div>
                    )}
                  </>
                )}
              </div>
            </div>

            {/* Assigned To Info */}
            <div className="pb-4 border-b border-slate-200">
              <h4 className="font-semibold text-slate-900 mb-3">Assigned To</h4>
              <div className="bg-slate-50 p-4 rounded-lg space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-slate-600">Name:</span>
                  <span className="font-medium">{viewingAssignment.assignedToName || 'N/A'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-slate-600">Type:</span>
                  <span className="font-medium capitalize">{viewingAssignment.assignedToType}</span>
                </div>
                {viewingAssignment.assignedToDetails && (
                  <>
                    {viewingAssignment.assignedToDetails.capacity && (
                      <div className="flex justify-between">
                        <span className="text-sm text-slate-600">Capacity:</span>
                        <span className="font-medium">{viewingAssignment.assignedToDetails.capacity}</span>
                      </div>
                    )}
                    {viewingAssignment.assignedToDetails.licensePlate && (
                      <div className="flex justify-between">
                        <span className="text-sm text-slate-600">License Plate:</span>
                        <span className="font-medium">{viewingAssignment.assignedToDetails.licensePlate}</span>
                      </div>
                    )}
                  </>
                )}
              </div>
            </div>

            {/* Dates */}
            <div className="pb-4 border-b border-slate-200">
              <h4 className="font-semibold text-slate-900 mb-3">Timeline</h4>
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-slate-600">Effective Date:</span>
                  <span className="font-medium">{viewingAssignment.effectiveDate}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-slate-600">Expiry Date:</span>
                  <span className="font-medium">{viewingAssignment.expiryDate || 'Permanent'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-slate-600">Assigned At:</span>
                  <span className="font-medium">
                    {new Date(viewingAssignment.assignedAt).toLocaleString()}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-slate-600">Currently Active:</span>
                  <span className={`font-medium ${viewingAssignment.isCurrentlyActive ? 'text-green-600' : 'text-slate-600'}`}>
                    {viewingAssignment.isCurrentlyActive ? 'Yes' : 'No'}
                  </span>
                </div>
              </div>
            </div>

            {/* Audit Info */}
            {viewingAssignment.assignedByName && (
              <div className="pb-4 border-b border-slate-200">
                <h4 className="font-semibold text-slate-900 mb-3">Audit Information</h4>
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-sm text-slate-600">Assigned By:</span>
                    <span className="font-medium">{viewingAssignment.assignedByName}</span>
                  </div>
                </div>
              </div>
            )}

            {/* Reason and Notes */}
            {(viewingAssignment.reason || viewingAssignment.notes) && (
              <div>
                {viewingAssignment.reason && (
                  <div className="mb-3">
                    <p className="text-sm text-slate-600 mb-1">Reason:</p>
                    <p className="text-slate-900">{viewingAssignment.reason}</p>
                  </div>
                )}
                {viewingAssignment.notes && (
                  <div>
                    <p className="text-sm text-slate-600 mb-1">Notes:</p>
                    <p className="text-slate-900">{viewingAssignment.notes}</p>
                  </div>
                )}
              </div>
            )}

            <div className="pt-4">
              <Button onClick={() => setShowViewDetailsModal(false)} className="w-full">
                Close
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
