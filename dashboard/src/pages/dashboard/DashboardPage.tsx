import { useEffect, useState } from 'react';
import {
  ShoppingBag,
  DollarSign,
  TrendingUp,
  Clock,
  ArrowUpRight,
  ArrowDownRight,
  Store,
  UtensilsCrossed
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

  useEffect(() => {
    const fetchData = async () => {
      try {
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
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'decimal',
      minimumFractionDigits: 0,
    }).format(amount) + ' FCFA';
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600">Vue d'ensemble de votre activité</p>
        </div>
        {/* D9 — Sélecteur restaurant */}
        {restaurants.length > 1 && (
          <div className="flex items-center gap-2">
            <Store className="h-4 w-4 text-gray-400 flex-shrink-0" />
            <select
              value={selectedRestaurantId ?? ''}
              onChange={e => setSelectedRestaurantId(e.target.value ? Number(e.target.value) : null)}
              className="border border-gray-200 rounded-lg px-3 py-2 text-sm text-gray-700 focus:ring-2 focus:ring-orange-500 bg-white"
            >
              <option value="">Tous les restaurants</option>
              {restaurants.map(r => (
                <option key={r.id} value={r.id}>{r.nom}</option>
              ))}
            </select>
          </div>
        )}
      </div>

      {/* Stats Cards */}
      {/* D9 — Si restaurant sélectionné, afficher ses stats individuelles */}
      {selectedRestaurantId && restaurantStats ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <StatCard
            title="Commandes aujourd'hui"
            value={restaurantStats.orders_today}
            icon={<ShoppingBag className="h-6 w-6" />}
            color="orange"
          />
          <StatCard
            title="Revenus aujourd'hui"
            value={formatCurrency(restaurantStats.revenue_today)}
            icon={<DollarSign className="h-6 w-6" />}
            color="green"
          />
          <StatCard
            title="En attente"
            value={restaurantStats.pending_orders}
            icon={<Clock className="h-6 w-6" />}
            color="yellow"
          />
          <StatCard
            title="Plats disponibles"
            value={`${restaurantStats.available_dishes} / ${restaurantStats.total_dishes}`}
            icon={<UtensilsCrossed className="h-6 w-6" />}
            color="blue"
          />
          <StatCard
            title="Total commandes"
            value={restaurantStats.total_orders}
            icon={<ShoppingBag className="h-6 w-6" />}
            color="orange"
          />
          <StatCard
            title="Revenus totaux"
            value={formatCurrency(restaurantStats.total_revenue)}
            icon={<TrendingUp className="h-6 w-6" />}
            color="green"
          />
          <StatCard
            title="Catégories"
            value={restaurantStats.total_categories}
            icon={<Store className="h-6 w-6" />}
            color="blue"
          />
          <StatCard
            title="Promotions actives"
            value={restaurantStats.active_promotions}
            icon={<TrendingUp className="h-6 w-6" />}
            color="yellow"
          />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <StatCard
            title="Commandes aujourd'hui"
            value={stats?.today.orders ?? 0}
            icon={<ShoppingBag className="h-6 w-6" />}
            trend={stats?.growth.orders}
            color="orange"
          />
          <StatCard
            title="Revenus aujourd'hui"
            value={formatCurrency(stats?.today.revenue ?? 0)}
            icon={<DollarSign className="h-6 w-6" />}
            trend={stats?.growth.revenue}
            color="green"
          />
          <StatCard
            title="En attente"
            value={stats?.today.pending_orders ?? 0}
            icon={<Clock className="h-6 w-6" />}
            color="yellow"
          />
          <StatCard
            title="Restaurants"
            value={stats?.total_restaurants ?? 0}
            icon={<Store className="h-6 w-6" />}
            color="blue"
          />
        </div>
      )}
      {/* Orders Chart */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Commandes — 7 derniers jours</h2>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="label" stroke="#9ca3af" fontSize={12} />
              <YAxis stroke="#9ca3af" fontSize={12} />
              <Tooltip
                contentStyle={{
                  backgroundColor: 'white',
                  border: '1px solid #e5e7eb',
                  borderRadius: '8px',
                  boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
                }}
              />
              <Line
                type="monotone"
                dataKey="orders"
                stroke="#f97316"
                strokeWidth={2}
                dot={{ fill: '#f97316', strokeWidth: 2 }}
                name="Commandes"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Recent Orders */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Commandes récentes</h2>
        <div className="space-y-4">
          {recentOrders.length > 0 ? (
            recentOrders.map((order) => (
              <div key={order.id} className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0">
                <div>
                  <p className="font-medium text-gray-900">#{order.id}</p>
                  <p className="text-sm text-gray-500">{order.customer_name || 'Client'}</p>
                </div>
                <div className="text-right">
                  <p className="font-medium text-gray-900">{order.formatted_total}</p>
                  <span className={`inline-flex px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(order.status)}`}>
                    {order.status_text}
                  </span>
                </div>
              </div>
            ))
          ) : (
            <p className="text-gray-500 text-center py-8">Aucune commande récente</p>
          )}
        </div>
      </div>

      {/* D4 — Graphique revenus 6 derniers mois */}
      {
        revenueData.length > 0 && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900">Revenus — 6 derniers mois</h2>
              <div className="flex items-center gap-1 text-sm text-green-600 font-medium">
                <TrendingUp className="h-4 w-4" />
                FCFA
              </div>
            </div>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={revenueData} barSize={28}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" vertical={false} />
                  <XAxis dataKey="label" stroke="#9ca3af" fontSize={12} tickLine={false} />
                  <YAxis
                    stroke="#9ca3af"
                    fontSize={11}
                    tickLine={false}
                    axisLine={false}
                    tickFormatter={(v: number) => v >= 1000 ? `${(v / 1000).toFixed(0)}k` : String(v)}
                  />
                  <Tooltip
                    formatter={(value) => [`${new Intl.NumberFormat('fr-FR').format(Number(value))} FCFA`, 'Revenus']}
                    contentStyle={{ backgroundColor: 'white', border: '1px solid #e5e7eb', borderRadius: '8px', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)' }}
                  />
                  <Bar dataKey="revenue" fill="#22c55e" radius={[4, 4, 0, 0]} name="Revenus" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        )
      }

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-orange-100 flex items-center justify-center">
              <UtensilsCrossed className="h-6 w-6 text-orange-600" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Total Plats</p>
              <p className="text-2xl font-bold text-gray-900">{stats?.total_dishes ?? 0}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-green-100 flex items-center justify-center">
              <TrendingUp className="h-6 w-6 text-green-600" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Commandes ce mois</p>
              <p className="text-2xl font-bold text-gray-900">{stats?.this_month.orders ?? 0}</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-blue-100 flex items-center justify-center">
              <DollarSign className="h-6 w-6 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Revenus ce mois</p>
              <p className="text-2xl font-bold text-gray-900">{formatCurrency(stats?.this_month.revenue ?? 0)}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  trend?: number;
  color: 'orange' | 'green' | 'yellow' | 'blue';
}

function StatCard({ title, value, icon, trend, color }: StatCardProps) {
  const colorClasses = {
    orange: 'bg-orange-100 text-orange-600',
    green: 'bg-green-100 text-green-600',
    yellow: 'bg-yellow-100 text-yellow-600',
    blue: 'bg-blue-100 text-blue-600',
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <div className={`w-12 h-12 rounded-lg ${colorClasses[color]} flex items-center justify-center`}>
          {icon}
        </div>
        {trend !== undefined && (
          <div className={`flex items-center gap-1 text-sm font-medium ${trend >= 0 ? 'text-green-600' : 'text-red-600'}`}>
            {trend >= 0 ? <ArrowUpRight className="h-4 w-4" /> : <ArrowDownRight className="h-4 w-4" />}
            {Math.abs(trend)}%
          </div>
        )}
      </div>
      <p className="text-sm text-gray-500 mb-1">{title}</p>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
    </div>
  );
}

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
