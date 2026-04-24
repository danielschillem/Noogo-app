import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || '/api';

const api = axios.create({
  baseURL: API_URL,
  timeout: 60000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Interceptor pour ajouter le token d'auth
api.interceptors.request.use(
  (config) => {
    const token = sessionStorage.getItem('auth_token') ?? localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Interceptor pour gérer les erreurs
let _redirectingToLogin = false;
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const is401 = error.response?.status === 401;
    const isAuthEndpoint = error.config?.url?.includes('/auth/');
    const alreadyOnLogin = window.location.pathname === '/login' || window.location.pathname.endsWith('/login');

    // Redirige vers /login uniquement si :
    //  - c'est un 401 sur un endpoint non-auth (ex: /dashboard, /restaurants…)
    //  - on n'est pas déjà sur /login (évite la boucle refresh)
    //  - pas déjà en cours de redirection
    if (is401 && !isAuthEndpoint && !alreadyOnLogin && !_redirectingToLogin) {
      _redirectingToLogin = true;
      sessionStorage.removeItem('auth_token');
      sessionStorage.removeItem('user');
      localStorage.removeItem('auth_token');
      localStorage.removeItem('user');
      // Si l'utilisateur était sur une page restaurant verrouillée, on le redirige vers ce login
      const lockedId = localStorage.getItem('locked_restaurant_id');
      localStorage.removeItem('locked_restaurant_id');
      if (lockedId) {
        window.location.href = `/r/${lockedId}/login`;
      } else {
        window.location.href = '/login';
      }
    } else if (is401 && isAuthEndpoint) {
      // Pour /auth/me, /auth/refresh etc. : juste nettoyer le storage
      // AuthContext gère la redirection proprement
      sessionStorage.removeItem('auth_token');
      sessionStorage.removeItem('user');
      localStorage.removeItem('auth_token');
      localStorage.removeItem('user');
    }
    return Promise.reject(error);
  }
);

// Auth API
export const authApi = {
  login: (email: string, password: string) =>
    api.post('/auth/login', { email, password }),
  register: (data: { name: string; email: string; password: string; password_confirmation: string }) =>
    api.post('/auth/register', data),
  logout: () => api.post('/auth/logout'),
  me: () => api.get('/auth/me'),
  updateUser: (data: { name?: string; email?: string }) => api.put('/auth/user/update', data),
  forgotPassword: (email: string) =>
    api.post('/auth/forgot-password', { email }),
  resetPassword: (data: { token: string; password: string; password_confirmation: string }) =>
    api.post('/auth/reset-password', data),
  changePassword: (data: { current_password: string; password: string; password_confirmation: string }) =>
    api.post('/auth/change-password', data),
};

// Dashboard API
export const dashboardApi = {
  getStats: () => api.get('/dashboard'),
  getPendingCount: () => api.get('/dashboard/pending-count'),
  getRecentOrders: (limit = 10) => api.get(`/dashboard/recent-orders?limit=${limit}`),
  getOrdersChart: (days = 7) => api.get(`/dashboard/orders-chart?days=${days}`),
  getRevenueChart: (months = 6) => api.get(`/dashboard/revenue-chart?months=${months}`),
  getTopDishes: (limit = 5) => api.get(`/dashboard/top-dishes?limit=${limit}`),
};

// Restaurants API
export const restaurantsApi = {
  getAll: (params?: Record<string, unknown>) => api.get('/restaurants', { params }),
  getById: (id: number) => api.get(`/restaurants/${id}`),
  create: (data: FormData) => api.post('/restaurants', data, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  update: (id: number, data: FormData) => api.post(`/restaurants/${id}?_method=PUT`, data, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  delete: (id: number) => api.delete(`/restaurants/${id}`),
  toggleActive: (id: number) => api.post(`/restaurants/${id}/toggle-active`),
  toggleOpen: (id: number) => api.post(`/restaurants/${id}/toggle-open`),
  getStatistics: (id: number) => api.get(`/restaurants/${id}/statistics`),
  generateQrCode: (id: number) => api.post(`/restaurants/${id}/generate-qr`),
};

// Categories API
export const categoriesApi = {
  getAll: (restaurantId: number) => api.get(`/restaurants/${restaurantId}/categories`),
  getById: (restaurantId: number, id: number) => api.get(`/restaurants/${restaurantId}/categories/${id}`),
  create: (restaurantId: number, data: FormData) => api.post(`/restaurants/${restaurantId}/categories`, data, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  update: (restaurantId: number, id: number, data: FormData) =>
    api.post(`/restaurants/${restaurantId}/categories/${id}?_method=PUT`, data, {
      headers: { 'Content-Type': 'multipart/form-data' }
    }),
  delete: (restaurantId: number, id: number) => api.delete(`/restaurants/${restaurantId}/categories/${id}`),
  reorder: (restaurantId: number, categories: { id: number; ordre: number }[]) =>
    api.post(`/restaurants/${restaurantId}/categories/reorder`, { categories }),
  toggleActive: (restaurantId: number, id: number) =>
    api.post(`/restaurants/${restaurantId}/categories/${id}/toggle-active`),
};

// Dishes API
export const dishesApi = {
  getAll: (restaurantId: number, params?: Record<string, unknown>) =>
    api.get(`/restaurants/${restaurantId}/dishes`, { params }),
  getById: (restaurantId: number, id: number) => api.get(`/restaurants/${restaurantId}/dishes/${id}`),
  create: (restaurantId: number, data: FormData) => api.post(`/restaurants/${restaurantId}/dishes`, data, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }),
  update: (restaurantId: number, id: number, data: FormData) =>
    api.post(`/restaurants/${restaurantId}/dishes/${id}?_method=PUT`, data, {
      headers: { 'Content-Type': 'multipart/form-data' }
    }),
  delete: (restaurantId: number, id: number) => api.delete(`/restaurants/${restaurantId}/dishes/${id}`),
  toggleAvailability: (restaurantId: number, id: number) =>
    api.post(`/restaurants/${restaurantId}/dishes/${id}/toggle-availability`),
  togglePlatDuJour: (restaurantId: number, id: number) =>
    api.post(`/restaurants/${restaurantId}/dishes/${id}/toggle-plat-du-jour`),
  getPlatsDuJour: (restaurantId: number) => api.get(`/restaurants/${restaurantId}/plats-du-jour`),
  reorder: (restaurantId: number, dishes: { id: number; ordre: number }[]) =>
    api.post(`/restaurants/${restaurantId}/dishes/reorder`, { dishes }),
};

// Orders API
export const ordersApi = {
  getAll: (restaurantId: number, params?: Record<string, unknown>) =>
    api.get(`/restaurants/${restaurantId}/orders`, { params }),
  getById: (restaurantId: number, id: number) => api.get(`/restaurants/${restaurantId}/orders/${id}`),
  create: (restaurantId: number, data: Record<string, unknown>) =>
    api.post(`/restaurants/${restaurantId}/orders`, data),
  updateStatus: (restaurantId: number, id: number, status: string) =>
    api.patch(`/restaurants/${restaurantId}/orders/${id}/status`, { status }),
  cancel: (restaurantId: number, id: number) =>
    api.post(`/restaurants/${restaurantId}/orders/${id}/cancel`),
  getStatistics: (restaurantId: number, params?: { from?: string; to?: string }) =>
    api.get(`/restaurants/${restaurantId}/orders-statistics`, { params }),
  getPendingCount: (restaurantId: number) =>
    api.get(`/restaurants/${restaurantId}/orders-pending-count`),
};

// Bloc note — commandes orales (menu par catégorie, validation avec snapshot)
export const oralOrderNotesApi = {
  list: (restaurantId: number, params?: { status?: string; page?: number; per_page?: number }) =>
    api.get(`/restaurants/${restaurantId}/oral-order-notes`, { params }),
  create: (restaurantId: number, data?: { title?: string; staff_comment?: string }) =>
    api.post(`/restaurants/${restaurantId}/oral-order-notes`, data ?? {}),
  get: (restaurantId: number, id: number) =>
    api.get(`/restaurants/${restaurantId}/oral-order-notes/${id}`),
  update: (restaurantId: number, id: number, data: {
    title?: string | null;
    staff_comment?: string | null;
    items?: { dish_id: number; quantity: number }[];
  }) => api.patch(`/restaurants/${restaurantId}/oral-order-notes/${id}`, data),
  validate: (restaurantId: number, id: number) =>
    api.post(`/restaurants/${restaurantId}/oral-order-notes/${id}/validate`),
  convertToOrder: (restaurantId: number, id: number, data: {
    order_type: 'sur_place' | 'a_emporter' | 'livraison';
    payment_method: string;
    mobile_money_provider?: string;
    customer_name?: string;
    customer_phone?: string;
    table_number?: string;
    notes?: string;
  }) => api.post(`/restaurants/${restaurantId}/oral-order-notes/${id}/convert-to-order`, data),
  remove: (restaurantId: number, id: number) =>
    api.delete(`/restaurants/${restaurantId}/oral-order-notes/${id}`),
};

// Flash Infos API
export const flashInfosApi = {
  getAll: (restaurantId: number, params?: Record<string, unknown>) =>
    api.get(`/restaurants/${restaurantId}/flash-infos`, { params }),
  getById: (restaurantId: number, id: number) =>
    api.get(`/restaurants/${restaurantId}/flash-infos/${id}`),
  create: (restaurantId: number, data: FormData) =>
    api.post(`/restaurants/${restaurantId}/flash-infos`, data, {
      headers: { 'Content-Type': 'multipart/form-data' }
    }),
  update: (restaurantId: number, id: number, data: FormData) =>
    api.post(`/restaurants/${restaurantId}/flash-infos/${id}?_method=PUT`, data, {
      headers: { 'Content-Type': 'multipart/form-data' }
    }),
  delete: (restaurantId: number, id: number) =>
    api.delete(`/restaurants/${restaurantId}/flash-infos/${id}`),
  toggleActive: (restaurantId: number, id: number) =>
    api.post(`/restaurants/${restaurantId}/flash-infos/${id}/toggle-active`),
};

// Coupons API
export const couponsApi = {
  getAll: (restaurantId: number) =>
    api.get(`/restaurants/${restaurantId}/coupons`),
  create: (restaurantId: number, data: {
    code: string; type: 'percentage' | 'fixed'; value: number;
    min_order?: number; max_discount?: number; max_uses?: number;
    starts_at?: string; expires_at?: string; is_active?: boolean;
  }) => api.post(`/restaurants/${restaurantId}/coupons`, data),
  update: (restaurantId: number, id: number, data: Partial<{
    code: string; type: 'percentage' | 'fixed'; value: number;
    min_order: number | null; max_discount: number | null; max_uses: number | null;
    starts_at: string | null; expires_at: string | null; is_active: boolean;
  }>) => api.put(`/restaurants/${restaurantId}/coupons/${id}`, data),
  delete: (restaurantId: number, id: number) =>
    api.delete(`/restaurants/${restaurantId}/coupons/${id}`),
  toggleActive: (restaurantId: number, id: number) =>
    api.post(`/restaurants/${restaurantId}/coupons/${id}/toggle-active`),
};

// Staff API
export const staffApi = {
  getAll: (restaurantId: number) =>
    api.get(`/restaurants/${restaurantId}/staff`),
  create: (restaurantId: number, data: {
    name: string; email: string; phone?: string;
    role: string; password?: string;
  }) => api.post(`/restaurants/${restaurantId}/staff`, data),
  update: (restaurantId: number, staffId: number, data: {
    role?: string; is_active?: boolean;
  }) => api.put(`/restaurants/${restaurantId}/staff/${staffId}`, data),
  remove: (restaurantId: number, staffId: number) =>
    api.delete(`/restaurants/${restaurantId}/staff/${staffId}`),
};

// My restaurants (pour les non-admins)
export const myRestaurantsApi = {
  get: () => api.get('/auth/my-restaurants'),
};

// Portal API — endpoints publics (aucune auth requise), pour la page de connexion restaurant
// Instance axios sans intercepteur auth pour ne pas envoyer de token
const publicApi = axios.create({
  baseURL: API_URL,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
});

export const portalApi = {
  /** Liste des restaurants actifs (id, nom, logo, adresse) */
  listRestaurants: () => publicApi.get('/portal/restaurants'),
  /** Détail d'un restaurant sans auth (id, nom, logo, adresse, telephone) */
  getRestaurant: (id: number) => publicApi.get(`/portal/restaurants/${id}`),
};

// Admin API (super admin only)
export const adminApi = {
  getStats: () => api.get('/admin/stats'),

  // Users
  listUsers: (params?: { search?: string; page?: number; per_page?: number; is_admin?: boolean }) =>
    api.get('/admin/users', { params }),
  createUser: (data: { name: string; email: string; phone?: string; password: string; is_admin?: boolean }) =>
    api.post('/admin/users', data),
  updateUser: (id: number, data: { name?: string; email?: string; phone?: string; is_admin?: boolean; password?: string }) =>
    api.put(`/admin/users/${id}`, data),
  deleteUser: (id: number) => api.delete(`/admin/users/${id}`),
  toggleAdmin: (id: number) => api.post(`/admin/users/${id}/toggle-admin`),

  // Restaurants
  listRestaurants: (params?: { search?: string; page?: number; per_page?: number; is_active?: boolean }) =>
    api.get('/admin/restaurants', { params }),
  toggleRestaurantActive: (id: number) => api.post(`/admin/restaurants/${id}/toggle-active`),
  updateRestaurantLicense: (id: number, data: {
    license_plan?: string | null;
    license_status: 'active' | 'suspended' | 'expired' | 'trial';
    license_expires_at?: string | null;
    license_max_staff?: number | null;
  }) => api.put(`/admin/restaurants/${id}/license`, data),
  listAuditLogs: (params?: { action?: string; target_type?: string; page?: number; per_page?: number }) =>
    api.get('/admin/audit-logs', { params }),
};

// Delivery API
export const deliveryApi = {
  // Deliveries (admin)
  getAll: (params?: { status?: string; driver_id?: number; page?: number }) =>
    api.get('/admin/deliveries', { params }),
  getRestaurantDeliveries: (restaurantId: number, params?: { status?: string; driver_id?: number; page?: number }) =>
    api.get(`/restaurants/${restaurantId}/deliveries`, { params }),
  getById: (id: number) => api.get(`/deliveries/${id}`),
  requestDelivery: (orderId: number, data: {
    client_lat?: number; client_lng?: number; client_address?: string; fee?: number; notes?: string;
  }) => api.post(`/orders/${orderId}/request-delivery`, data),
  assign: (deliveryId: number, driverIdValue: number) =>
    api.post(`/deliveries/${deliveryId}/assign`, { delivery_driver_id: driverIdValue }),
  updateStatus: (deliveryId: number, status: string, failureReason?: string) =>
    api.patch(`/deliveries/${deliveryId}/status`, { status, failure_reason: failureReason }),

  // Drivers (admin)
  getDrivers: (params?: { status?: string; zone?: string; search?: string; page?: number }) =>
    api.get('/admin/drivers', { params }),
  getRestaurantAvailableDrivers: (restaurantId: number, params?: { zone?: string; search?: string; page?: number }) =>
    api.get(`/restaurants/${restaurantId}/drivers/available`, { params }),
  createDriver: (data: { name: string; phone: string; zone?: string; user_id?: number }) =>
    api.post('/admin/drivers', data),
  registerDriver: (data: { name: string; telephone: string; password: string; password_confirmation: string; zone?: string }) =>
    api.post('/admin/auth/register-driver', data),
  updateDriver: (id: number, data: { name?: string; phone?: string; zone?: string; status?: string }) =>
    api.put(`/admin/drivers/${id}`, data),
  deleteDriver: (id: number) => api.delete(`/admin/drivers/${id}`),
};

// Ratings API
export const ratingsApi = {
  getAll: (restaurantId: number, params?: { page?: number; per_page?: number }) =>
    api.get(`/restaurants/${restaurantId}/ratings`, { params }),
};

export default api;
