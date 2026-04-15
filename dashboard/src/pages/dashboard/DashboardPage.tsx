import { useCallback, useEffect, useRef, useState } from 'react';
import {
  ShoppingBag,
  DollarSign,
  TrendingUp,
  Clock,
  ArrowUpRight,
  ArrowDownRight,
  Store,
  UtensilsCrossed,
  RefreshCw,
  Activity,
} from 'lucide-react';
import { dashboardApi, restaurantsApi } from '../../services/api';
import type { DashboardStats, Order, Restaurant } from '../../types';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Area,
  AreaChart,
} from 'recharts';

interface RestaurantStats {
  total_orders: number;
  orders_today: number;
  pending_orders: number;
  total_revenue: number;
  revenue_today: number;
  total_dishes: number;
  available_dishes: number;
  total_categories: number;
  active_promotions: number;
}

export default function DashboardPage() {
  // D9 — sélecteur restaurant
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [selectedRestaurantId, setSelectedRestaurantId] = useState<number | null>(null);
  const [restaurantStats, setRestaurantStats] = useState<RestaurantStats | null>(null);

  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [recentOrders, setRecentOrders] = useState<Order[]>([]);
  const [chartData, setChartData] = useState<{ date: string; label: string; orders: number; revenue: number }[]>([]);
  const [revenueData, setRevenueData] = useState<{ month: string; label: string; revenue: number; orders: number }[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    restaurantsApi.getAll().then(res => {
      const list: Restaurant[] = res.data.data?.data ?? res.data.data ?? [];
      setRestaurants(list);
    }).catch(console.error);
  }, []);

  // Quand un restaurant est sélectionné, charger ses stats individuelles
  useEffect(() => {
    if (!selectedRestaurantId) { setRestaurantStats(null); return; }
    restaurantsApi.getStatistics(selectedRestaurantId)
      .then(res => setRestaurantStats(res.data.data))
      .catch(console.error);
  }, [selectedRestaurantId]);

  const fetchData = useCallback(async (silent = false) => {
    try {
      if (!silent) setIsRefreshing(true);
      const [statsRes, ordersRes, chartRes, revenueRes] = await Promise.all([
        dashboardApi.getStats(),
        dashboardApi.getRecentOrders(5),
        dashboardApi.getOrdersChart(7),
        dashboardApi.getRevenueChart(6),
      ]);

      setStats(statsRes.data.data);
      setRecentOrders(ordersRes.data.data);
      setChartData(chartRes.data.data);
      setRevenueData(revenueRes.data.data);
      setLastUpdated(new Date());
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
    intervalRef.current = setInterval(() => fetchData(true), 30_000);
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, [fetchData]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'decimal',
      minimumFractionDigits: 0,
    }).format(amount) + ' FCFA';
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-12 h-12 rounded-2xl flex items-center justify-center animate-pulse"
            style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
            <Activity className="h-6 w-6 text-white" />
          </div>
          <p className="text-sm font-medium" style={{ color: '#64748b' }}>Chargement du dashboard…</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fadeIn">

      {/* ── Header ── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: '#0f172a' }}>Tableau de bord</h1>
          <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>
            Vue d'ensemble de votre activité
          </p>
        </div>
        <div className="flex items-center gap-2.5">
          {lastUpdated && (
            <span className="text-xs hidden sm:block px-3 py-1.5 rounded-lg"
              style={{ background: 'white', color: '#94a3b8', border: '1px solid #e2e8f0' }}>
              <span className="text-green-500 mr-1">●</span>
              {lastUpdated.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
            </span>
          )}
          <button
            onClick={() => fetchData()}
            disabled={isRefreshing}
            title="Actualiser"
            className="p-2.5 rounded-xl border disabled:opacity-50 transition-all hover:-translate-y-px"
            style={{ background: 'white', border: '1px solid #e2e8f0', color: '#64748b' }}>
            <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
          </button>
          {restaurants.length > 1 && (
            <div className="flex items-center gap-2 px-3 py-2 rounded-xl"
              style={{ background: 'white', border: '1px solid #e2e8f0' }}>
              <Store className="h-4 w-4 flex-shrink-0" style={{ color: '#94a3b8' }} />
              <select
                value={selectedRestaurantId ?? ''}
                onChange={e => setSelectedRestaurantId(e.target.value ? Number(e.target.value) : null)}
                className="text-sm bg-transparent border-none outline-none"
                style={{ color: '#374151' }}>
                <option value="">Tous les restaurants</option>
                {restaurants.map(r => <option key={r.id} value={r.id}>{r.nom}</option>)}
              </select>
            </div>
          )}
        </div>
      </div>

      {/* ── Stat Cards ── */}
      {selectedRestaurantId && restaurantStats ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <GradientStatCard title="Commandes aujourd'hui" value={restaurantStats.orders_today}
            icon={<ShoppingBag className="h-5 w-5" />} gradient="orange" />
          <GradientStatCard title="Revenus aujourd'hui" value={formatCurrency(restaurantStats.revenue_today)}
            icon={<DollarSign className="h-5 w-5" />} gradient="green" />
          <GradientStatCard title="En attente" value={restaurantStats.pending_orders}
            icon={<Clock className="h-5 w-5" />} gradient="violet" />
          <GradientStatCard title="Plats disponibles" value={`${restaurantStats.available_dishes}/${restaurantStats.total_dishes}`}
            icon={<UtensilsCrossed className="h-5 w-5" />} gradient="blue" />
          <GradientStatCard title="Total commandes" value={restaurantStats.total_orders}
            icon={<ShoppingBag className="h-5 w-5" />} gradient="orange" />
          <GradientStatCard title="Revenus totaux" value={formatCurrency(restaurantStats.total_revenue)}
            icon={<TrendingUp className="h-5 w-5" />} gradient="green" />
          <GradientStatCard title="Catégories" value={restaurantStats.total_categories}
            icon={<Store className="h-5 w-5" />} gradient="blue" />
          <GradientStatCard title="Promotions actives" value={restaurantStats.active_promotions}
            icon={<TrendingUp className="h-5 w-5" />} gradient="violet" />
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <GradientStatCard title="Commandes aujourd'hui" value={stats?.today.orders ?? 0}
            icon={<ShoppingBag className="h-5 w-5" />} gradient="orange" trend={stats?.growth.orders} />
          <GradientStatCard title="Revenus aujourd'hui" value={formatCurrency(stats?.today.revenue ?? 0)}
            icon={<DollarSign className="h-5 w-5" />} gradient="green" trend={stats?.growth.revenue} />
          <GradientStatCard title="En attente" value={stats?.today.pending_orders ?? 0}
            icon={<Clock className="h-5 w-5" />} gradient="violet" />
          <GradientStatCard title="Restaurants" value={stats?.total_restaurants ?? 0}
            icon={<Store className="h-5 w-5" />} gradient="blue" />
        </div>
      )}

      {/* ── Charts row ── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

        {/* Area chart — 7 jours */}
        <div className="lg:col-span-2 rounded-2xl p-6"
          style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="font-semibold text-base" style={{ color: '#0f172a' }}>Commandes</h2>
              <p className="text-xs mt-0.5" style={{ color: '#94a3b8' }}>7 derniers jours</p>
            </div>
            <div className="flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-lg"
              style={{ background: '#fff7ed', color: '#f97316' }}>
              <Activity className="h-3.5 w-3.5" /> Live
            </div>
          </div>
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData}>
                <defs>
                  <linearGradient id="ordersGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#f97316" stopOpacity={0.15} />
                    <stop offset="95%" stopColor="#f97316" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis dataKey="label" stroke="#cbd5e1" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#cbd5e1" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip
                  contentStyle={{
                    background: 'white', border: '1px solid #e2e8f0', borderRadius: 10,
                    boxShadow: '0 4px 20px rgba(0,0,0,0.08)', fontSize: 12
                  }}
                  cursor={{ stroke: '#f97316', strokeWidth: 1, strokeDasharray: '4 4' }}
                />
                <Area type="monotone" dataKey="orders" stroke="#f97316" strokeWidth={2.5}
                  fill="url(#ordersGrad)" dot={{ fill: '#f97316', r: 3, strokeWidth: 2, stroke: 'white' }}
                  activeDot={{ r: 5, stroke: 'white', strokeWidth: 2 }} name="Commandes" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Commandes récentes */}
        <div className="rounded-2xl p-6"
          style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <h2 className="font-semibold text-base mb-4" style={{ color: '#0f172a' }}>Commandes récentes</h2>
          <div className="space-y-3">
            {recentOrders.length > 0 ? recentOrders.map(order => (
              <div key={order.id} className="flex items-center justify-between py-2 border-b last:border-0"
                style={{ borderColor: '#f8fafc' }}>
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg flex items-center justify-center text-xs font-bold"
                    style={{ background: '#fff7ed', color: '#f97316' }}>
                    #{order.id}
                  </div>
                  <p className="text-xs font-medium truncate max-w-[80px]" style={{ color: '#374151' }}>
                    {order.customer_name || 'Client'}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-xs font-semibold" style={{ color: '#0f172a' }}>{order.formatted_total}</p>
                  <StatusBadge status={order.status} label={order.status_text} />
                </div>
              </div>
            )) : (
              <div className="flex flex-col items-center justify-center py-10 gap-2">
                <ShoppingBag className="h-8 w-8" style={{ color: '#c7d2fe' }} />
                <p className="text-xs" style={{ color: '#94a3b8' }}>Aucune commande</p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ── Revenue bar chart ── */}
      {revenueData.length > 0 && (
        <div className="rounded-2xl p-6"
          style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="font-semibold text-base" style={{ color: '#0f172a' }}>Revenus</h2>
              <p className="text-xs mt-0.5" style={{ color: '#94a3b8' }}>6 derniers mois</p>
            </div>
            <div className="flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-lg"
              style={{ background: '#f0fdf4', color: '#16a34a' }}>
              <TrendingUp className="h-3.5 w-3.5" /> FCFA
            </div>
          </div>
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={revenueData} barSize={32}>
                <defs>
                  <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#10b981" />
                    <stop offset="100%" stopColor="#059669" />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis dataKey="label" stroke="#cbd5e1" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#cbd5e1" fontSize={11} tickLine={false} axisLine={false}
                  tickFormatter={(v: number) => v >= 1000 ? `${(v / 1000).toFixed(0)}k` : String(v)} />
                <Tooltip
                  formatter={(v) => [`${new Intl.NumberFormat('fr-FR').format(Number(v))} FCFA`, 'Revenus']}
                  contentStyle={{
                    background: 'white', border: '1px solid #e2e8f0', borderRadius: 10,
                    boxShadow: '0 4px 20px rgba(0,0,0,0.08)', fontSize: 12
                  }}
                  cursor={{ fill: '#f8fafc' }}
                />
                <Bar dataKey="revenue" fill="url(#revenueGrad)" radius={[6, 6, 0, 0]} name="Revenus" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* ── Quick stats mini-cards ── */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
        <MiniStatCard icon={<UtensilsCrossed className="h-5 w-5" />} label="Total Plats"
          value={stats?.total_dishes ?? 0} color="#f97316" bg="#fff7ed" />
        <MiniStatCard icon={<TrendingUp className="h-5 w-5" />} label="Commandes ce mois"
          value={stats?.this_month.orders ?? 0} color="#10b981" bg="#f0fdf4" />
        <MiniStatCard icon={<DollarSign className="h-5 w-5" />} label="Revenus ce mois"
          value={formatCurrency(stats?.this_month.revenue ?? 0)} color="#3b82f6" bg="#eff6ff" />
      </div>
    </div>
  );
}

/* ── GradientStatCard ─────────────────────────────────────────── */
const GRADIENTS = {
  orange: 'linear-gradient(135deg,#ff6b35 0%,#f97316 50%,#fb923c 100%)',
  green: 'linear-gradient(135deg,#059669 0%,#10b981 50%,#34d399 100%)',
  blue: 'linear-gradient(135deg,#2563eb 0%,#3b82f6 50%,#60a5fa 100%)',
  violet: 'linear-gradient(135deg,#7c3aed 0%,#8b5cf6 50%,#a78bfa 100%)',
};

interface GradientStatCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  gradient: keyof typeof GRADIENTS;
  trend?: number;
}

