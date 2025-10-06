import { useState, useEffect } from 'react';
import Layout from './components/Layout';
import ChildrenPage from './pages/ChildrenPage';
import ParentsPage from './pages/ParentsPage';
import BusesPage from './pages/BusesPage';
import DriversPage from './pages/DriversPage';
import MindersPage from './pages/MindersPage';
import TripsPage from './pages/TripsPage';
import AdminsPage from './pages/AdminsPage';
import AuthPage from './pages/AuthPage';

function App() {
  const [currentPage, setCurrentPage] = useState('children');
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    // Check authentication on mount
    const token = localStorage.getItem('adminToken');
    setIsAuthenticated(!!token);
  }, []);

  const handleLogin = () => {
    setIsAuthenticated(true);
  };

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    setIsAuthenticated(false);
  };

  // Show auth page if not authenticated
  if (!isAuthenticated) {
    return <AuthPage onLogin={handleLogin} />;
  }

  const renderPage = () => {
    switch (currentPage) {
      case 'children':
        return <ChildrenPage />;
      case 'parents':
        return <ParentsPage />;
      case 'buses':
        return <BusesPage />;
      case 'drivers':
        return <DriversPage />;
      case 'minders':
        return <MindersPage />;
      case 'trips':
        return <TripsPage />;
      case 'admins':
        return <AdminsPage />;
      default:
        return <ChildrenPage />;
    }
  };

  return (
    <Layout currentPage={currentPage} onNavigate={setCurrentPage} onLogout={handleLogout}>
      {renderPage()}
    </Layout>
  );
}

export default App;
