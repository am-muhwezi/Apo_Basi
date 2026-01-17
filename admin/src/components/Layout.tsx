import { useState, useEffect } from 'react';
import { Outlet, Link, useLocation } from 'react-router-dom';
import { Bus, Users, Baby, CircleUser as UserCircle, MapPin, Shield, Menu, X, LogOut, LayoutDashboard, Layers, ChevronDown, ChevronRight, BarChart3, Database, CheckSquare } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

export default function Layout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [adminName, setAdminName] = useState('');
  const [managementOpen, setManagementOpen] = useState(false);
  const location = useLocation();
  const { logout } = useAuth();

  useEffect(() => {
    // Get admin name from localStorage
    const userStr = localStorage.getItem('adminUser');
    if (userStr) {
      const user = JSON.parse(userStr);
      setAdminName(`${user.first_name || ''} ${user.last_name || ''}`.trim() || user.username || 'Admin');
    }
  }, []);

  const menuItems = [
    { id: 'dashboard', path: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'analytics', path: '/dashboard/analytics', label: 'Analytics', icon: BarChart3 },
    { id: 'attendance', path: '/dashboard/attendance', label: 'Attendance', icon: CheckSquare },
    { id: 'trips', path: '/dashboard/trips', label: 'Trips & Tracking', icon: MapPin },
    { id: 'assignments', path: '/dashboard/assignments', label: 'Assignments', icon: Layers },
    { id: 'admins', path: '/dashboard/admins', label: 'Admins', icon: Shield },
  ];

  const managementItems = [
    { id: 'children', path: '/dashboard/children', label: 'Children', icon: Baby },
    { id: 'parents', path: '/dashboard/parents', label: 'Parents', icon: Users },
    { id: 'buses', path: '/dashboard/buses', label: 'Buses', icon: Bus },
    { id: 'drivers', path: '/dashboard/drivers', label: 'Drivers', icon: UserCircle },
    { id: 'minders', path: '/dashboard/minders', label: 'Bus Minders', icon: UserCircle },
  ];

  // Check if any management item is active
  const isManagementActive = managementItems.some(item => location.pathname === item.path);

  // Auto-open management menu if a management route is active
  useEffect(() => {
    if (isManagementActive) {
      setManagementOpen(true);
    }
  }, [isManagementActive]);

  return (
    <div className="min-h-screen bg-slate-50">
      <div className="fixed top-0 left-0 right-0 h-16 bg-white border-b border-slate-200 z-20 flex items-center justify-between px-4 md:px-6">
        <div className="flex items-center">
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="md:hidden mr-4 p-2 hover:bg-slate-100 rounded-lg"
          >
            {sidebarOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
          <img src="/logo.svg" alt="ApoBasi" className="w-8 h-8 mr-3" />
          <h1 className="text-xl font-bold text-slate-900">ApoBasi</h1>
        </div>
        <div className="flex items-center gap-4">
          {adminName && (
            <div className="hidden md:flex items-center gap-2 px-3 py-1 bg-blue-50 rounded-lg">
              <UserCircle size={20} className="text-blue-600" />
              <span className="text-sm font-medium text-slate-700">{adminName}</span>
            </div>
          )}
          <button
            onClick={logout}
            className="flex items-center gap-2 px-4 py-2 text-slate-700 hover:bg-slate-100 rounded-lg transition-colors"
          >
            <LogOut size={20} />
            <span className="hidden md:inline">Logout</span>
          </button>
        </div>
      </div>

      <div className="flex pt-16">
        <aside
          className={`fixed left-0 top-16 h-[calc(100vh-4rem)] w-64 bg-white border-r border-slate-200 z-10 transition-transform md:translate-x-0 ${
            sidebarOpen ? 'translate-x-0' : '-translate-x-full'
          }`}
        >
          <nav className="p-4 space-y-1">
            {menuItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path;
              return (
                <Link
                  key={item.id}
                  to={item.path}
                  onClick={() => setSidebarOpen(false)}
                  className={`w-full flex items-center px-4 py-3 rounded-lg text-left transition-colors ${
                    isActive
                      ? 'bg-blue-50 text-blue-700 font-medium'
                      : 'text-slate-700 hover:bg-slate-50'
                  }`}
                >
                  <Icon size={20} className="mr-3" />
                  {item.label}
                </Link>
              );
            })}

            {/* Management Collapsible Menu */}
            <div className="mt-1">
              <button
                onClick={() => setManagementOpen(!managementOpen)}
                className={`w-full flex items-center justify-between px-4 py-3 rounded-lg text-left transition-colors ${
                  isManagementActive
                    ? 'bg-blue-50 text-blue-700 font-medium'
                    : 'text-slate-700 hover:bg-slate-50'
                }`}
              >
                <div className="flex items-center">
                  <Database size={20} className="mr-3" />
                  Management
                </div>
                {managementOpen ? (
                  <ChevronDown size={16} />
                ) : (
                  <ChevronRight size={16} />
                )}
              </button>

              {/* Nested Management Items */}
              {managementOpen && (
                <div className="ml-4 mt-1 space-y-1 border-l-2 border-slate-200 pl-2">
                  {managementItems.map((item) => {
                    const Icon = item.icon;
                    const isActive = location.pathname === item.path;
                    return (
                      <Link
                        key={item.id}
                        to={item.path}
                        onClick={() => setSidebarOpen(false)}
                        className={`w-full flex items-center px-4 py-2.5 rounded-lg text-left transition-colors text-sm ${
                          isActive
                            ? 'bg-blue-50 text-blue-700 font-medium'
                            : 'text-slate-600 hover:bg-slate-50'
                        }`}
                      >
                        <Icon size={18} className="mr-3" />
                        {item.label}
                      </Link>
                    );
                  })}
                </div>
              )}
            </div>
          </nav>
        </aside>

        <main className="flex-1 md:ml-64 p-4 md:p-6">
          <div className="max-w-7xl mx-auto">
            <Outlet />
          </div>
        </main>
      </div>

      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-[5] md:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}
    </div>
  );
}
