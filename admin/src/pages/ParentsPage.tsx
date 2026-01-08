import React, { useState } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2, UserPlus, Users, Baby, UserCheck, Phone } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import FormError from '../components/common/FormError';
import { parentService } from '../services/parentService';
import { childService } from '../services/childService';
import { useToast } from '../contexts/ToastContext';
import { useConfirm } from '../contexts/ConfirmContext';
import type { Parent, Child } from '../types';

export default function ParentsPage() {
  const toast = useToast();
  const confirmDialog = useConfirm();
  const [formError, setFormError] = useState<string | null>(null);
  const [childFormError, setChildFormError] = useState<string | null>(null);
  const [parents, setParents] = useState<Parent[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(false);

  // State for parent-specific children (loaded on-demand)
  const [parentChildren, setParentChildren] = useState<Child[]>([]);
  const [loadingChildren, setLoadingChildren] = useState(false);

  // Fetch parents from backend on mount
  React.useEffect(() => {
    loadParents();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  async function loadParents(append = false) {
    try {
      setLoading(true);
      const offset = append ? parents.length : 0;
      const result = await parentService.loadParents({ limit: 20, offset });

      if (result.success && result.data) {
        const newParents = result.data.parents || [];
        setParents(append ? [...parents, ...newParents] : newParents);
        setHasMore(result.data.hasNext || false);
      }
    } catch (error) {
      console.error('Failed to load parents:', error);
    } finally {
      setLoading(false);
    }
  }

  function loadMoreParents() {
    if (!loading && hasMore) {
      loadParents(true);
    }
  }

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedParent, setSelectedParent] = useState<Parent | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showAddChildModal, setShowAddChildModal] = useState(false);
  const [showDeleteOptionsModal, setShowDeleteOptionsModal] = useState(false);
  const [deleteTargetId, setDeleteTargetId] = useState<string>('');
  const [deleteChildren, setDeleteChildren] = useState<any[]>([]);
  const [formData, setFormData] = useState<Partial<Parent>>({});
  const [childFormData, setChildFormData] = useState<Partial<Child>>({});

  const filteredParents = parents.filter((parent) => {
    const matchesSearch =
      parent.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      parent.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      parent.email.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesSearch;
  });

  const handleCreate = () => {
    setSelectedParent(null);
    setFormError(null);
    setFormData({
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      address: '',
      childrenIds: [],
      status: 'active',
    });
    setShowModal(true);
  };

  const handleEdit = (parent: Parent) => {
    setSelectedParent(parent);
    setFormError(null);
    setFormData(parent);
    setShowModal(true);
  };

  const handleView = async (parent: Parent) => {
    setSelectedParent(parent);
    setShowDetailModal(true);

    // Load children for this specific parent
    if (parent.childrenIds && parent.childrenIds.length > 0) {
      await loadParentChildren(parent.childrenIds);
    } else {
      setParentChildren([]);
    }
  };

  const loadParentChildren = async (childrenIds: string[]) => {
    try {
      setLoadingChildren(true);
      const childPromises = childrenIds.map(id => childService.getChild(id));
      const results = await Promise.all(childPromises);

      const loadedChildren = results
        .filter(result => result.success && result.data)
        .map(result => result.data!);

      setParentChildren(loadedChildren);
    } catch (error) {
      console.error('Failed to load children:', error);
      setParentChildren([]);
    } finally {
      setLoadingChildren(false);
    }
  };

  const handleDelete = async (id: string) => {
    // First attempt - check if parent has children
    const result = await parentService.deleteParent(id);

    if (result.success) {
      toast.success('Parent deleted successfully');
      loadParents();
      return;
    }

    // If requires confirmation (has children), show options modal
    if (result.error?.requiresConfirmation) {
      setDeleteTargetId(id);
      setDeleteChildren(result.error.children || []);
      setShowDeleteOptionsModal(true);
    } else {
      // Other error
      toast.error(result.error?.message || 'Failed to delete parent');
    }
  };

  const handleDeleteWithAction = async (action: 'keep_children' | 'delete_children') => {
    const result = await parentService.deleteParent(deleteTargetId, action);

    if (result.success) {
      const message = result.data?.message || 'Parent deleted successfully';
      toast.success(message);
      setShowDeleteOptionsModal(false);
      loadParents();
    } else {
      toast.error(result.error?.message || 'Failed to delete parent');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (selectedParent) {
      const result = await parentService.updateParent(selectedParent.id, formData);
      if (result.success) {
        toast.success('Parent updated successfully');
        loadParents();
        setShowModal(false);
      } else {
        setFormError(result.error?.message || 'Failed to update parent');
      }
    } else {
      const result = await parentService.createParent(formData);
      if (result.success) {
        toast.success('Parent created successfully');
        loadParents();
        setShowModal(false);
      } else {
        setFormError(result.error?.message || 'Failed to create parent');
      }
    }
  };

  const handleAddChild = (parent: Parent) => {
    setSelectedParent(parent);
    setChildFormError(null);
    setChildFormData({
      firstName: '',
      lastName: parent.lastName,
      grade: 'Grade 1',
      age: 6,
      parentId: parent.id,
      address: parent.address,
      emergencyContact: parent.phone,
      status: 'active',
    });
    setShowAddChildModal(true);
  };

  const handleChildSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setChildFormError(null);

    const result = await childService.createChild(childFormData);
    if (result.success) {
      toast.success('Child added successfully');
      loadParents(); // Reload parents to get updated childrenCount and childrenIds
      setShowAddChildModal(false);
    } else {
      setChildFormError(result.error?.message || 'Failed to create child');
    }
  };

  // Calculate stats from parent data (no need to load all children)
  const totalParents = parents.length;
  const activeParents = parents.filter((p) => p.status === 'active').length;
  const totalChildren = parents.reduce((sum, p) => sum + (p.childrenCount || 0), 0);
  const parentsWithChildren = parents.filter((p) => p.childrenIds && p.childrenIds.length > 0).length;

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900 mb-4 md:mb-0">Parents</h1>
        <Button onClick={handleCreate}>
          <Plus size={20} className="mr-2 inline" />
          Add Parent
        </Button>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Users className="w-5 h-5 text-blue-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Parents</h3>
          <p className="text-2xl font-bold text-slate-900">{totalParents}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-green-100 rounded-lg">
              <UserCheck className="w-5 h-5 text-green-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Active Parents</h3>
          <p className="text-2xl font-bold text-slate-900">{activeParents}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Baby className="w-5 h-5 text-purple-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Children</h3>
          <p className="text-2xl font-bold text-slate-900">{totalChildren}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-orange-100 rounded-lg">
              <UserPlus className="w-5 h-5 text-orange-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">With Children</h3>
          <p className="text-2xl font-bold text-slate-900">{parentsWithChildren}</p>
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
              {filteredParents.map((parent) => (
                <tr key={parent.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="font-medium text-slate-900">
                      {parent.firstName} {parent.lastName}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{parent.email}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{parent.phone}</td>
                  <td className="px-6 py-4 text-slate-700">
                    <div className="max-w-xs truncate">
                      {parent.childrenCount ? `${parent.childrenCount} ${parent.childrenCount === 1 ? 'child' : 'children'}` : 'No children'}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 py-1 text-xs font-medium rounded-full ${
                        parent.status === 'active'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-slate-100 text-slate-800'
                      }`}
                    >
                      {parent.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => handleAddChild(parent)}
                        className="p-2 hover:bg-green-50 rounded-lg text-green-600"
                        title="Add Child"
                      >
                        <UserPlus size={18} />
                      </button>
                      <button
                        onClick={() => handleView(parent)}
                        className="p-2 hover:bg-blue-50 rounded-lg text-blue-600"
                      >
                        <Eye size={18} />
                      </button>
                      <button
                        onClick={() => handleEdit(parent)}
                        className="p-2 hover:bg-slate-100 rounded-lg text-slate-600"
                      >
                        <Edit size={18} />
                      </button>
                      <button
                        onClick={() => handleDelete(parent.id)}
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
              Loaded {filteredParents.length} of {filteredParents.length}{hasMore ? '+' : ''} parents
            </span>
            {hasMore && (
              <Button
                onClick={loadMoreParents}
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

      <Modal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        title={selectedParent ? 'Edit Parent' : 'Add New Parent'}
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
          <Input
            label="Address"
            value={formData.address || ''}
            onChange={(e) => setFormData({ ...formData, address: e.target.value })}
            required
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
            <Button type="submit">{selectedParent ? 'Update' : 'Create'}</Button>
          </div>
        </form>
      </Modal>

      <Modal
        isOpen={showDetailModal}
        onClose={() => setShowDetailModal(false)}
        title="Parent Details"
      >
        {selectedParent && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-slate-700">Name</p>
                <p className="text-base text-slate-900">
                  {selectedParent.firstName} {selectedParent.lastName}
                </p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Status</p>
                <p className="text-base text-slate-900">{selectedParent.status}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Email</p>
                <p className="text-base text-slate-900">{selectedParent.email}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Phone</p>
                <p className="text-base text-slate-900">{selectedParent.phone}</p>
              </div>
              <div className="col-span-2">
                <p className="text-sm font-medium text-slate-700">Address</p>
                <p className="text-base text-slate-900">{selectedParent.address}</p>
              </div>
              <div className="col-span-2">
                <div className="flex items-center justify-between mb-2">
                  <p className="text-sm font-medium text-slate-700">Children</p>
                  <Button
                    size="sm"
                    onClick={() => {
                      setShowDetailModal(false);
                      handleAddChild(selectedParent);
                    }}
                  >
                    <UserPlus size={16} className="mr-1 inline" />
                    Add Child
                  </Button>
                </div>
                {loadingChildren ? (
                  <p className="text-slate-600">Loading children...</p>
                ) : (
                  <div className="space-y-2">
                    {parentChildren.length > 0 ? (
                      parentChildren.map((child) => (
                        <div key={child.id} className="p-3 bg-slate-50 rounded-lg">
                          <p className="font-medium text-slate-900">
                            {child.firstName} {child.lastName}
                          </p>
                          <p className="text-sm text-slate-600">{child.grade} - Age {child.age}</p>
                        </div>
                      ))
                    ) : (
                      <p className="text-slate-600">No children assigned</p>
                    )}
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </Modal>

      <Modal
        isOpen={showAddChildModal}
        onClose={() => setShowAddChildModal(false)}
        title={`Add Child to ${selectedParent?.firstName} ${selectedParent?.lastName}`}
      >
        <form onSubmit={handleChildSubmit} className="space-y-4">
          <FormError message={childFormError} onDismiss={() => setChildFormError(null)} />
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              label="First Name"
              value={childFormData.firstName || ''}
              onChange={(e) => setChildFormData({ ...childFormData, firstName: e.target.value })}
              required
            />
            <Input
              label="Last Name"
              value={childFormData.lastName || ''}
              onChange={(e) => setChildFormData({ ...childFormData, lastName: e.target.value })}
              required
            />
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select
              label="Grade"
              value={childFormData.grade || ''}
              onChange={(e) => setChildFormData({ ...childFormData, grade: e.target.value })}
              options={[
                'Grade 1',
                'Grade 2',
                'Grade 3',
                'Grade 4',
                'Grade 5',
                'Grade 6',
              ].map((g) => ({ value: g, label: g }))}
            />
            <Input
              label="Age"
              type="number"
              value={childFormData.age || ''}
              onChange={(e) => setChildFormData({ ...childFormData, age: parseInt(e.target.value) })}
              required
            />
          </div>
          <Input
            label="Address"
            value={childFormData.address || ''}
            onChange={(e) => setChildFormData({ ...childFormData, address: e.target.value })}
            required
          />
          <Input
            label="Emergency Contact"
            value={childFormData.emergencyContact || ''}
            onChange={(e) => setChildFormData({ ...childFormData, emergencyContact: e.target.value })}
            required
          />
          <div className="flex justify-end gap-3 pt-4">
            <Button type="button" variant="secondary" onClick={() => setShowAddChildModal(false)}>
              Cancel
            </Button>
            <Button type="submit">Add Child</Button>
          </div>
        </form>
      </Modal>

      {/* Delete Options Modal */}
      <Modal
        isOpen={showDeleteOptionsModal}
        onClose={() => setShowDeleteOptionsModal(false)}
        title="Delete Parent - Choose Action"
      >
        <div className="space-y-4">
          <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <p className="text-sm text-yellow-800 font-medium mb-2">
              This parent has {deleteChildren.length} child(ren):
            </p>
            <div className="space-y-1">
              {deleteChildren.map((child: any) => (
                <p key={child.id} className="text-sm text-yellow-700">
                  • {child.firstName} {child.lastName} ({child.grade})
                </p>
              ))}
            </div>
          </div>

          <p className="text-sm text-slate-600">
            What would you like to do with the children?
          </p>

          <div className="space-y-3">
            <button
              onClick={() => handleDeleteWithAction('keep_children')}
              className="w-full p-4 text-left border-2 border-blue-200 rounded-lg hover:border-blue-400 hover:bg-blue-50 transition-colors"
            >
              <div className="flex items-start gap-3">
                <div className="flex-shrink-0 w-5 h-5 mt-0.5 rounded-full border-2 border-blue-500"></div>
                <div>
                  <p className="font-medium text-slate-900">Keep Children (Recommended)</p>
                  <p className="text-sm text-slate-600 mt-1">
                    Delete only the parent. Children will have no parent assigned and can be
                    reassigned later from the Children page.
                  </p>
                </div>
              </div>
            </button>

            <button
              onClick={() => handleDeleteWithAction('delete_children')}
              className="w-full p-4 text-left border-2 border-red-200 rounded-lg hover:border-red-400 hover:bg-red-50 transition-colors"
            >
              <div className="flex items-start gap-3">
                <div className="flex-shrink-0 w-5 h-5 mt-0.5 rounded-full border-2 border-red-500"></div>
                <div>
                  <p className="font-medium text-slate-900">Delete All Data</p>
                  <p className="text-sm text-slate-600 mt-1">
                    Delete the parent AND all {deleteChildren.length} child(ren). This action
                    cannot be undone.
                  </p>
                </div>
              </div>
            </button>
          </div>

          <div className="flex justify-end pt-4">
            <Button variant="secondary" onClick={() => setShowDeleteOptionsModal(false)}>
              Cancel
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