function GradientStatCard({ title, value, icon, gradient, trend }: GradientStatCardProps) {
  return (
    <div className="relative overflow-hidden rounded-2xl p-5 text-white"
      style={{ background: GRADIENTS[gradient], boxShadow: '0 4px 20px rgba(0,0,0,0.12)' }}>
      {/* Decorative circle */}
      <div className="absolute -top-4 -right-4 w-24 h-24 rounded-full opacity-20"
        style={{ background: 'rgba(255,255,255,0.3)' }} />
      <div className="absolute -bottom-6 -right-2 w-16 h-16 rounded-full opacity-10"
        style={{ background: 'rgba(255,255,255,0.5)' }} />

      <div className="relative">
        <div className="flex items-center justify-between mb-3">
          <div className="p-2 rounded-xl" style={{ background: 'rgba(255,255,255,0.2)' }}>
            {icon}
          </div>
          {trend !== undefined && (
            <div className="flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-lg"
              style={{ background: 'rgba(255,255,255,0.2)' }}>
              {trend >= 0
                ? <ArrowUpRight className="h-3.5 w-3.5" />
                : <ArrowDownRight className="h-3.5 w-3.5" />}
              {Math.abs(trend)}%
            </div>
          )}
        </div>
        <p className="text-xs font-medium opacity-80 mb-1">{title}</p>
        <p className="text-2xl font-bold leading-tight">{value}</p>
      </div>
    </div>
  );
}

