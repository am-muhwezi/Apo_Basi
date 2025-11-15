import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

interface PrivateRouteProps {
  children: React.ReactNode;
}

/**
 * PrivateRoute Component
 *
 * Protects routes that require authentication.
 * If user is not authenticated, redirects to login page.
 *
 * Usage:
 * <Route path="/dashboard" element={
 *   <PrivateRoute>
 *     <DashboardPage />
 *   </PrivateRoute>
 * } />
 */
export default function PrivateRoute({ children }: PrivateRouteProps) {
  const { isAuthenticated, loading } = useAuth();

  // Show loading spinner while checking authentication
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  // Redirect to login if not authenticated
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  // Render protected component
  return <>{children}</>;
}
