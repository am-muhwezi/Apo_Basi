import React, { useState } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2 } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import { busMinderService } from '../services/busMinderService';
import { busService } from '../services/busService';
import type { BusMinder, Bus } from '../types';

export default function MindersPage() {
  const [minders, setMinders] = useState<BusMinder[]>([]);
  const [buses, setBuses] = useState<Bus[]>([]);

  // Fetch bus minders and buses from backend on mount
  React.useEffect(() => {
    loadMinders();
    loadBuses();
  }, []);

  async function loadMinders() {
    try {
      const data = await busMinderService.loadBusMinders();
      setMinders(data);
    } catch (error) {
      console.error('Failed to load bus minders:', error);
    }
  }

  async function loadBuses() {
    try {
      const data = await busService.loadBuses();
      setBuses(data);
    } catch (error) {
      console.error('Failed to load buses:', error);
    }
  }

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedMinder, setSelectedMinder] = useState<BusMinder | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [formData, setFormData] = useState<Partial<BusMinder>>({});

  const filteredMinders = minders.filter((minder) => {
    const matchesSearch =
      minder.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      minder.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      minder.email.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesSearch;
  });

  const handleCreate = () => {
    setSelectedMinder(null);
    setFormData({
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      certifications: [],
      status: 'active',
    });
    setShowModal(true);
  };

  const handleEdit = (minder: BusMinder) => {
    setSelectedMinder(minder);
    setFormData(minder);
    setShowModal(true);
  };

  const handleView = (minder: BusMinder) => {
    setSelectedMinder(minder);
    setShowDetailModal(true);
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this bus minder?')) {
      try {
        await busMinderService.deleteBusMinder(id);
        loadMinders();
      } catch (error) {
        alert('Failed to delete bus minder');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (selectedMinder) {
        await busMinderService.updateBusMinder(selectedMinder.id, formData);
      } else {
        await busMinderService.createBusMinder(formData);
      }
      loadMinders();
      setShowModal(false);
    } catch (error) {
      alert(`Failed to ${selectedMinder ? 'update' : 'create'} bus minder`);
    }
  };

  const getBusNumber = (busId: string | undefined) => {
    if (!busId) return 'Not assigned';
    const bus = buses.find((b) => b.id === busId);
    return bus ? bus.busNumber : 'Not assigned';
  };

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900 mb-4 md:mb-0">Bus Minders</h1>
        <Button onClick={handleCreate}>
          <Plus size={20} className="mr-2 inline" />
          Add Bus Minder
        </Button>
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
                  Certifications
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
              {filteredMinders.map((minder) => (
                <tr key={minder.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="font-medium text-slate-900">
                      {minder.firstName} {minder.lastName}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{minder.email}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{minder.phone}</td>
                  <td className="px-6 py-4 text-slate-700">
                    {minder.certifications?.join(', ') || 'None'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">
                    {getBusNumber(minder.assignedBusId)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 py-1 text-xs font-medium rounded-full ${
                        minder.status === 'active'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-slate-100 text-slate-800'
                      }`}
                    >
                      {minder.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => handleView(minder)}
                        className="p-2 hover:bg-blue-50 rounded-lg text-blue-600"
                      >
                        <Eye size={18} />
                      </button>
                      <button
                        onClick={() => handleEdit(minder)}
                        className="p-2 hover:bg-slate-100 rounded-lg text-slate-600"
                      >
                        <Edit size={18} />
                      </button>
                      <button
                        onClick={() => handleDelete(minder.id)}
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
        title={selectedMinder ? 'Edit Bus Minder' : 'Add New Bus Minder'}
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
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Certifications (comma-separated)
            </label>
            <Input
              value={formData.certifications?.join(', ') || ''}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  certifications: e.target.value.split(',').map((c) => c.trim()).filter(Boolean),
                })
              }
              placeholder="e.g., First Aid, CPR, Child Safety"
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
            <Button type="submit">{selectedMinder ? 'Update' : 'Create'}</Button>
          </div>
        </form>
      </Modal>

      <Modal
        isOpen={showDetailModal}
        onClose={() => setShowDetailModal(false)}
        title="Bus Minder Details"
      >
        {selectedMinder && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-slate-700">Name</p>
                <p className="text-base text-slate-900">
                  {selectedMinder.firstName} {selectedMinder.lastName}
                </p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Status</p>
                <p className="text-base text-slate-900">{selectedMinder.status}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Email</p>
                <p className="text-base text-slate-900">{selectedMinder.email}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Phone</p>
                <p className="text-base text-slate-900">{selectedMinder.phone}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Assigned Bus</p>
                <p className="text-base text-slate-900">
                  {getBusNumber(selectedMinder.assignedBusId)}
                </p>
              </div>
              <div className="col-span-2">
                <p className="text-sm font-medium text-slate-700">Certifications</p>
                <div className="flex flex-wrap gap-2 mt-1">
                  {selectedMinder.certifications && selectedMinder.certifications.length > 0 ? (
                    selectedMinder.certifications.map((cert, index) => (
                      <span
                        key={index}
                        className="px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-sm"
                      >
                        {cert}
                      </span>
                    ))
                  ) : (
                    <p className="text-slate-600">No certifications</p>
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