/* ── MiniStatCard ─────────────────────────────────────────────── */
interface MiniStatCardProps { icon: React.ReactNode; label: string; value: string | number; color: string; bg: string; }

function MiniStatCard({ icon, label, value, color, bg }: MiniStatCardProps) {
  return (
    <div className="flex items-center gap-4 p-5 rounded-2xl"
      style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
      <div className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0"
        style={{ background: bg, color }}>
        {icon}
      </div>
      <div className="min-w-0">
        <p className="text-xs mb-0.5" style={{ color: '#94a3b8' }}>{label}</p>
        <p className="text-xl font-bold truncate" style={{ color: '#0f172a' }}>{value}</p>
      </div>
    </div>
  );
}

/* ── StatusBadge ──────────────────────────────────────────────── */
const STATUS_STYLES: Record<string, { bg: string; color: string }> = {
  pending: { bg: '#fefce8', color: '#ca8a04' },
  confirmed: { bg: '#eff6ff', color: '#2563eb' },
  preparing: { bg: '#faf5ff', color: '#7c3aed' },
  ready: { bg: '#f0fdf4', color: '#16a34a' },
  delivered: { bg: '#f0fdf4', color: '#16a34a' },
  completed: { bg: '#f8fafc', color: '#475569' },
  cancelled: { bg: '#fef2f2', color: '#dc2626' },
};

function StatusBadge({ status, label }: { status: string; label: string }) {
  const s = STATUS_STYLES[status] ?? { bg: '#f8fafc', color: '#475569' };
  return (
    <span className="inline-block px-2 py-0.5 rounded-md text-[10px] font-semibold"
      style={{ background: s.bg, color: s.color }}>
      {label}
    </span>
  );
}

/* ── Legacy getStatusColor (kept for compatibility) ────────────── */
function getStatusColor(status: string): string {
  const colors: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-800',
    confirmed: 'bg-blue-100 text-blue-800',
    preparing: 'bg-purple-100 text-purple-800',
    ready: 'bg-green-100 text-green-800',
    delivered: 'bg-green-100 text-green-800',
    completed: 'bg-gray-100 text-gray-800',
    cancelled: 'bg-red-100 text-red-800',
  };
  return colors[status] || 'bg-gray-100 text-gray-800';
}
// suppress unused warning — used by other pages that import this
void getStatusColor;
