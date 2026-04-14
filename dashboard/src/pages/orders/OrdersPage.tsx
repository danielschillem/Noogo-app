import { useEffect, useState, useRef, useCallback } from 'react';
import { useParams } from 'react-router-dom';
import {
  Clock,
  CheckCircle,
  XCircle,
  ChefHat,
  Package,
  Filter,
  RefreshCw,
  Store,
  AlertCircle,
  Download,
} from 'lucide-react';
import { ordersApi, restaurantsApi } from '../../services/api';
import { usePusher } from '../../hooks/usePusher';
import type { Order, OrderStatus, Restaurant } from '../../types';

const POLL_INTERVAL = 15_000; // 15 secondes

export default function OrdersPage() {
  const { restaurantId: paramRestaurantId } = useParams();

  // ── Restaurant selector (quand `/orders` sans param) ──────────────────
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [selectedRestaurantId, setSelectedRestaurantId] = useState<string | undefined>(paramRestaurantId);

  // L'ID effectif (depuis URL ou sélecteur)
  const restaurantId = paramRestaurantId ?? selectedRestaurantId;

  useEffect(() => {
    if (!paramRestaurantId) {
      restaurantsApi.getAll().then(res => {
        const list: Restaurant[] = res.data.data?.data ?? res.data.data ?? [];
        setRestaurants(list);
        if (list.length > 0 && !selectedRestaurantId) {
          setSelectedRestaurantId(String(list[0].id));
        }
      }).catch(console.error);
    }
  }, [paramRestaurantId, selectedRestaurantId]);

  // ── Commandes ─────────────────────────────────────────────────────────
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [newCount, setNewCount] = useState(0);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const prevIdsRef = useRef<Set<number>>(new Set());
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // ── Stats mini-barre (D5) ─────────────────────────────────────────────
  const [pendingCounts, setPendingCounts] = useState<{ pending: number; confirmed: number; preparing: number; ready: number } | null>(null);

  const fetchOrders = useCallback(async (silent = false) => {
    if (!restaurantId) return;
    try {
      if (!silent) setIsRefreshing(true);
      const params: Record<string, unknown> = {};
      if (statusFilter !== 'all') params.status = statusFilter;
      const response = await ordersApi.getAll(parseInt(restaurantId), params);
      const fetched: Order[] = response.data.data.data || response.data.data;

      // Détecter les nouvelles commandes (pending non vues)
      const incoming = fetched.filter(o => o.status === 'pending' && !prevIdsRef.current.has(o.id));
      if (incoming.length > 0) setNewCount(c => c + incoming.length);
      fetched.forEach(o => prevIdsRef.current.add(o.id));

      setOrders(fetched);

      // D5 — stats mini-barre
      try {
        const statsRes = await ordersApi.getPendingCount(parseInt(restaurantId));
        setPendingCounts(statsRes.data.data);
      } catch { /* non bloquant */ }
    } catch (error) {
      console.error('Error fetching orders:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [restaurantId, statusFilter]);

  useEffect(() => {
    prevIdsRef.current = new Set();
    setOrders([]);
    setIsLoading(true);
    if (restaurantId) {
      fetchOrders();
      intervalRef.current = setInterval(() => fetchOrders(true), POLL_INTERVAL);
    }
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, [fetchOrders, restaurantId]);

  const handleManualRefresh = () => {
    setNewCount(0);
    fetchOrders();
  };

  // D11 — Pusher temps réel (complète le polling de 15s)
  usePusher(
    restaurantId ? `restaurant.${restaurantId}` : null,
    {
      'order.created': (data) => {
        const newOrder = data as Order;
        if (!prevIdsRef.current.has(newOrder.id)) {
          prevIdsRef.current.add(newOrder.id);
          setOrders(prev => [newOrder, ...prev]);
          setNewCount(c => c + 1);
        }
      },
      'order.updated': (data) => {
        const updated = data as Order;
        setOrders(prev =>
          prev.map(o => (o.id === updated.id ? { ...o, ...updated } : o))
        );
      },
    },
  );

  // D10 — Export CSV
  const handleExportCsv = () => {
    if (orders.length === 0) return;
    const headers = ['ID', 'Date', 'Client', 'Téléphone', 'Type', 'Table', 'Statut', 'Paiement', 'Total (FCFA)', 'Plats'];
    const rows = orders.map(o => [
      o.id,
      new Date(o.order_date).toLocaleString('fr-FR'),
      o.customer_name ?? '',
      o.customer_phone ?? '',
      o.order_type_text,
      o.table_number ?? '',
      o.status_text,
      o.payment_method,
      o.total_amount,
      (o.items ?? []).map(i => `${i.quantity}x ${i.dish?.nom ?? ''}`).join(' | '),
    ]);
    const csv = [headers, ...rows]
      .map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(';'))
      .join('\n');
    const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `commandes-${restaurantId ?? 'all'}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleUpdateStatus = async (orderId: number, newStatus: OrderStatus) => {
    if (!restaurantId) return;
    try {
      await ordersApi.updateStatus(parseInt(restaurantId), orderId, newStatus);
      fetchOrders();
    } catch (error) {
      console.error('Error updating order status:', error);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending': return <Clock className="h-5 w-5 text-yellow-500" />;
      case 'confirmed': return <CheckCircle className="h-5 w-5 text-blue-500" />;
      case 'preparing': return <ChefHat className="h-5 w-5 text-purple-500" />;
      case 'ready': return <Package className="h-5 w-5 text-green-500" />;
      case 'delivered':
      case 'completed': return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'cancelled': return <XCircle className="h-5 w-5 text-red-500" />;
      default: return <Clock className="h-5 w-5 text-gray-500" />;
    }
  };

  const statusColors: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-800 border-yellow-200',
    confirmed: 'bg-blue-100 text-blue-800 border-blue-200',
    preparing: 'bg-purple-100 text-purple-800 border-purple-200',
    ready: 'bg-green-100 text-green-800 border-green-200',
    delivered: 'bg-green-100 text-green-800 border-green-200',
    completed: 'bg-gray-100 text-gray-800 border-gray-200',
    cancelled: 'bg-red-100 text-red-800 border-red-200',
  };

  if (isLoading && restaurantId) {
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
          <h1 className="text-2xl font-bold text-gray-900">Commandes</h1>
          <p className="text-gray-600">Gérez les commandes en cours</p>
        </div>
        <div className="flex items-center gap-3">
          {/* D3 — Sélecteur restaurant (visible quand pas de param URL) */}
          {!paramRestaurantId && restaurants.length > 0 && (
            <div className="flex items-center gap-2">
              <Store className="h-4 w-4 text-gray-400 flex-shrink-0" />
              <select
                value={selectedRestaurantId ?? ''}
                onChange={e => { setSelectedRestaurantId(e.target.value); setNewCount(0); }}
                className="border border-gray-200 rounded-lg px-3 py-2 text-sm text-gray-700 focus:ring-2 focus:ring-orange-500 focus:border-transparent bg-white"
              >
                {restaurants.map(r => (
                  <option key={r.id} value={r.id}>{r.nom}</option>
                ))}
              </select>
            </div>
          )}
          {newCount > 0 && (
            <span className="inline-flex items-center gap-1 px-3 py-1 bg-red-100 text-red-700 rounded-full text-sm font-semibold animate-pulse">
              🔔 {newCount} nouvelle{newCount > 1 ? 's' : ''}
            </span>
          )}
          {orders.length > 0 && (
            <button
              onClick={handleExportCsv}
              className="inline-flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50 transition-colors"
            >
              <Download className="h-4 w-4" />
              Exporter CSV
            </button>
          )}
          <button
            onClick={handleManualRefresh}
            disabled={isRefreshing}
            className="inline-flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50 disabled:opacity-50 transition-colors"
          >
            <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
            Actualiser
          </button>
        </div>
      </div>

      {/* D3 — Message si aucun restaurant */}
      {!restaurantId && (
        <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
          <Store className="h-12 w-12 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Aucun restaurant disponible</h3>
          <p className="text-gray-500">Créez d'abord un restaurant pour voir ses commandes.</p>
        </div>
      )}

      {/* D5 — Mini-barre de stats */}
      {pendingCounts && restaurantId && (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {[
            { label: 'En attente', value: pendingCounts.pending, icon: AlertCircle, color: 'text-yellow-600 bg-yellow-50 border-yellow-200' },
            { label: 'Confirmées', value: pendingCounts.confirmed, icon: CheckCircle, color: 'text-blue-600 bg-blue-50 border-blue-200' },
            { label: 'En préparation', value: pendingCounts.preparing, icon: ChefHat, color: 'text-purple-600 bg-purple-50 border-purple-200' },
            { label: 'Prêtes', value: pendingCounts.ready, icon: Package, color: 'text-green-600 bg-green-50 border-green-200' },
          ].map(({ label, value, icon: Icon, color }) => (
            <div key={label} className={`flex items-center gap-3 px-4 py-3 rounded-xl border ${color}`}>
              <Icon className="h-5 w-5 flex-shrink-0" />
              <div>
                <p className="text-xl font-bold">{value}</p>
                <p className="text-xs font-medium opacity-80">{label}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Filters */}
      <div className="flex items-center gap-2 overflow-x-auto pb-2">
        <Filter className="h-5 w-5 text-gray-400 flex-shrink-0" />
        {['all', 'pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled'].map((status) => (
          <button
            key={status}
            onClick={() => setStatusFilter(status)}
            className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors ${statusFilter === status
              ? 'bg-orange-500 text-white'
              : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
              }`}
          >
            {status === 'all' ? 'Toutes' :
              status === 'pending' ? 'En attente' :
                status === 'confirmed' ? 'Confirmées' :
                  status === 'preparing' ? 'En préparation' :
                    status === 'ready' ? 'Prêtes' :
                      status === 'completed' ? 'Terminées' : 'Annulées'}
          </button>
        ))}
      </div>

      {/* Orders List */}
      {orders.length > 0 ? (
        <div className="space-y-4">
          {orders.map((order) => (
            <div
              key={order.id}
              className="bg-white rounded-xl border border-gray-200 p-6 hover:shadow-md transition-shadow"
            >
              <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                {/* Order Info */}
                <div className="flex items-start gap-4">
                  <div className={`p-3 rounded-lg ${statusColors[order.status]}`}>
                    {getStatusIcon(order.status)}
                  </div>
                  <div>
                    <div className="flex items-center gap-3">
                      <h3 className="font-semibold text-gray-900">Commande #{order.id}</h3>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium border ${statusColors[order.status]}`}>
                        {order.status_text}
                      </span>
                    </div>
                    <p className="text-sm text-gray-500 mt-1">
                      {order.customer_name || 'Client'} • {order.order_type_text}
                      {order.table_number && ` • Table ${order.table_number}`}
                    </p>
                    <p className="text-sm text-gray-400 mt-1">
                      {new Date(order.order_date).toLocaleString('fr-FR')}
                    </p>
                  </div>
                </div>

                {/* Items Summary */}
                <div className="flex-1 lg:px-6">
                  <div className="flex flex-wrap gap-2">
                    {order.items?.slice(0, 3).map((item, index) => (
                      <span key={index} className="px-2 py-1 bg-gray-100 rounded text-sm text-gray-600">
                        {item.quantity}x {item.dish?.nom || 'Plat'}
                      </span>
                    ))}
                    {order.items?.length > 3 && (
                      <span className="px-2 py-1 bg-gray-100 rounded text-sm text-gray-600">
                        +{order.items.length - 3} autres
                      </span>
                    )}
                  </div>
                </div>

                {/* Total & Actions */}
                <div className="flex items-center gap-4">
                  <div className="text-right">
                    <p className="text-lg font-bold text-gray-900">{order.formatted_total}</p>
                    <p className="text-sm text-gray-500">{order.payment_method}</p>
                  </div>

                  {order.status === 'pending' && (
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleUpdateStatus(order.id, 'confirmed')}
                        className="px-3 py-2 bg-green-500 text-white rounded-lg text-sm hover:bg-green-600"
                      >
                        Confirmer
                      </button>
                      <button
                        onClick={() => handleUpdateStatus(order.id, 'cancelled')}
                        className="px-3 py-2 bg-red-500 text-white rounded-lg text-sm hover:bg-red-600"
                      >
                        Annuler
                      </button>
                    </div>
                  )}

                  {order.status === 'confirmed' && (
                    <button
                      onClick={() => handleUpdateStatus(order.id, 'preparing')}
                      className="px-4 py-2 bg-purple-500 text-white rounded-lg text-sm hover:bg-purple-600"
                    >
                      En préparation
                    </button>
                  )}

                  {order.status === 'preparing' && (
                    <button
                      onClick={() => handleUpdateStatus(order.id, 'ready')}
                      className="px-4 py-2 bg-green-500 text-white rounded-lg text-sm hover:bg-green-600"
                    >
                      Prête
                    </button>
                  )}

                  {order.status === 'ready' && (
                    <button
                      onClick={() => handleUpdateStatus(order.id, 'delivered')}
                      className="px-4 py-2 bg-blue-500 text-white rounded-lg text-sm hover:bg-blue-600"
                    >
                      Livrée
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-100 rounded-full flex items-center justify-center">
            <Package className="h-8 w-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">Aucune commande</h3>
          <p className="text-gray-500">Les commandes apparaîtront ici</p>
        </div>
      )}
    </div>
  );
}
