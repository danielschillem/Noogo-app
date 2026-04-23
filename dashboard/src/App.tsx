import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth } from './context/AuthContext';
import { NotificationProvider } from './context/NotificationContext';
import DashboardLayout from './components/layout/DashboardLayout';
import RestaurantLayout from './components/layout/RestaurantLayout';
import LoginPage from './pages/auth/LoginPage';
import RegisterPage from './pages/auth/RegisterPage';
import RestaurantLoginPage from './pages/auth/RestaurantLoginPage';
import PortalLoginPage from './pages/auth/PortalLoginPage';
import DashboardPage from './pages/dashboard/DashboardPage';
import RestaurantsPage from './pages/restaurants/RestaurantsPage';
import RestaurantFormPage from './pages/restaurants/RestaurantFormPage';
import RestaurantDetailPage from './pages/restaurants/RestaurantDetailPage';
import StaffPage from './pages/restaurants/StaffPage';
import ProfilePage from './pages/auth/ProfilePage';
import OrdersPage from './pages/orders/OrdersPage';
import MenuPage from './pages/menu/MenuPage';
import PromotionsPage from './pages/promotions/PromotionsPage';
import ForgotPasswordPage from './pages/auth/ForgotPasswordPage';
import ResetPasswordPage from './pages/auth/ResetPasswordPage';
import AdminPage from './pages/admin/AdminPage';
import KitchenPage from './pages/restaurants/KitchenPage';
import DriversPage from './pages/delivery/DriversPage';
import DeliveriesPage from './pages/delivery/DeliveriesPage';
import RatingsPage from './pages/ratings/RatingsPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading, lockedRestaurantId } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
      </div>
    );
  }

  if (!isAuthenticated) return <Navigate to="/login" replace />;
  // Utilisateur verrouillé sur un restaurant → il ne peut pas accéder au dashboard global
  if (lockedRestaurantId) return <Navigate to={`/r/${lockedRestaurantId}/orders`} replace />;
  return <>{children}</>;
}

function AdminRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading, user } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
      </div>
    );
  }

  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (!user?.is_admin) return <Navigate to="/" replace />;
  return <>{children}</>;
}

function PublicRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading, lockedRestaurantId } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
      </div>
    );
  }

  if (isAuthenticated) {
    // Si l'utilisateur est verrouillé sur un restaurant → le renvoyer à son espace
    if (lockedRestaurantId) return <Navigate to={`/r/${lockedRestaurantId}/orders`} replace />;
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
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
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />
      <Route path="/reset-password" element={<ResetPasswordPage />} />

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
        <Route path="restaurants/:id/kitchen" element={<KitchenPage />} />
        <Route path="orders" element={<OrdersPage />} />
        <Route path="restaurants/:restaurantId/orders" element={<OrdersPage />} />
        <Route path="menu" element={<MenuPage />} />
        <Route path="promotions" element={<PromotionsPage />} />
        <Route path="ratings" element={<RatingsPage />} />
        <Route path="drivers" element={
          <AdminRoute>
            <DriversPage />
          </AdminRoute>
        } />
        <Route path="deliveries" element={
          <AdminRoute>
            <DeliveriesPage />
          </AdminRoute>
        } />
        <Route path="admin" element={
          <AdminRoute>
            <AdminPage />
          </AdminRoute>
        } />
      </Route>

      {/* Redirect unknown routes */}
      <Route path="*" element={<Navigate to="/" replace />} />

      {/* Routes restaurant isolées (/r/:restaurantId/*) */}
      {/* Login spécifique à un restaurant — public */}
      <Route path="/r/:restaurantId/login" element={<RestaurantLoginPage />} />

      {/* Portail général de connexion restaurant — choisir dans la liste */}
      <Route path="/portal" element={<PortalLoginPage />} />

      {/* Espace staff verrouillé — le RestaurantLayout gère l'isolation */}
      <Route path="/r/:restaurantId" element={<RestaurantLayout />}>
        <Route index element={<Navigate to="orders" replace />} />
        <Route path="orders" element={<OrdersPage />} />
        <Route path="kitchen" element={<KitchenPage />} />
        <Route path="menu" element={<MenuPage />} />
      </Route>
    </Routes>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AuthProvider>
          <NotificationProvider>
            <AppRoutes />
          </NotificationProvider>
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
