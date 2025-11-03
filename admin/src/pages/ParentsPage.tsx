import React, { useState } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2, UserPlus, Users, Baby, UserCheck, Phone } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import { parentService } from '../services/parentService';
import { childService } from '../services/childService';
import type { Parent, Child } from '../types';

export default function ParentsPage() {
  const [parents, setParents] = useState<Parent[]>([]);
  const [children, setChildren] = useState<Child[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(false);

  // Fetch parents and children from backend on mount
  React.useEffect(() => {
    loadParents();
    loadChildren();
  }, []);

  async function loadParents(append = false) {
    try {
      setLoading(true);
      const offset = append ? parents.length : 0;
      const data = await parentService.loadParents({ limit: 20, offset });
      setParents(append ? [...parents, ...data] : data);
      setHasMore(data.length === 20);
    } catch (error) {
      console.error('Failed to load parents:', error);
    } finally {
      setLoading(false);
    }
  }

  async function loadChildren() {
    try {
      const data = await childService.loadChildren({ limit: 100 });
      setChildren(data);
    } catch (error) {
      console.error('Failed to load children:', error);
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
    setFormData(parent);
    setShowModal(true);
  };

  const handleView = (parent: Parent) => {
    setSelectedParent(parent);
    setShowDetailModal(true);
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this parent?')) {
      try {
        await parentService.deleteParent(id);
        loadParents();
      } catch (error) {
        alert('Failed to delete parent');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (selectedParent) {
        await parentService.updateParent(selectedParent.id, formData);
      } else {
        await parentService.createParent(formData);
      }
      loadParents();
      setShowModal(false);
    } catch (error) {
      alert(`Failed to ${selectedParent ? 'update' : 'create'} parent`);
    }
  };

  const handleAddChild = (parent: Parent) => {
    setSelectedParent(parent);
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
    try {
      await childService.createChild(childFormData);
      loadParents();
      loadChildren();
      setShowAddChildModal(false);
    } catch (error) {
      alert('Failed to create child');
    }
  };

  const getChildrenNames = (childrenIds: string[] | undefined) => {
    if (!childrenIds || childrenIds.length === 0) return '';

    return childrenIds
      .map((id) => {
        const child = children.find((c) => c.id === id);
        return child ? `${child.firstName} ${child.lastName}` : null;
      })
      .filter(Boolean)
      .join(', ');
  };

  // Calculate stats
  const totalParents = parents.length;
  const activeParents = parents.filter((p) => p.status === 'active').length;
  const totalChildren = children.length;
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
                    <div className="max-w-xs truncate">{getChildrenNames(parent.childrenIds) || 'No children'}</div>
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
                <p className="text-sm font-medium text-slate-700 mb-2">Children</p>
                <div className="space-y-2">
                  {selectedParent.childrenIds && selectedParent.childrenIds.length > 0 ? (
                    selectedParent.childrenIds.map((childId) => {
                      const child = children.find((c) => c.id === childId);
                      return child ? (
                        <div key={child.id} className="p-3 bg-slate-50 rounded-lg">
                          <p className="font-medium text-slate-900">
                            {child.firstName} {child.lastName}
                          </p>
                          <p className="text-sm text-slate-600">{child.grade} - Age {child.age}</p>
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

      <Modal
        isOpen={showAddChildModal}
        onClose={() => setShowAddChildModal(false)}
        title={`Add Child to ${selectedParent?.firstName} ${selectedParent?.lastName}`}
      >
        <form onSubmit={handleChildSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
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
          <div className="grid grid-cols-2 gap-4">
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
    </div>
  );
}
