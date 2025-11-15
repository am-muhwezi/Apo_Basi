import { Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import PrivateRoute from './components/PrivateRoute';
import DashboardPage from './pages/DashboardPage';
import AnalyticsPage from './pages/AnalyticsPage';
import AttendancePage from './pages/AttendancePage';
import ChildrenPage from './pages/ChildrenPage';
import ParentsPage from './pages/ParentsPage';
import BusesPage from './pages/BusesPage';
import DriversPage from './pages/DriversPage';
import MindersPage from './pages/MindersPage';
import TripsPage from './pages/TripsPage';
import AdminsPage from './pages/AdminsPage';
import AssignmentsPage from './pages/AssignmentsPage';
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import { useAuth } from './contexts/AuthContext';

function App() {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <Routes>
      {/* Public routes */}
      <Route
        path="/login"
        element={isAuthenticated ? <Navigate to="/dashboard" replace /> : <LoginPage />}
      />
      <Route
        path="/signup"
        element={isAuthenticated ? <Navigate to="/dashboard" replace /> : <SignupPage />}
      />

      {/* Protected routes */}
      <Route
        path="/"
        element={
          <PrivateRoute>
            <Layout />
          </PrivateRoute>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<DashboardPage />} />
        <Route path="analytics" element={<AnalyticsPage />} />
        <Route path="attendance" element={<AttendancePage />} />
        <Route path="children" element={<ChildrenPage />} />
        <Route path="parents" element={<ParentsPage />} />
        <Route path="buses" element={<BusesPage />} />
        <Route path="drivers" element={<DriversPage />} />
        <Route path="minders" element={<MindersPage />} />
        <Route path="trips" element={<TripsPage />} />
        <Route path="assignments" element={<AssignmentsPage />} />
        <Route path="admins" element={<AdminsPage />} />
      </Route>

      {/* Catch all - redirect to dashboard or login */}
      <Route
        path="*"
        element={<Navigate to={isAuthenticated ? "/dashboard" : "/login"} replace />}
      />
    </Routes>
  );
}

export default App;
