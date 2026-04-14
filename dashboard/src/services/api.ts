import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || '/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Interceptor pour ajouter le token d'auth
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Interceptor pour gérer les erreurs
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('auth_token');
      localStorage.removeItem('user');
      window.location.href = '/login';
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
};

// Dashboard API
export const dashboardApi = {
  getStats: () => api.get('/dashboard'),
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

export default api;
