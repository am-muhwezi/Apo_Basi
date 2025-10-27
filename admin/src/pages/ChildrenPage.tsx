import React, { useState } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2, Baby, Users, Bus as BusIcon, UserCheck } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import { childService } from '../services/childService';
import type { Child, Parent, Bus } from '../types';

export default function ChildrenPage() {
  const [children, setChildren] = useState<Child[]>([]);
  const [parents, setParents] = useState<Parent[]>([]);
  const [buses, setBuses] = useState<Bus[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [gradeFilter, setGradeFilter] = useState('all');
  const [selectedChild, setSelectedChild] = useState<Child | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [formData, setFormData] = useState<Partial<Child>>({});

  const grades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'];

  // Fetch data from backend on mount
  React.useEffect(() => {
    loadChildren();
    loadParents();
    loadBuses();
  }, []);

  async function loadChildren() {
    try {
      const data = await childService.loadChildren();
      setChildren(data);
    } catch (error) {
      console.error('Failed to load children:', error);
    }
  }

  async function loadParents() {
    try {
      const data = await childService.loadParents();
      setParents(data);
    } catch (error) {
      console.error('Failed to load parents:', error);
    }
  }

  async function loadBuses() {
    try {
      const data = await childService.loadBuses();
      setBuses(data);
    } catch (error) {
      console.error('Failed to load buses:', error);
    }
  }

  const filteredChildren = children.filter((child) => {
    const matchesSearch =
      child.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      child.lastName.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesGrade = gradeFilter === 'all' || child.grade === gradeFilter;
    return matchesSearch && matchesGrade;
  });

  // Calculate stats (moved after filteredChildren definition)
  const totalChildren = children.length;
  const activeChildren = children.filter((c) => c.status === 'active').length;
  const childrenWithBus = children.filter((c) => c.busId).length;
  const childrenByGrade = filteredChildren.length;

  const handleCreate = () => {
    setSelectedChild(null);
    setFormData({
      firstName: '',
      lastName: '',
      grade: 'Grade 1',
      age: 6,
      parentId: parents[0]?.id || '',
      address: '',
      emergencyContact: '',
      status: 'active',
    });
    setShowModal(true);
  };

  const handleEdit = (child: Child) => {
    setSelectedChild(child);
    setFormData(child);
    setShowModal(true);
  };

  const handleView = (child: Child) => {
    setSelectedChild(child);
    setShowDetailModal(true);
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this child?')) {
      try {
        await childService.deleteChild(id);
        loadChildren();
      } catch (error) {
        alert('Failed to delete child');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (selectedChild) {
        await childService.updateChild(selectedChild.id, formData);
      } else {
        await childService.createChild(formData);
      }
      loadChildren();
      setShowModal(false);
    } catch (error) {
      alert(`Failed to ${selectedChild ? 'update' : 'create'} child`);
    }
  };

  const getParentName = (parentId: string) => {
    const parent = parents.find((p) => p.id === parentId);
    return parent ? `${parent.firstName} ${parent.lastName}` : 'Unknown';
  };

  const getBusNumber = (busId?: string) => {
    if (!busId) return 'Not Assigned';
    const bus = buses.find((b) => b.id === busId);
    return bus ? bus.busNumber : 'Unknown';
  };

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

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 mb-6 p-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
            <input
              type="text"
              placeholder="Search by name..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
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

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
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
                    {getParentName(child.parentId)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {getBusNumber(child.busId)}
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
      </div>

      <Modal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        title={selectedChild ? 'Edit Child' : 'Add New Child'}
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
          <div className="grid grid-cols-2 gap-4">
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
          <Select
            label="Parent"
            value={formData.parentId || ''}
            onChange={(e) => setFormData({ ...formData, parentId: e.target.value })}
            options={parents.map((p) => ({ value: p.id, label: `${p.firstName} ${p.lastName}` }))}
          />
          <Select
            label="Assigned Bus"
            value={formData.busId || ''}
            onChange={(e) => setFormData({ ...formData, busId: e.target.value || undefined })}
            options={[
              { value: '', label: 'Not Assigned' },
              ...buses.map((b) => ({ value: b.id, label: b.busNumber })),
            ]}
          />
          <Input
            label="Address"
            value={formData.address || ''}
            onChange={(e) => setFormData({ ...formData, address: e.target.value })}
            required
          />
          <Input
            label="Emergency Contact"
            value={formData.emergencyContact || ''}
            onChange={(e) => setFormData({ ...formData, emergencyContact: e.target.value })}
            required
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

      <Modal
        isOpen={showDetailModal}
        onClose={() => setShowDetailModal(false)}
        title="Child Details"
      >
        {selectedChild && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-slate-700">Name</p>
                <p className="text-base text-slate-900">
                  {selectedChild.firstName} {selectedChild.lastName}
                </p>
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
                <p className="text-sm font-medium text-slate-700">Status</p>
                <p className="text-base text-slate-900">{selectedChild.status}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Parent</p>
                <p className="text-base text-slate-900">{getParentName(selectedChild.parentId)}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Assigned Bus</p>
                <p className="text-base text-slate-900">{getBusNumber(selectedChild.busId)}</p>
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
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
