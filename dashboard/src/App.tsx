import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth } from './context/AuthContext';
import DashboardLayout from './components/layout/DashboardLayout';
import LoginPage from './pages/auth/LoginPage';
import RegisterPage from './pages/auth/RegisterPage';
import DashboardPage from './pages/dashboard/DashboardPage';
import RestaurantsPage from './pages/restaurants/RestaurantsPage';
import RestaurantFormPage from './pages/restaurants/RestaurantFormPage';
import RestaurantDetailPage from './pages/restaurants/RestaurantDetailPage';
import StaffPage from './pages/restaurants/StaffPage';
import ProfilePage from './pages/auth/ProfilePage';
import OrdersPage from './pages/orders/OrdersPage';
import MenuPage from './pages/menu/MenuPage';
import PromotionsPage from './pages/promotions/PromotionsPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
      </div>
    );
  }

  return isAuthenticated ? <>{children}</> : <Navigate to="/login" replace />;
}

function PublicRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
      </div>
    );
  }

  return !isAuthenticated ? <>{children}</> : <Navigate to="/" replace />;
}

function AppRoutes() {
  return (
    <Routes>
      {/* Public routes */}
      <Route
        path="/login"
        element={
          <PublicRoute>
            <LoginPage />
          </PublicRoute>
        }
      />
      <Route
        path="/register"
        element={
          <PublicRoute>
            <RegisterPage />
          </PublicRoute>
        }
      />

      {/* Protected routes */}
      <Route
        path="/"
        element={
          <PrivateRoute>
            <DashboardLayout />
          </PrivateRoute>
        }
      >
        <Route index element={<DashboardPage />} />
        <Route path="profile" element={<ProfilePage />} />
        <Route path="restaurants" element={<RestaurantsPage />} />
        <Route path="restaurants/new" element={<RestaurantFormPage />} />
        <Route path="restaurants/:id" element={<RestaurantDetailPage />} />
        <Route path="restaurants/:id/edit" element={<RestaurantFormPage />} />
        <Route path="restaurants/:id/staff" element={<StaffPage />} />
        <Route path="orders" element={<OrdersPage />} />
        <Route path="restaurants/:restaurantId/orders" element={<OrdersPage />} />
        <Route path="menu" element={<MenuPage />} />
        <Route path="promotions" element={<PromotionsPage />} />
      </Route>

      {/* Redirect unknown routes */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
