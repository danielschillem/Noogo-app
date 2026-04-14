// Types pour l'application Noogo Dashboard

export interface User {
  id: number;
  name: string;
  email: string;
  phone?: string;
  is_admin: boolean;
  created_at: string;
}

export type StaffRole = 'owner' | 'manager' | 'cashier' | 'waiter';

export const STAFF_ROLE_LABELS: Record<StaffRole, string> = {
  owner: 'Propriétaire',
  manager: 'Gérant',
  cashier: 'Caissier',
  waiter: 'Serveur',
};

export const STAFF_ROLE_COLORS: Record<StaffRole, string> = {
  owner: 'bg-purple-100 text-purple-700',
  manager: 'bg-blue-100 text-blue-700',
  cashier: 'bg-green-100 text-green-700',
  waiter: 'bg-orange-100 text-orange-700',
};

export interface StaffMember {
  id: number;
  user_id: number;
  name: string;
  email: string;
  phone?: string;
  role: StaffRole;
  role_label: string;
  permissions: string[];
  is_active: boolean;
  created_at: string;
}

export interface MyRestaurant {
  id: number;
  nom: string;
  logo?: string;
  adresse: string;
  is_active: boolean;
  role: StaffRole;
  role_label: string;
  permissions: string[];
}

export interface Restaurant {
  id: number;
  user_id: number;
  nom: string;
  telephone: string;
  adresse: string;
  email?: string;
  logo?: string;
  logo_url?: string;
  description?: string;
  heures_ouverture?: string;
  images?: string[];
  is_active: boolean;
  is_open: boolean;
  is_open_override?: boolean | null;
  latitude?: number | null;
  longitude?: number | null;
  qr_code?: string;
  created_at: string;
  categories_count?: number;
  dishes_count?: number;
  orders_count?: number;
}

export interface Category {
  id: number;
  restaurant_id: number;
  nom: string;
  description?: string;
  image?: string;
  image_url?: string;
  ordre: number;
  is_active: boolean;
  dishes_count?: number;
}

export interface Dish {
  id: number;
  restaurant_id: number;
  category_id: number;
  nom: string;
  description?: string;
  prix: number;
  images?: string[];
  image_url?: string;
  disponibilite: boolean;
  is_plat_du_jour: boolean;
  temps_preparation: number;
  ordre: number;
  formatted_price: string;
  categorie: string;
}

export interface OrderItem {
  id: number;
  order_id: number;
  dish_id: number;
  quantity: number;
  unit_price: number;
  total_price: number;
  special_instructions?: string;
  dish?: Dish;
}

export interface Order {
  id: number;
  restaurant_id: number;
  user_id?: number;
  customer_name?: string;
  customer_phone?: string;
  status: OrderStatus;
  order_type: OrderType;
  table_number?: string;
  total_amount: number;
  payment_method: string;
  transaction_id?: string;
  mobile_money_provider?: string;
  notes?: string;
  order_date: string;
  items: OrderItem[];
  status_text: string;
  order_type_text: string;
  formatted_total: string;
  restaurant?: Restaurant;
}

export type OrderStatus =
  | 'pending'
  | 'confirmed'
  | 'preparing'
  | 'ready'
  | 'delivered'
  | 'completed'
  | 'cancelled';

export type OrderType = 'sur_place' | 'a_emporter' | 'livraison';

export interface FlashInfo {
  id: number;
  restaurant_id: number;
  titre: string;
  description?: string;
  image?: string;
  image_url?: string;
  type: 'promotion' | 'info' | 'event' | 'offre';
  reduction_percentage?: number;
  prix_special?: number;
  date_debut?: string;
  date_fin?: string;
  is_active: boolean;
  is_valid: boolean;
}

export interface DashboardStats {
  today: {
    orders: number;
    revenue: number;
    pending_orders: number;
  };
  this_month: {
    orders: number;
    revenue: number;
    completed_orders: number;
  };
  last_month: {
    orders: number;
    revenue: number;
  };
  growth: {
    orders: number;
    revenue: number;
  };
  total_restaurants: number;
  total_dishes: number;
  active_dishes: number;
}

export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data: T;
  errors?: Record<string, string[]>;
}

export interface PaginatedResponse<T> {
  data: T[];
  current_page: number;
  last_page: number;
  per_page: number;
  total: number;
}

export interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}
