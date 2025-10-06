import { ReactNode, useState, useEffect } from 'react';
import { Bus, Users, Baby, CircleUser as UserCircle, MapPin, Shield, Menu, X, LogOut } from 'lucide-react';

interface LayoutProps {
  children: ReactNode;
  currentPage: string;
  onNavigate: (page: string) => void;
  onLogout: () => void;
}

export default function Layout({ children, currentPage, onNavigate, onLogout }: LayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [adminName, setAdminName] = useState('');

  useEffect(() => {
    // Get admin name from localStorage
    const userStr = localStorage.getItem('adminUser');
    if (userStr) {
      const user = JSON.parse(userStr);
      setAdminName(`${user.first_name} ${user.last_name}`);
    }
  }, []);

  const menuItems = [
    { id: 'children', label: 'Children', icon: Baby },
    { id: 'parents', label: 'Parents', icon: Users },
    { id: 'buses', label: 'Buses', icon: Bus },
    { id: 'drivers', label: 'Drivers', icon: UserCircle },
    { id: 'minders', label: 'Bus Minders', icon: UserCircle },
    { id: 'trips', label: 'Trips & Tracking', icon: MapPin },
    { id: 'admins', label: 'Admins', icon: Shield },
  ];

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
          <Bus className="text-blue-600 mr-3" size={28} />
          <h1 className="text-xl font-bold text-slate-900">AppBasi Admin</h1>
        </div>
        <div className="flex items-center gap-4">
          {adminName && (
            <div className="hidden md:flex items-center gap-2 px-3 py-1 bg-blue-50 rounded-lg">
              <UserCircle size={20} className="text-blue-600" />
              <span className="text-sm font-medium text-slate-700">{adminName}</span>
            </div>
          )}
          <button
            onClick={onLogout}
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
              const isActive = currentPage === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => {
                    onNavigate(item.id);
                    setSidebarOpen(false);
                  }}
                  className={`w-full flex items-center px-4 py-3 rounded-lg text-left transition-colors ${
                    isActive
                      ? 'bg-blue-50 text-blue-700 font-medium'
                      : 'text-slate-700 hover:bg-slate-50'
                  }`}
                >
                  <Icon size={20} className="mr-3" />
                  {item.label}
                </button>
              );
            })}
          </nav>
        </aside>

        <main className="flex-1 md:ml-64 p-4 md:p-6">
          <div className="max-w-7xl mx-auto">{children}</div>
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
