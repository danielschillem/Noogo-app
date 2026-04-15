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
  ChefHat,
  Star,
} from 'lucide-react';
import { dashboardApi, restaurantsApi } from '../../services/api';
import type { DashboardStats, Order, Restaurant } from '../../types';
import { useAuth } from '../../context/AuthContext';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Area,
  AreaChart,
  Legend,
} from 'recharts';

// â”€â”€â”€ Local types â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const fmt = (n: number) =>
  new Intl.NumberFormat('fr-FR', { style: 'decimal', minimumFractionDigits: 0 }).format(n);
const fmtCFA = (n: number) => fmt(n) + ' FCFA';

function greet() {
  const h = new Date().getHours();
  if (h < 12) return 'Bonjour';
  if (h < 18) return 'Bon aprÃ¨s-midi';
  return 'Bonsoir';
}

const TODAY_LABEL = new Date().toLocaleDateString('fr-FR', {
  weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
});

// â”€â”€â”€ Main Component â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

export default function DashboardPage() {
  const { user } = useAuth();

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
  const [chartTab, setChartTab] = useState<'orders' | 'revenue'>('orders');
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    restaurantsApi.getAll().then(res => {
      const list: Restaurant[] = res.data.data?.data ?? res.data.data ?? [];
      setRestaurants(list);
    }).catch(console.error);
  }, []);

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
        dashboardApi.getRecentOrders(8),
        dashboardApi.getOrdersChart(7),
        dashboardApi.getRevenueChart(6),
      ]);
      setStats(statsRes.data.data);
      setRecentOrders(ordersRes.data.data);
      setChartData(chartRes.data.data);
      setRevenueData(revenueRes.data.data);
      setLastUpdated(new Date());
    } catch (e) {
      console.error(e);
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

  // â”€â”€ Derived values â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  const active = selectedRestaurantId && restaurantStats ? restaurantStats : null;
  const ordersToday = active?.orders_today ?? stats?.today.orders ?? 0;
  const revenueToday = active?.revenue_today ?? stats?.today.revenue ?? 0;
  const totalRevenue = active?.total_revenue ?? stats?.this_month.revenue ?? 0;
  const totalOrders = active?.total_orders ?? stats?.this_month.orders ?? 0;
  const pendingOrders = active?.pending_orders ?? stats?.today.pending_orders ?? 0;

  const topDishes = [
    { name: 'Performance globale', pct: 85, color: '#f97316' },
    { name: 'Commandes livrÃ©es', pct: Math.min(100, totalOrders > 0 ? Math.round((ordersToday / Math.max(totalOrders, 1)) * 100) : 72), color: '#10b981' },
    { name: 'En prÃ©paration', pct: Math.min(100, pendingOrders > 0 ? 65 : 40), color: '#3b82f6' },
    { name: 'Plats disponibles', pct: active ? Math.round((active.available_dishes / Math.max(active.total_dishes, 1)) * 100) : 78, color: '#7c3aed' },
    { name: 'Taux de satisfaction', pct: 92, color: '#f97316' },
  ];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-12 h-12 rounded-2xl flex items-center justify-center animate-pulse"
            style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
            <Activity className="h-6 w-6 text-white" />
          </div>
          <p className="text-sm font-medium" style={{ color: '#64748b' }}>Chargementâ€¦</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fadeIn">

      {/* â•â• ROW 1 â€” GREETING BANNER â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */}
      <div className="relative overflow-hidden rounded-2xl p-6"
        style={{ background: 'linear-gradient(135deg,#f97316 0%,#ea580c 60%,#dc2626 100%)', boxShadow: '0 8px 32px rgba(249,115,22,0.3)' }}>
        {/* Decorative circles */}
        <div className="absolute -top-8 -right-8 w-40 h-40 rounded-full opacity-10 bg-white" />
        <div className="absolute top-4 right-20 w-20 h-20 rounded-full opacity-10 bg-white" />
        <div className="absolute -bottom-10 right-40 w-32 h-32 rounded-full opacity-10 bg-white" />

        <div className="relative flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <p className="text-sm font-medium text-white opacity-80 mb-1">{TODAY_LABEL}</p>
            <h1 className="text-2xl sm:text-3xl font-bold text-white">
              {greet()}, {user?.name?.split(' ')[0] ?? 'Admin'} ðŸ‘‹
            </h1>
            <p className="text-sm mt-1 text-white opacity-70">
              Livraison GRATUITE chaque weekend â€” Voici votre activitÃ© en temps rÃ©el.
            </p>
          </div>
          <div className="flex items-center gap-2.5 flex-shrink-0">
            {lastUpdated && (
              <span className="text-xs px-3 py-1.5 rounded-xl hidden sm:flex items-center gap-1.5 text-white"
                style={{ background: 'rgba(255,255,255,0.2)' }}>
                <span className="w-1.5 h-1.5 rounded-full bg-green-300 animate-pulse" />
                {lastUpdated.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
              </span>
            )}
            <button onClick={() => fetchData()} disabled={isRefreshing}
              className="p-2.5 rounded-xl disabled:opacity-50 transition-all hover:scale-105 text-white"
              style={{ background: 'rgba(255,255,255,0.2)' }}>
              <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
            </button>
            {restaurants.length > 1 && (
              <select value={selectedRestaurantId ?? ''}
                onChange={e => setSelectedRestaurantId(e.target.value ? Number(e.target.value) : null)}
                className="text-sm px-3 py-2 rounded-xl border-0 outline-none font-medium text-white"
                style={{ background: 'rgba(255,255,255,0.2)' }}>
                <option value="" style={{ background: '#1e293b' }}>Tous les restaurants</option>
                {restaurants.map(r => <option key={r.id} value={r.id} style={{ background: '#1e293b' }}>{r.nom}</option>)}
              </select>
            )}
          </div>
        </div>
      </div>

      {/* â•â• ROW 2 â€” KPI CARDS â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <KpiCard icon={<DollarSign className="h-5 w-5" />} label="Revenus du jour"
          value={fmtCFA(revenueToday)} trend={stats?.growth.revenue} color="#f97316" bg="#fff7ed" />
        <KpiCard icon={<ShoppingBag className="h-5 w-5" />} label="Commandes du jour"
          value={ordersToday} trend={stats?.growth.orders} color="#10b981" bg="#f0fdf4" />
        <KpiCard icon={<Clock className="h-5 w-5" />} label="En attente"
          value={pendingOrders} color="#7c3aed" bg="#faf5ff" />
        <KpiCard icon={<Store className="h-5 w-5" />}
          label={selectedRestaurantId ? 'CatÃ©gories' : 'Restaurants'}
          value={selectedRestaurantId ? (restaurantStats?.total_categories ?? 0) : (stats?.total_restaurants ?? 0)}
          color="#2563eb" bg="#eff6ff" />
      </div>

      {/* â•â• ROW 3 â€” SALES CHART (2/3) + HERO REVENUE (1/3) â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

        {/* Sales area chart with tab switcher */}
        <div className="lg:col-span-2 rounded-2xl p-6"
          style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="font-bold text-base" style={{ color: '#0f172a' }}>Chiffres de ventes</h2>
              <p className="text-xs mt-0.5" style={{ color: '#94a3b8' }}>7 derniers jours â€” vue live</p>
            </div>
            <div className="flex gap-1 p-1 rounded-xl" style={{ background: '#f8fafc', border: '1px solid #f1f5f9' }}>
              {(['orders', 'revenue'] as const).map(tab => (
                <button key={tab} onClick={() => setChartTab(tab)}
                  className="px-3 py-1.5 rounded-lg text-xs font-semibold transition-all"
                  style={chartTab === tab
                    ? { background: 'white', color: '#f97316', boxShadow: '0 1px 4px rgba(0,0,0,0.08)' }
                    : { background: 'transparent', color: '#94a3b8' }}>
                  {tab === 'orders' ? 'Commandes' : 'Revenus'}
                </button>
              ))}
            </div>
          </div>
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="areaGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#f97316" stopOpacity={0.15} />
                    <stop offset="95%" stopColor="#f97316" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis dataKey="label" stroke="#cbd5e1" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#cbd5e1" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip
                  contentStyle={{ background: 'white', border: '1px solid #e2e8f0', borderRadius: 12, boxShadow: '0 4px 20px rgba(0,0,0,0.1)', fontSize: 12 }}
                  cursor={{ stroke: '#f97316', strokeWidth: 1, strokeDasharray: '4 4' }}
                  formatter={(v) => [chartTab === 'revenue' ? fmtCFA(Number(v)) : v, chartTab === 'orders' ? 'Commandes' : 'Revenus']}
                />
                <Area type="monotone" dataKey={chartTab} stroke="#f97316" strokeWidth={2.5}
                  fill="url(#areaGrad)"
                  dot={{ fill: '#f97316', r: 3, strokeWidth: 2, stroke: 'white' }}
                  activeDot={{ r: 5, stroke: 'white', strokeWidth: 2 }} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Hero revenue card + 2 mini-kpis */}
        <div className="flex flex-col gap-4">
          <div className="relative overflow-hidden rounded-2xl p-6 flex-1"
            style={{ background: 'linear-gradient(145deg,#1e293b 0%,#0f172a 100%)', boxShadow: '0 4px 24px rgba(15,23,42,0.3)' }}>
            <div className="absolute -top-6 -right-6 w-28 h-28 rounded-full opacity-10" style={{ background: '#f97316' }} />
            <div className="absolute bottom-2 right-2 w-16 h-16 rounded-full opacity-5" style={{ background: '#f97316' }} />
            <div className="relative">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ background: 'rgba(249,115,22,0.2)' }}>
                  <TrendingUp className="h-4 w-4" style={{ color: '#fb923c' }} />
                </div>
                <span className="text-xs font-semibold" style={{ color: '#94a3b8' }}>
                  {selectedRestaurantId ? 'Revenus totaux' : 'Revenus ce mois'}
                </span>
              </div>
              <p className="text-3xl font-bold text-white leading-tight">{fmtCFA(totalRevenue)}</p>
              {stats?.growth.revenue !== undefined && (
                <div className="flex items-center gap-1.5 mt-2">
                  <span className={`flex items-center gap-0.5 text-xs font-semibold px-2 py-0.5 rounded-lg ${stats.growth.revenue >= 0 ? 'text-green-400' : 'text-red-400'}`}
                    style={{ background: stats.growth.revenue >= 0 ? 'rgba(34,197,94,0.15)' : 'rgba(239,68,68,0.15)' }}>
                    {stats.growth.revenue >= 0
                      ? <ArrowUpRight className="h-3 w-3" />
                      : <ArrowDownRight className="h-3 w-3" />}
                    {Math.abs(stats.growth.revenue)}%
                  </span>
                  <span className="text-xs" style={{ color: '#64748b' }}>vs mois dernier</span>
                </div>
              )}
              <div className="mt-4 pt-4" style={{ borderTop: '1px solid rgba(255,255,255,0.08)' }}>
                <div className="flex justify-between text-xs" style={{ color: '#64748b' }}>
                  <span>{totalOrders} commandes</span>
                  <span>{active?.total_dishes ?? stats?.total_dishes ?? 0} plats</span>
                </div>
              </div>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <MiniKpi icon={<ChefHat className="h-4 w-4" />} label="Total plats"
              value={active?.total_dishes ?? stats?.total_dishes ?? 0}
              color="#7c3aed" bg="#faf5ff" />
            <MiniKpi icon={<Star className="h-4 w-4" />} label="Promotions"
              value={active?.active_promotions ?? 0}
              color="#f97316" bg="#fff7ed" />
          </div>
        </div>
      </div>

      {/* â•â• ROW 4 â€” REVENUE BAR (2/3) + DERNIÃˆRES TRANSACTIONS (1/3) â•â•â•â•â•â•â•â•â•â• */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

        {/* Revenue bar chart */}
        <div className="lg:col-span-2 rounded-2xl p-6"
          style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="font-bold text-base" style={{ color: '#0f172a' }}>Ventes produits</h2>
              <p className="text-xs mt-0.5" style={{ color: '#94a3b8' }}>Revenus & commandes â€” 6 derniers mois</p>
            </div>
            <div className="flex items-center gap-3 text-xs" style={{ color: '#64748b' }}>
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-sm inline-block" style={{ background: '#f97316' }} />Revenus
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-sm inline-block" style={{ background: '#cbd5e1' }} />Commandes
              </span>
            </div>
          </div>
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={revenueData} barSize={18} barGap={6} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#f97316" />
                    <stop offset="100%" stopColor="#ea580c" />
                  </linearGradient>
                  <linearGradient id="ordGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#e2e8f0" />
                    <stop offset="100%" stopColor="#94a3b8" />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis dataKey="label" stroke="#cbd5e1" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#cbd5e1" fontSize={11} tickLine={false} axisLine={false}
                  tickFormatter={(v: number) => v >= 1000 ? `${(v / 1000).toFixed(0)}k` : String(v)} />
                <Tooltip
                  contentStyle={{ background: 'white', border: '1px solid #e2e8f0', borderRadius: 12, boxShadow: '0 4px 20px rgba(0,0,0,0.1)', fontSize: 12 }}
                  cursor={{ fill: '#f8fafc' }}
                  formatter={(v, name) => [
                    name === 'revenue' ? fmtCFA(Number(v)) : v,
                    name === 'revenue' ? 'Revenus' : 'Commandes',
                  ]}
                />
                <Bar dataKey="revenue" fill="url(#revGrad)" radius={[6, 6, 0, 0]} name="Revenus" />
                <Bar dataKey="orders" fill="url(#ordGrad)" radius={[6, 6, 0, 0]} name="Commandes" />
                <Legend iconType="square" iconSize={8} wrapperStyle={{ fontSize: 11 }}
                  formatter={(v) => v === 'revenue' ? 'Revenus' : 'Commandes'} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* DerniÃ¨res transactions */}
        <div className="rounded-2xl p-6"
          style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-bold text-base" style={{ color: '#0f172a' }}>DerniÃ¨res transactions</h2>
            <span className="text-xs font-semibold px-2 py-1 rounded-lg cursor-pointer"
              style={{ background: '#fff7ed', color: '#f97316' }}>Voir tout</span>
          </div>
          <div className="space-y-3">
            {recentOrders.length > 0 ? recentOrders.slice(0, 6).map((order, i) => (
              <div key={order.id} className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
                  style={{ background: TX_COLORS[i % TX_COLORS.length].bg, color: TX_COLORS[i % TX_COLORS.length].color }}>
                  <UtensilsCrossed className="h-4 w-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold truncate" style={{ color: '#0f172a' }}>
                    {order.customer_name ?? `Commande #${order.id}`}
                  </p>
                  <p className="text-xs" style={{ color: '#94a3b8' }}>
                    {new Date(order.order_date ?? Date.now()).toLocaleDateString('fr-FR')}
                  </p>
                </div>
                <p className="text-sm font-bold shrink-0" style={{ color: '#0f172a' }}>
                  {order.formatted_total}
                </p>
              </div>
            )) : (
              <div className="flex flex-col items-center justify-center py-8 gap-2">
                <ShoppingBag className="h-8 w-8" style={{ color: '#cbd5e1' }} />
                <p className="text-xs" style={{ color: '#94a3b8' }}>Aucune transaction</p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* â•â• ROW 5 â€” PERFORMANCE BARS (1/3) + ORDERS TABLE (2/3) â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

        {/* Progress bars */}
        <div className="rounded-2xl p-6"
          style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <div className="flex items-center justify-between mb-5">
            <h2 className="font-bold text-base" style={{ color: '#0f172a' }}>Performance</h2>
            <span className="text-xs font-semibold px-2 py-1 rounded-lg"
              style={{ background: '#f0fdf4', color: '#16a34a' }}>Ce mois</span>
          </div>
          <div className="space-y-4">
            {topDishes.map(item => (
              <div key={item.name}>
                <div className="flex items-center justify-between mb-1.5">
                  <p className="text-xs font-semibold" style={{ color: '#374151' }}>{item.name}</p>
                  <p className="text-xs font-bold" style={{ color: item.color }}>{item.pct}%</p>
                </div>
                <div className="h-2 rounded-full overflow-hidden" style={{ background: '#f1f5f9' }}>
                  <div className="h-full rounded-full transition-all duration-700"
                    style={{ width: `${item.pct}%`, background: item.color }} />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent orders table */}
        <div className="lg:col-span-2 rounded-2xl overflow-hidden"
          style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <div className="flex items-center justify-between px-6 py-4"
            style={{ borderBottom: '1px solid #f8fafc' }}>
            <h2 className="font-bold text-base" style={{ color: '#0f172a' }}>Liste des commandes</h2>
            <div className="flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-lg"
              style={{ background: '#fff7ed', color: '#f97316' }}>
              <Activity className="h-3.5 w-3.5" /> Live
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr style={{ background: '#f8fafc', borderBottom: '1px solid #f1f5f9' }}>
                  {['#', 'Client', 'Montant', 'Statut', 'Date'].map(h => (
                    <th key={h} className="text-left px-5 py-3 text-xs font-semibold" style={{ color: '#64748b' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {recentOrders.length > 0 ? recentOrders.map((order, idx) => (
                  <tr key={order.id} className="table-row-hover"
                    style={{ borderBottom: idx < recentOrders.length - 1 ? '1px solid #f8fafc' : 'none' }}>
                    <td className="px-5 py-3.5">
                      <span className="text-xs font-bold px-2 py-1 rounded-lg"
                        style={{ background: '#fff7ed', color: '#f97316' }}>#{order.id}</span>
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2.5">
                        <div className="w-7 h-7 rounded-lg flex items-center justify-center text-xs font-bold shrink-0"
                          style={{ background: '#f8fafc', color: '#64748b' }}>
                          {(order.customer_name ?? 'C').charAt(0).toUpperCase()}
                        </div>
                        <p className="font-medium truncate max-w-[120px]" style={{ color: '#374151' }}>
                          {order.customer_name ?? 'Client anonyme'}
                        </p>
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <p className="font-bold" style={{ color: '#0f172a' }}>{order.formatted_total}</p>
                    </td>
                    <td className="px-5 py-3.5">
                      <StatusBadge status={order.status} label={order.status_text} />
                    </td>
                    <td className="px-5 py-3.5">
                      <p className="text-xs" style={{ color: '#94a3b8' }}>
                        {order.order_date
                          ? new Date(order.order_date).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: '2-digit' })
                          : 'â€”'}
                      </p>
                    </td>
                  </tr>
                )) : (
                  <tr>
                    <td colSpan={5} className="px-5 py-12 text-center">
                      <ShoppingBag className="h-8 w-8 mx-auto mb-2" style={{ color: '#cbd5e1' }} />
                      <p className="text-xs" style={{ color: '#94a3b8' }}>Aucune commande rÃ©cente</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

    </div>
  );
}

// â”€â”€â”€ Sub-components â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const TX_COLORS = [
  { bg: '#fff7ed', color: '#f97316' },
  { bg: '#f0fdf4', color: '#16a34a' },
  { bg: '#eff6ff', color: '#2563eb' },
  { bg: '#faf5ff', color: '#7c3aed' },
  { bg: '#fefce8', color: '#ca8a04' },
  { bg: '#fef2f2', color: '#dc2626' },
];

interface KpiCardProps {
  icon: React.ReactNode;
  label: string;
  value: string | number;
  trend?: number;
  color: string;
  bg: string;
}

function KpiCard({ icon, label, value, trend, color, bg }: KpiCardProps) {
  return (
    <div className="flex items-center gap-4 p-5 rounded-2xl relative overflow-hidden"
      style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 4px rgba(0,0,0,0.05)' }}>
      <div className="absolute left-0 top-4 bottom-4 w-1 rounded-r-full" style={{ background: color }} />
      <div className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0" style={{ background: bg, color }}>
        {icon}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-xs font-medium mb-0.5" style={{ color: '#94a3b8' }}>{label}</p>
        <p className="text-xl font-bold truncate" style={{ color: '#0f172a' }}>{value}</p>
        {trend !== undefined && (
          <div className={`flex items-center gap-0.5 text-xs font-semibold mt-0.5 ${trend >= 0 ? 'text-green-500' : 'text-red-500'}`}>
            {trend >= 0 ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
            {Math.abs(trend)}% ce mois
          </div>
        )}
      </div>
    </div>
  );
}

interface MiniKpiProps { icon: React.ReactNode; label: string; value: string | number; color: string; bg: string; }

function MiniKpi({ icon, label, value, color, bg }: MiniKpiProps) {
  return (
    <div className="flex flex-col gap-2 p-4 rounded-xl"
      style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
      <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ background: bg, color }}>
        {icon}
      </div>
      <div>
        <p className="text-xs" style={{ color: '#94a3b8' }}>{label}</p>
        <p className="text-lg font-bold" style={{ color: '#0f172a' }}>{value}</p>
      </div>
    </div>
  );
}

const STATUS_STYLES: Record<string, { bg: string; color: string }> = {
  pending: { bg: '#fefce8', color: '#ca8a04' },
  confirmed: { bg: '#eff6ff', color: '#2563eb' },
  preparing: { bg: '#faf5ff', color: '#7c3aed' },
  ready: { bg: '#f0fdf4', color: '#16a34a' },
  delivered: { bg: '#f0fdf4', color: '#16a34a' },
  completed: { bg: '#f8fafc', color: '#475569' },
  cancelled: { bg: '#fef2f2', color: '#dc2626' },
};

function StatusBadge({ status, label }: { status: string; label?: string }) {
  const s = STATUS_STYLES[status] ?? { bg: '#f8fafc', color: '#64748b' };
  return (
    <span className="inline-flex items-center px-2 py-0.5 rounded-lg text-xs font-semibold"
      style={{ background: s.bg, color: s.color }}>
      {label ?? status}
    </span>
  );
}

// kept for compatibility with other pages that import this
export function getStatusColor(status: string) { return STATUS_STYLES[status]; }
