import React, { useState } from 'react';
import { Plus, Search, Eye, CreditCard as Edit, Trash2, Key } from 'lucide-react';
import Button from '../components/common/Button';
import Input from '../components/common/Input';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import FormError from '../components/common/FormError';
import { getAdmins, createAdmin, updateAdmin, deleteAdmin, changeAdminPassword } from '../services/adminApi';
import { useToast } from '../contexts/ToastContext';
import { useConfirm } from '../contexts/ConfirmContext';
import type { Admin, Permission } from '../types';

export default function AdminsPage() {
  const toast = useToast();
  const confirm = useConfirm();
  const [formError, setFormError] = useState<string | null>(null);
  const [admins, setAdmins] = useState<Admin[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(false);

  // Fetch admins from backend
  React.useEffect(() => {
    loadAdmins();
  }, []);

  async function loadAdmins(append = false) {
    try {
      setLoading(true);
      const offset = append ? admins.length : 0;
      const response = await getAdmins({ limit: 20, offset });
      // Handle paginated response from DRF: {results: [], count, next, previous}
      const data = response.data.results || response.data || [];
      setAdmins(append ? [...admins, ...Array.isArray(data) ? data : []] : (Array.isArray(data) ? data : []));
      setHasMore(Array.isArray(data) && data.length === 20);
    } catch (error) {
      if (!append) setAdmins([]);
    } finally {
      setLoading(false);
    }
  }

  function loadMoreAdmins() {
    if (!loading && hasMore) {
      loadAdmins(true);
    }
  }
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedAdmin, setSelectedAdmin] = useState<Admin | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [formData, setFormData] = useState<Partial<Admin>>({});
  const [passwordData, setPasswordData] = useState({
    newPassword: '',
    confirmPassword: ''
  });

  const allPermissions: Permission[] = [
    'manage-children',
    'manage-parents',
    'manage-buses',
    'manage-drivers',
    'manage-minders',
    'manage-trips',
    'manage-admins',
    'view-reports',
  ];

  const filteredAdmins = admins.filter((admin) => {
    const matchesSearch =
      admin.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      admin.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      admin.email.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesSearch;
  });

  const handleCreate = () => {
    setSelectedAdmin(null);
    setFormError(null);
    setFormData({
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      role: 'viewer',
      permissions: [],
      status: 'active',
    });
    setShowModal(true);
  };

  const handleEdit = (admin: Admin) => {
    setSelectedAdmin(admin);
    setFormError(null);
    setFormData(admin);
    setShowModal(true);
  };

  const handleView = (admin: Admin) => {
    setSelectedAdmin(admin);
    setShowDetailModal(true);
  };

  const handleChangePassword = (admin: Admin) => {
    setSelectedAdmin(admin);
    setFormError(null);
    setPasswordData({ newPassword: '', confirmPassword: '' });
    setShowPasswordModal(true);
  };

  const handleDelete = async (id: string) => {
    const confirmed = await confirm({
      title: 'Delete Admin',
      message: 'Are you sure you want to delete this admin? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      variant: 'danger',
    });

    if (confirmed) {
      try {
        await deleteAdmin(id);
        toast.success('Admin deleted successfully');
        await loadAdmins();
      } catch (error) {
        toast.error('Failed to delete admin');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    try {
      if (selectedAdmin) {
        await updateAdmin(selectedAdmin.id, formData);
        toast.success('Admin updated successfully');
      } else {
        await createAdmin({
          firstName: formData.firstName!,
          lastName: formData.lastName!,
          email: formData.email,
          phone: formData.phone!,
          role: formData.role as 'super-admin' | 'admin' | 'viewer',
          status: formData.status as 'active' | 'inactive'
        });
        toast.success('Admin created successfully');
      }
      await loadAdmins();
      setShowModal(false);
    } catch (error: any) {
      const message = error?.response?.data?.detail ||
                      error?.response?.data?.email?.[0] ||
                      error?.message ||
                      'Failed to save admin. Please check the form.';
      setFormError(message);
    }
  };

  const handlePasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (passwordData.newPassword !== passwordData.confirmPassword) {
      setFormError('Passwords do not match');
      return;
    }

    if (passwordData.newPassword.length < 6) {
      setFormError('Password must be at least 6 characters');
      return;
    }

    if (!selectedAdmin) return;

    try {
      await changeAdminPassword(selectedAdmin.id, passwordData);
      toast.success('Password changed successfully');
      setShowPasswordModal(false);
      setPasswordData({ newPassword: '', confirmPassword: '' });
    } catch (error: any) {
      const message = error?.response?.data?.confirmPassword?.[0] ||
                      error?.response?.data?.detail ||
                      error?.message ||
                      'Failed to change password. Please try again.';
      setFormError(message);
    }
  };

  const togglePermission = (permission: Permission) => {
    const currentPermissions = formData.permissions || [];
    const newPermissions = currentPermissions.includes(permission)
      ? currentPermissions.filter((p) => p !== permission)
      : [...currentPermissions, permission];
    setFormData({ ...formData, permissions: newPermissions });
  };

  const formatPermission = (permission: string) => {
    return permission
      .split('-')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  };

  const formatDate = (timestamp: string) => {
    return new Date(timestamp).toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900 mb-4 md:mb-0">Admin Management</h1>
        <Button onClick={handleCreate}>
          <Plus size={20} className="mr-2 inline" />
          Add Admin
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
                  Role
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Permissions
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-700 uppercase tracking-wider">
                  Last Login
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
              {filteredAdmins.map((admin) => (
                <tr key={admin.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="font-medium text-slate-900">
                      {admin.firstName} {admin.lastName}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700">{admin.email}</td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 py-1 text-xs font-medium rounded-full ${
                        admin.role === 'super-admin'
                          ? 'bg-red-100 text-red-800'
                          : admin.role === 'admin'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-slate-100 text-slate-800'
                      }`}
                    >
                      {admin.role}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-slate-700">{admin.permissions.length} permissions</td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-700 text-sm">
                    {admin.lastLogin ? formatDate(admin.lastLogin) : 'Never'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 py-1 text-xs font-medium rounded-full ${
                        admin.status === 'active'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-slate-100 text-slate-800'
                      }`}
                    >
                      {admin.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => handleView(admin)}
                        className="p-2 hover:bg-blue-50 rounded-lg text-blue-600"
                        title="View details"
                      >
                        <Eye size={18} />
                      </button>
                      <button
                        onClick={() => handleChangePassword(admin)}
                        className="p-2 hover:bg-purple-50 rounded-lg text-purple-600"
                        title="Change password"
                      >
                        <Key size={18} />
                      </button>
                      <button
                        onClick={() => handleEdit(admin)}
                        className="p-2 hover:bg-slate-100 rounded-lg text-slate-600"
                        title="Edit admin"
                      >
                        <Edit size={18} />
                      </button>
                      <button
                        onClick={() => handleDelete(admin.id)}
                        className="p-2 hover:bg-red-50 rounded-lg text-red-600"
                        title="Delete admin"
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
              Loaded {filteredAdmins.length} of {filteredAdmins.length}{hasMore ? '+' : ''} admins
            </span>
            {hasMore && (
              <Button
                onClick={loadMoreAdmins}
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
        title={selectedAdmin ? 'Edit Admin' : 'Add New Admin'}
        size="lg"
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
          <Select
            label="Role"
            value={formData.role || ''}
            onChange={(e) =>
              setFormData({ ...formData, role: e.target.value as Admin['role'] })
            }
            options={[
              { value: 'viewer', label: 'Viewer' },
              { value: 'admin', label: 'Admin' },
              { value: 'super-admin', label: 'Super Admin' },
            ]}
          />

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-3">
              Permissions
            </label>
            <div className="grid grid-cols-2 gap-3 max-h-64 overflow-y-auto border border-slate-300 rounded-lg p-4">
              {allPermissions.map((permission) => (
                <label
                  key={permission}
                  className="flex items-center p-2 hover:bg-slate-50 rounded cursor-pointer"
                >
                  <input
                    type="checkbox"
                    checked={formData.permissions?.includes(permission) || false}
                    onChange={() => togglePermission(permission)}
                    className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm text-slate-700">
                    {formatPermission(permission)}
                  </span>
                </label>
              ))}
            </div>
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
            <Button type="submit">{selectedAdmin ? 'Update' : 'Create'}</Button>
          </div>
        </form>
      </Modal>

      <Modal
        isOpen={showDetailModal}
        onClose={() => setShowDetailModal(false)}
        title="Admin Details"
      >
        {selectedAdmin && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-slate-700">Name</p>
                <p className="text-base text-slate-900">
                  {selectedAdmin.firstName} {selectedAdmin.lastName}
                </p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Role</p>
                <p className="text-base text-slate-900">{selectedAdmin.role}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Email</p>
                <p className="text-base text-slate-900">{selectedAdmin.email}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Phone</p>
                <p className="text-base text-slate-900">{selectedAdmin.phone}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Status</p>
                <p className="text-base text-slate-900">{selectedAdmin.status}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Last Login</p>
                <p className="text-base text-slate-900">
                  {selectedAdmin.lastLogin ? formatDate(selectedAdmin.lastLogin) : 'Never'}
                </p>
              </div>
              <div className="col-span-2">
                <p className="text-sm font-medium text-slate-700 mb-2">Permissions</p>
                <div className="flex flex-wrap gap-2">
                  {selectedAdmin.permissions.map((permission) => (
                    <span
                      key={permission}
                      className="px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-sm"
                    >
                      {formatPermission(permission)}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}
      </Modal>

      <Modal
        isOpen={showPasswordModal}
        onClose={() => setShowPasswordModal(false)}
        title={`Change Password - ${selectedAdmin?.firstName} ${selectedAdmin?.lastName}`}
      >
        <form onSubmit={handlePasswordSubmit} className="space-y-4">
          <FormError message={formError} onDismiss={() => setFormError(null)} />

          <Input
            label="New Password"
            type="password"
            value={passwordData.newPassword}
            onChange={(e) => setPasswordData({ ...passwordData, newPassword: e.target.value })}
            required
            minLength={6}
            placeholder="Enter new password (min 6 characters)"
          />

          <Input
            label="Confirm Password"
            type="password"
            value={passwordData.confirmPassword}
            onChange={(e) => setPasswordData({ ...passwordData, confirmPassword: e.target.value })}
            required
            minLength={6}
            placeholder="Confirm new password"
          />

          <div className="flex justify-end gap-3 pt-4">
            <Button type="button" variant="secondary" onClick={() => setShowPasswordModal(false)}>
              Cancel
            </Button>
            <Button type="submit">Change Password</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
