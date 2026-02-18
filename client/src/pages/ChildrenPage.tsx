import React, { useState, useEffect } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2, Baby, Users, Bus as BusIcon, UserCheck, ArrowUpDown } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import FormError from '../components/common/FormError';
import ParentSearchInput from '../components/ParentSearchInput';
import { useChildren } from '../hooks/useChildren';
import { childService } from '../services/childService';
import { useToast } from '../contexts/ToastContext';
import { useConfirm } from '../contexts/ConfirmContext';
import { config } from '../config/environment';
import type { Child, Parent } from '../types';

export default function ChildrenPage() {
  const toast = useToast();
  const confirm = useConfirm();
  const [formError, setFormError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [ordering, setOrdering] = useState('first_name');
  const [gradeFilter, setGradeFilter] = useState('all');
  const [selectedChild, setSelectedChild] = useState<Child | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [formData, setFormData] = useState<Partial<Child>>({});
  const [selectedParent, setSelectedParent] = useState<Parent | null>(null);

  const grades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'];

  const {
    children,
    loading: childrenLoading,
    error: childrenError,
    hasMore: childrenHasMore,
    totalCount: childrenTotal,
    loadChildren,
    loadMore: loadMoreChildren,
    refreshChildren
  } = useChildren({ search: searchTerm, ordering });

  React.useEffect(() => { loadChildren(); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    const timer = setTimeout(() => loadChildren(), 400);
    return () => clearTimeout(timer);
  }, [searchTerm]); // eslint-disable-line react-hooks/exhaustive-deps

  // Grade filter stays client-side (exact enum match)
  const filteredChildren = gradeFilter === 'all'
    ? children
    : children.filter((child) => child.grade === gradeFilter);

  // Calculate stats
  const totalChildren = children.length;
  const activeChildren = children.filter((c) => c.status === 'active').length;
  const childrenWithBus = children.filter((c) => c.busId).length;
  const childrenByGrade = filteredChildren.length;

  const handleCreate = () => {
    setSelectedChild(null);
    setSelectedParent(null);
    setFormError(null);
    setFormData({
      firstName: '',
      lastName: '',
      grade: 'Grade 1',
      age: 6,
      parentId: '',
      address: '',
      emergencyContact: '',
      status: 'active',
    });
    setShowModal(true);
  };

  const handleEdit = (child: Child) => {
    setSelectedChild(child);
    setSelectedParent(null); // Will be populated by ParentSearchInput if child has parent
    setFormError(null);
    setFormData(child);
    setShowModal(true);
  };

  const handleView = (child: Child) => {
    setSelectedChild(child);
    setShowDetailModal(true);
  };

  const handleDelete = async (id: string) => {
    const confirmed = await confirm({
      title: 'Delete Child',
      message: 'Are you sure you want to delete this child? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      variant: 'danger',
    });

    if (confirmed) {
      const result = await childService.deleteChild(id);
      if (result.success) {
        toast.success('Child deleted successfully');
        await refreshChildren();
      } else {
        toast.error(result.error?.message || 'Failed to delete child');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (selectedChild) {
      const result = await childService.updateChild(selectedChild.id, formData);
      if (result.success) {
        toast.success('Child updated successfully');
        setShowModal(false);
        await refreshChildren();
      } else {
        setFormError(result.error?.message || 'Failed to update child');
      }
    } else {
      const result = await childService.createChild(formData);
      if (result.success) {
        toast.success('Child created successfully');
        setShowModal(false);
        await refreshChildren();
      } else {
        setFormError(result.error?.message || 'Failed to create child');
      }
    }
  };

  if (childrenError) {
    return (
      <div className="p-8 text-center">
        <p className="text-red-600 mb-4">Error: {childrenError}</p>
        <Button onClick={() => refreshChildren()}>Retry</Button>
      </div>
    );
  }

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900 mb-4 md:mb-0">Children</h1>
        <Button onClick={handleCreate}>
          <Plus size={20} className="mr-2 inline" />
          Add Child
        </Button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Baby className="w-5 h-5 text-blue-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Children</h3>
          <p className="text-2xl font-bold text-slate-900">{totalChildren}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-green-100 rounded-lg">
              <UserCheck className="w-5 h-5 text-green-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Active</h3>
          <p className="text-2xl font-bold text-slate-900">{activeChildren}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-purple-100 rounded-lg">
              <BusIcon className="w-5 h-5 text-purple-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Assigned to Bus</h3>
          <p className="text-2xl font-bold text-slate-900">{childrenWithBus}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-orange-100 rounded-lg">
              <Search className="w-5 h-5 text-orange-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Filtered Results</h3>
          <p className="text-2xl font-bold text-slate-900">{childrenByGrade}</p>
        </div>
      </div>

      {/* Search and Filter */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 mb-6 p-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="flex gap-2">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
              <input
                type="text"
                placeholder="Search by name..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <button
              onClick={() => setOrdering(ordering === 'first_name' ? '-first_name' : 'first_name')}
              className="flex items-center gap-1 px-3 py-2 border border-slate-300 rounded-lg text-slate-600 hover:bg-slate-50"
              title="Toggle sort order"
            >
              <ArrowUpDown size={16} />
            </button>
          </div>
          <Select
            value={gradeFilter}
            onChange={(e) => setGradeFilter(e.target.value)}
            options={[
              { value: 'all', label: 'All Grades' },
              ...grades.map((g) => ({ value: g, label: g })),
            ]}
          />
        </div>
      </div>

      {/* Children Table - Desktop */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden hidden md:block">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Grade
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Age
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Parent
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Bus
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
              {filteredChildren.map((child) => (
                <tr key={child.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="font-medium text-slate-900">
                      {child.firstName} {child.lastName}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{child.grade}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{child.age}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {child.parentName || 'Unknown'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {child.assignedBusNumber || 'Not Assigned'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 py-1 text-xs font-medium rounded-full ${
                        child.status === 'active'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-slate-100 text-slate-800'
                      }`}
                    >
                      {child.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => handleView(child)}
                        className="p-2 hover:bg-blue-50 rounded-lg text-blue-600"
                      >
                        <Eye size={18} />
                      </button>
                      <button
                        onClick={() => handleEdit(child)}
                        className="p-2 hover:bg-slate-100 rounded-lg text-slate-600"
                      >
                        <Edit size={18} />
                      </button>
                      <button
                        onClick={() => handleDelete(child.id)}
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

        {/* Pagination - Desktop */}
        <div className="p-4 border-t border-slate-200">
          <div className="flex flex-col items-center gap-3">
            <span className="text-sm text-slate-600">
              Loaded {children.length} of {childrenTotal} children
            </span>
            {childrenHasMore && (
              <Button
                onClick={loadMoreChildren}
                disabled={childrenLoading}
                variant="secondary"
                size="sm"
              >
                {childrenLoading ? 'Loading...' : 'Load More'}
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Children Cards - Mobile */}
      <div className="md:hidden space-y-4">
        {filteredChildren.map((child) => (
          <div key={child.id} className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="flex items-start justify-between mb-3">
              <div>
                <h3 className="font-semibold text-slate-900 text-lg">
                  {child.firstName} {child.lastName}
                </h3>
                <p className="text-sm text-slate-600">{child.grade} • Age {child.age}</p>
              </div>
              <span
                className={`px-2 py-1 text-xs font-medium rounded-full ${
                  child.status === 'active'
                    ? 'bg-green-100 text-green-800'
                    : 'bg-slate-100 text-slate-800'
                }`}
              >
                {child.status}
              </span>
            </div>

            <div className="space-y-2 mb-4">
              <div className="flex items-center gap-2 text-sm">
                <Users className="w-4 h-4 text-slate-400" />
                <span className="text-slate-600">Parent:</span>
                <span className="font-medium text-slate-900">{child.parentName || 'Unknown'}</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <BusIcon className="w-4 h-4 text-slate-400" />
                <span className="text-slate-600">Bus:</span>
                <span className="font-medium text-slate-900">{child.assignedBusNumber || 'Not Assigned'}</span>
              </div>
            </div>

            <div className="flex gap-2 pt-3 border-t border-slate-200">
              <button
                onClick={() => handleView(child)}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
              >
                <Eye size={18} />
                <span className="text-sm font-medium">View</span>
              </button>
              <button
                onClick={() => handleEdit(child)}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-slate-50 text-slate-600 rounded-lg hover:bg-slate-100 transition-colors"
              >
                <Edit size={18} />
                <span className="text-sm font-medium">Edit</span>
              </button>
              <button
                onClick={() => handleDelete(child.id)}
                className="px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
              >
                <Trash2 size={18} />
              </button>
            </div>
          </div>
        ))}

        {/* Pagination - Mobile */}
        {filteredChildren.length > 0 && (
          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="flex flex-col items-center gap-3">
              <span className="text-sm text-slate-600">
                Loaded {children.length} of {childrenTotal} children
              </span>
              {childrenHasMore && (
                <Button
                  onClick={loadMoreChildren}
                  disabled={childrenLoading}
                  variant="secondary"
                  size="sm"
                  className="w-full"
                >
                  {childrenLoading ? 'Loading...' : 'Load More'}
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
        title={selectedChild ? 'Edit Child' : 'Add New Child'}
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
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select
              label="Grade"
              value={formData.grade || ''}
              onChange={(e) => setFormData({ ...formData, grade: e.target.value })}
              options={grades.map((g) => ({ value: g, label: g }))}
            />
            <Input
              label="Age"
              type="number"
              value={formData.age || ''}
              onChange={(e) => setFormData({ ...formData, age: parseInt(e.target.value) })}
              required
            />
          </div>
          <ParentSearchInput
            value={formData.parentId}
            selectedParent={selectedParent}
            onChange={(parentId, parent) => {
              setFormData({ ...formData, parentId });
              setSelectedParent(parent);
            }}
            placeholder="Search for parent by name, email, or phone..."
          />
          <Input
            label="Address"
            value={formData.address || ''}
            onChange={(e) => setFormData({ ...formData, address: e.target.value })}
          />
          <Input
            label="Emergency Contact"
            value={formData.emergencyContact || ''}
            onChange={(e) => setFormData({ ...formData, emergencyContact: e.target.value })}
          />
          <Input
            label="Medical Info"
            value={formData.medicalInfo || ''}
            onChange={(e) => setFormData({ ...formData, medicalInfo: e.target.value })}
          />
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
            <Button type="submit">{selectedChild ? 'Update' : 'Create'}</Button>
          </div>
        </form>
      </Modal>

      {/* Detail Modal */}
      <Modal isOpen={showDetailModal} onClose={() => setShowDetailModal(false)} title="Child Details">
        {selectedChild && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-slate-700">First Name</p>
                <p className="text-base text-slate-900">{selectedChild.firstName}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Last Name</p>
                <p className="text-base text-slate-900">{selectedChild.lastName}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Grade</p>
                <p className="text-base text-slate-900">{selectedChild.grade}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Age</p>
                <p className="text-base text-slate-900">{selectedChild.age}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Parent</p>
                <p className="text-base text-slate-900">{selectedChild.parentName || 'Unknown'}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Bus</p>
                <p className="text-base text-slate-900">{selectedChild.assignedBusNumber || 'Not Assigned'}</p>
              </div>
              <div className="col-span-2">
                <p className="text-sm font-medium text-slate-700">Address</p>
                <p className="text-base text-slate-900">{selectedChild.address}</p>
              </div>
              <div className="col-span-2">
                <p className="text-sm font-medium text-slate-700">Emergency Contact</p>
                <p className="text-base text-slate-900">{selectedChild.emergencyContact}</p>
              </div>
              {selectedChild.medicalInfo && (
                <div className="col-span-2">
                  <p className="text-sm font-medium text-slate-700">Medical Info</p>
                  <p className="text-base text-slate-900">{selectedChild.medicalInfo}</p>
                </div>
              )}
              <div>
                <p className="text-sm font-medium text-slate-700">Status</p>
                <p className="text-base text-slate-900">{selectedChild.status}</p>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
