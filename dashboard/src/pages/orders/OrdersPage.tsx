import { useEffect, useState, useRef, useCallback } from 'react';
import { useParams } from 'react-router-dom';
import {
  Clock,
  CheckCircle,
  XCircle,
  ChefHat,
  Package,
  RefreshCw,
  Store,
  AlertCircle,
  Download,
  LayoutGrid,
  List,
  Activity,
} from 'lucide-react';
import { ordersApi, restaurantsApi } from '../../services/api';
import { usePusher } from '../../hooks/usePusher';
import type { Order, OrderStatus, Restaurant } from '../../types';

const POLL_INTERVAL = 15_000;

/* ── Kanban column config ── */
const KANBAN_COLUMNS: { status: string; label: string; color: string; bg: string; border: string; icon: React.ReactNode }[] = [
  { status: 'pending', label: 'En attente', color: '#ca8a04', bg: '#fefce8', border: '#fde68a', icon: <Clock className="h-4 w-4" /> },
  { status: 'confirmed', label: 'Confirmées', color: '#2563eb', bg: '#eff6ff', border: '#bfdbfe', icon: <CheckCircle className="h-4 w-4" /> },
  { status: 'preparing', label: 'En préparation', color: '#7c3aed', bg: '#faf5ff', border: '#ddd6fe', icon: <ChefHat className="h-4 w-4" /> },
  { status: 'ready', label: 'Prêtes', color: '#16a34a', bg: '#f0fdf4', border: '#bbf7d0', icon: <Package className="h-4 w-4" /> },
  { status: 'delivered', label: 'Livrées', color: '#0891b2', bg: '#ecfeff', border: '#a5f3fc', icon: <CheckCircle className="h-4 w-4" /> },
];

const NEXT_STATUS: Record<string, OrderStatus> = {
  pending: 'confirmed',
  confirmed: 'preparing',
  preparing: 'ready',
  ready: 'delivered',
};

const STATUS_STYLES: Record<string, { color: string; bg: string; border: string }> = {
  pending: { color: '#ca8a04', bg: '#fefce8', border: '#fde68a' },
  confirmed: { color: '#2563eb', bg: '#eff6ff', border: '#bfdbfe' },
  preparing: { color: '#7c3aed', bg: '#faf5ff', border: '#ddd6fe' },
  ready: { color: '#16a34a', bg: '#f0fdf4', border: '#bbf7d0' },
  delivered: { color: '#0891b2', bg: '#ecfeff', border: '#a5f3fc' },
  completed: { color: '#475569', bg: '#f8fafc', border: '#e2e8f0' },
  cancelled: { color: '#dc2626', bg: '#fef2f2', border: '#fecaca' },
};

export default function OrdersPage() {
  const { restaurantId: paramRestaurantId } = useParams();
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [selectedRestaurantId, setSelectedRestaurantId] = useState<string | undefined>(paramRestaurantId);
  const restaurantId = paramRestaurantId ?? selectedRestaurantId;

  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [newCount, setNewCount] = useState(0);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [viewMode, setViewMode] = useState<'kanban' | 'list'>('kanban');
  const [draggingId, setDraggingId] = useState<number | null>(null);
  const [dragOverCol, setDragOverCol] = useState<string | null>(null);
  const prevIdsRef = useRef<Set<number>>(new Set());
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const [pendingCounts, setPendingCounts] = useState<{ pending: number; confirmed: number; preparing: number; ready: number } | null>(null);

  useEffect(() => {
    if (!paramRestaurantId) {
      restaurantsApi.getAll().then(res => {
        const list: Restaurant[] = res.data.data?.data ?? res.data.data ?? [];
        setRestaurants(list);
        if (list.length > 0 && !selectedRestaurantId) setSelectedRestaurantId(String(list[0].id));
      }).catch(console.error);
    }
  }, [paramRestaurantId, selectedRestaurantId]);

  const fetchOrders = useCallback(async (silent = false) => {
    if (!restaurantId) return;
    try {
      if (!silent) setIsRefreshing(true);
      const params: Record<string, unknown> = {};
      // En vue kanban on récupère tout pour répartir dans les colonnes
      if (viewMode === 'list' && statusFilter !== 'all') params.status = statusFilter;
      const response = await ordersApi.getAll(parseInt(restaurantId), params);
      const fetched: Order[] = response.data.data.data || response.data.data;
      const incoming = fetched.filter(o => o.status === 'pending' && !prevIdsRef.current.has(o.id));
      if (incoming.length > 0) setNewCount(c => c + incoming.length);
      fetched.forEach(o => prevIdsRef.current.add(o.id));
      setOrders(fetched);
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
  }, [restaurantId, statusFilter, viewMode]);

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

  usePusher(restaurantId ? `restaurant.${restaurantId}` : null, {
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
      setOrders(prev => prev.map(o => o.id === updated.id ? { ...o, ...updated } : o));
    },
  });

  const handleExportCsv = () => {
    if (orders.length === 0) return;
    const headers = ['ID', 'Date', 'Client', 'Téléphone', 'Type', 'Table', 'Statut', 'Paiement', 'Total (FCFA)', 'Plats'];
    const rows = orders.map(o => [
      o.id, new Date(o.order_date).toLocaleString('fr-FR'),
      o.customer_name ?? '', o.customer_phone ?? '',
      o.order_type_text, o.table_number ?? '',
      o.status_text, o.payment_method, o.total_amount,
      (o.items ?? []).map(i => `${i.quantity}x ${i.dish?.nom ?? ''}`).join(' | '),
    ]);
    const csv = [headers, ...rows].map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(';')).join('\n');
    const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url;
    a.download = `commandes-${restaurantId}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click(); URL.revokeObjectURL(url);
  };

  const handleUpdateStatus = useCallback(async (orderId: number, newStatus: OrderStatus) => {
    if (!restaurantId) return;
    // Optimistic update
    setOrders(prev => prev.map(o => o.id === orderId ? { ...o, status: newStatus } : o));
    try {
      await ordersApi.updateStatus(parseInt(restaurantId), orderId, newStatus);
    } catch {
      fetchOrders(); // rollback
    }
  }, [restaurantId, fetchOrders]);

  /* ── Drag-and-drop handlers ── */
  const onDragStart = (orderId: number) => setDraggingId(orderId);
  const onDragEnd = () => { setDraggingId(null); setDragOverCol(null); };
  const onDragOver = (e: React.DragEvent, colStatus: string) => {
    e.preventDefault();
    setDragOverCol(colStatus);
  };
  const onDrop = (e: React.DragEvent, colStatus: string) => {
    e.preventDefault();
    if (draggingId === null) return;
    const order = orders.find(o => o.id === draggingId);
    if (order && order.status !== colStatus && ['pending', 'confirmed', 'preparing', 'ready', 'delivered'].includes(colStatus)) {
      handleUpdateStatus(draggingId, colStatus as OrderStatus);
    }
    setDraggingId(null);
    setDragOverCol(null);
  };

  const filteredOrders = viewMode === 'list' && statusFilter !== 'all'
    ? orders.filter(o => o.status === statusFilter)
    : orders;

  const activeOrders = orders.filter(o => !['completed', 'cancelled'].includes(o.status));
  const inactiveOrders = orders.filter(o => ['completed', 'cancelled'].includes(o.status));

  if (isLoading && restaurantId) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <div className="flex flex-col items-center gap-3">
          <div className="w-12 h-12 rounded-2xl flex items-center justify-center animate-pulse"
            style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
            <Activity className="h-6 w-6 text-white" />
          </div>
          <p className="text-sm font-medium" style={{ color: '#64748b' }}>Chargement des commandes…</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-5 animate-fadeIn">

      {/* ── Header ── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: '#0f172a' }}>Commandes</h1>
          <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>
            {activeOrders.length} commande{activeOrders.length !== 1 ? 's' : ''} active{activeOrders.length !== 1 ? 's' : ''}
          </p>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          {!paramRestaurantId && restaurants.length > 0 && (
            <div className="flex items-center gap-2 px-3 py-2 rounded-xl"
              style={{ background: 'white', border: '1px solid #e2e8f0' }}>
              <Store className="h-4 w-4 flex-shrink-0" style={{ color: '#94a3b8' }} />
              <select value={selectedRestaurantId ?? ''} onChange={e => { setSelectedRestaurantId(e.target.value); setNewCount(0); }}
                className="text-sm bg-transparent border-none outline-none" style={{ color: '#374151' }}>
                {restaurants.map(r => <option key={r.id} value={r.id}>{r.nom}</option>)}
              </select>
            </div>
          )}
          {newCount > 0 && (
            <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-semibold badge-pulse"
              style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
              🔔 {newCount} nouvelle{newCount > 1 ? 's' : ''}
            </span>
          )}
          {/* Toggle vue */}
          <div className="flex rounded-xl overflow-hidden" style={{ border: '1px solid #e2e8f0' }}>
            <button onClick={() => setViewMode('kanban')}
              className="flex items-center gap-1.5 px-3 py-2 text-sm font-medium transition-colors"
              style={{ background: viewMode === 'kanban' ? '#0f172a' : 'white', color: viewMode === 'kanban' ? 'white' : '#64748b' }}>
              <LayoutGrid className="h-4 w-4" /> Kanban
            </button>
            <button onClick={() => setViewMode('list')}
              className="flex items-center gap-1.5 px-3 py-2 text-sm font-medium transition-colors"
              style={{ background: viewMode === 'list' ? '#0f172a' : 'white', color: viewMode === 'list' ? 'white' : '#64748b' }}>
              <List className="h-4 w-4" /> Liste
            </button>
          </div>
          <button onClick={handleExportCsv} disabled={orders.length === 0}
            className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-sm font-medium transition-all disabled:opacity-40"
            style={{ background: 'white', border: '1px solid #e2e8f0', color: '#374151' }}>
            <Download className="h-4 w-4" /> CSV
          </button>
          <button onClick={() => { setNewCount(0); fetchOrders(); }} disabled={isRefreshing}
            className="p-2.5 rounded-xl transition-all disabled:opacity-50"
            style={{ background: 'white', border: '1px solid #e2e8f0', color: '#64748b' }}>
            <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Pas de restaurant */}
      {!restaurantId && (
        <div className="text-center py-16 rounded-2xl" style={{ background: 'white', border: '1px solid #f1f5f9' }}>
          <Store className="h-12 w-12 mx-auto mb-3" style={{ color: '#cbd5e1' }} />
          <p className="font-medium" style={{ color: '#374151' }}>Aucun restaurant disponible</p>
          <p className="text-sm mt-1" style={{ color: '#94a3b8' }}>Créez d'abord un restaurant.</p>
        </div>
      )}

      {/* ── Mini stats ── */}
      {pendingCounts && restaurantId && (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {([
            { label: 'En attente', value: pendingCounts.pending, icon: AlertCircle, ...STATUS_STYLES.pending },
            { label: 'Confirmées', value: pendingCounts.confirmed, icon: CheckCircle, ...STATUS_STYLES.confirmed },
            { label: 'En préparation', value: pendingCounts.preparing, icon: ChefHat, ...STATUS_STYLES.preparing },
            { label: 'Prêtes', value: pendingCounts.ready, icon: Package, ...STATUS_STYLES.ready },
          ] as const).map(({ label, value, icon: Icon, color, bg, border }) => (
            <div key={label} className="flex items-center gap-3 px-4 py-3 rounded-xl"
              style={{ background: bg, border: `1px solid ${border}` }}>
              <Icon className="h-5 w-5 flex-shrink-0" style={{ color }} />
              <div>
                <p className="text-xl font-bold" style={{ color }}>{value}</p>
                <p className="text-xs font-medium" style={{ color, opacity: 0.75 }}>{label}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── KANBAN VIEW ── */}
      {viewMode === 'kanban' && restaurantId && (
        <div className="overflow-x-auto pb-4">
          <div className="flex gap-4 min-w-max">
            {KANBAN_COLUMNS.map(col => {
              const colOrders = activeOrders.filter(o => o.status === col.status);
              const isDragTarget = dragOverCol === col.status;
              return (
                <div key={col.status}
                  style={{ width: 280, minWidth: 280 }}
                  onDragOver={e => onDragOver(e, col.status)}
                  onDrop={e => onDrop(e, col.status)}
                  onDragLeave={() => setDragOverCol(null)}>
                  {/* Column header */}
                  <div className="flex items-center justify-between px-4 py-3 rounded-t-2xl mb-0"
                    style={{ background: col.bg, border: `1px solid ${col.border}`, borderBottom: 'none' }}>
                    <div className="flex items-center gap-2">
                      <span style={{ color: col.color }}>{col.icon}</span>
                      <span className="text-sm font-semibold" style={{ color: col.color }}>{col.label}</span>
                    </div>
                    <span className="text-xs font-bold px-2 py-0.5 rounded-full"
                      style={{ background: col.color + '22', color: col.color }}>
                      {colOrders.length}
                    </span>
                  </div>
                  {/* Drop zone */}
                  <div className="rounded-b-2xl p-2 space-y-2 transition-all"
                    style={{
                      minHeight: 120,
                      background: isDragTarget ? col.bg : '#f8fafc',
                      border: `1.5px dashed ${isDragTarget ? col.border : '#e2e8f0'}`,
                      borderTop: 'none',
                    }}>
                    {colOrders.length === 0 && (
                      <div className="flex items-center justify-center h-16 text-xs" style={{ color: '#94a3b8' }}>
                        Glisser ici
                      </div>
                    )}
                    {colOrders.map(order => (
                      <KanbanCard key={order.id} order={order} col={col}
                        isDragging={draggingId === order.id}
                        onDragStart={() => onDragStart(order.id)}
                        onDragEnd={onDragEnd}
                        onAdvance={NEXT_STATUS[order.status]
                          ? () => handleUpdateStatus(order.id, NEXT_STATUS[order.status])
                          : undefined}
                        onCancel={() => handleUpdateStatus(order.id, 'cancelled')}
                      />
                    ))}
                  </div>
                </div>
              );
            })}

            {/* Archive column */}
            {inactiveOrders.length > 0 && (
              <div style={{ width: 240, minWidth: 240 }}>
                <div className="flex items-center justify-between px-4 py-3 rounded-t-2xl"
                  style={{ background: '#f8fafc', border: '1px solid #e2e8f0', borderBottom: 'none' }}>
                  <span className="text-sm font-semibold" style={{ color: '#64748b' }}>Archive</span>
                  <span className="text-xs font-bold px-2 py-0.5 rounded-full"
                    style={{ background: '#e2e8f0', color: '#475569' }}>
                    {inactiveOrders.length}
                  </span>
                </div>
                <div className="rounded-b-2xl p-2 space-y-2"
                  style={{ background: '#f8fafc', border: '1px solid #e2e8f0', borderTop: 'none', maxHeight: 400, overflowY: 'auto' }}>
                  {inactiveOrders.slice(0, 10).map(order => (
                    <div key={order.id} className="px-3 py-2 rounded-xl text-xs flex items-center justify-between"
                      style={{ background: 'white', border: '1px solid #f1f5f9' }}>
                      <div>
                        <p className="font-semibold" style={{ color: '#374151' }}>#{order.id}</p>
                        <p style={{ color: '#94a3b8' }}>{order.formatted_total}</p>
                      </div>
                      <span className="px-2 py-0.5 rounded-md font-semibold"
                        style={{
                          background: STATUS_STYLES[order.status]?.bg ?? '#f8fafc',
                          color: STATUS_STYLES[order.status]?.color ?? '#475569',
                          border: `1px solid ${STATUS_STYLES[order.status]?.border ?? '#e2e8f0'}`
                        }}>
                        {order.status_text}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ── LIST VIEW ── */}
      {viewMode === 'list' && restaurantId && (
        <>
          {/* Filter pills */}
          <div className="flex items-center gap-2 overflow-x-auto pb-1">
            {['all', 'pending', 'confirmed', 'preparing', 'ready', 'delivered', 'completed', 'cancelled'].map(s => {
              const label: Record<string, string> = {
                all: 'Toutes', pending: 'En attente', confirmed: 'Confirmées',
                preparing: 'En préparation', ready: 'Prêtes', delivered: 'Livrées', completed: 'Terminées', cancelled: 'Annulées'
              };
              const st = STATUS_STYLES[s];
              const active = statusFilter === s;
              return (
                <button key={s} onClick={() => setStatusFilter(s)}
                  className="px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-colors"
                  style={active
                    ? { background: st?.color ?? '#0f172a', color: 'white' }
                    : { background: 'white', color: '#64748b', border: '1px solid #e2e8f0' }}>
                  {label[s] ?? s}
                </button>
              );
            })}
          </div>

          {filteredOrders.length > 0 ? (
            <div className="space-y-3">
              {filteredOrders.map(order => <ListOrderCard key={order.id} order={order} onUpdateStatus={handleUpdateStatus} />)}
            </div>
          ) : (
            <div className="text-center py-16 rounded-2xl" style={{ background: 'white', border: '1px solid #f1f5f9' }}>
              <Package className="h-12 w-12 mx-auto mb-3" style={{ color: '#cbd5e1' }} />
              <p className="font-medium" style={{ color: '#374151' }}>Aucune commande</p>
              <p className="text-sm mt-1" style={{ color: '#94a3b8' }}>Les commandes apparaîtront ici</p>
            </div>
          )}
        </>
      )}
    </div>
  );
}

/* ── KanbanCard ─────────────────────────────────────────────────────── */
interface KanbanCardProps {
  order: Order;
  col: { color: string; bg: string; border: string };
  isDragging: boolean;
  onDragStart: () => void;
  onDragEnd: () => void;
  onAdvance?: () => void;
  onCancel: () => void;
}

function KanbanCard({ order, col, isDragging, onDragStart, onDragEnd, onAdvance, onCancel }: KanbanCardProps) {
  return (
    <div draggable onDragStart={onDragStart} onDragEnd={onDragEnd}
      className="rounded-xl p-3 cursor-grab active:cursor-grabbing transition-all select-none"
      style={{
        background: 'white',
        border: `1px solid ${col.border}`,
        opacity: isDragging ? 0.5 : 1,
        boxShadow: isDragging ? `0 8px 24px ${col.color}33` : '0 1px 3px rgba(0,0,0,0.05)',
        transform: isDragging ? 'rotate(2deg)' : 'none',
      }}>
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs font-bold" style={{ color: col.color }}>#{order.id}</span>
        <span className="text-xs font-semibold" style={{ color: '#374151' }}>{order.formatted_total}</span>
      </div>
      <p className="text-sm font-medium truncate mb-1" style={{ color: '#0f172a' }}>
        {order.customer_name || 'Client'}
      </p>
      <p className="text-xs mb-1" style={{ color: '#94a3b8' }}>
        {order.order_type_text}{order.table_number ? ` · Table ${order.table_number}` : ''}
      </p>
      <p className="text-xs mb-2" style={{ color: '#cbd5e1' }}>
        {new Date(order.order_date).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
      </p>
      {order.items && order.items.length > 0 && (
        <div className="flex flex-wrap gap-1 mb-2">
          {order.items.slice(0, 2).map((item, i) => (
            <span key={i} className="text-[10px] px-1.5 py-0.5 rounded font-medium"
              style={{ background: col.bg, color: col.color }}>
              {item.quantity}× {item.dish?.nom?.slice(0, 12) ?? 'Plat'}
            </span>
          ))}
          {order.items.length > 2 && (
            <span className="text-[10px] px-1.5 py-0.5 rounded" style={{ background: '#f1f5f9', color: '#64748b' }}>
              +{order.items.length - 2}
            </span>
          )}
        </div>
      )}
      {/* Actions */}
      <div className="flex gap-1.5 mt-2">
        {onAdvance && (
          <button onClick={onAdvance}
            className="flex-1 py-1.5 rounded-lg text-[11px] font-semibold text-white transition-opacity hover:opacity-90"
            style={{ background: col.color }}>
            {NEXT_STATUS[order.status] === 'confirmed' ? 'Confirmer' :
              NEXT_STATUS[order.status] === 'preparing' ? 'Préparer' :
                NEXT_STATUS[order.status] === 'ready' ? 'Prête' :
                  NEXT_STATUS[order.status] === 'delivered' ? 'Livrée' : 'Avancer'}
          </button>
        )}
        {['pending', 'confirmed'].includes(order.status) && (
          <button onClick={onCancel}
            className="px-2.5 py-1.5 rounded-lg text-[11px] font-semibold transition-opacity hover:opacity-90"
            style={{ background: '#fef2f2', color: '#dc2626' }}>
            ✕
          </button>
        )}
      </div>
    </div>
  );
}

/* ── ListOrderCard ─────────────────────────────────────────────────── */
function ListOrderCard({ order, onUpdateStatus }: { order: Order; onUpdateStatus: (id: number, s: OrderStatus) => void }) {
  const st = STATUS_STYLES[order.status] ?? STATUS_STYLES.completed;
  return (
    <div className="rounded-2xl p-5 transition-shadow hover:shadow-md"
      style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
      <div className="flex flex-col lg:flex-row lg:items-center gap-4">
        <div className="flex items-start gap-3 flex-1">
          <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 text-sm font-bold"
            style={{ background: st.bg, color: st.color, border: `1px solid ${st.border}` }}>
            #{order.id}
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <span className="font-semibold" style={{ color: '#0f172a' }}>{order.customer_name || 'Client'}</span>
              <span className="text-xs px-2 py-0.5 rounded-md font-semibold"
                style={{ background: st.bg, color: st.color, border: `1px solid ${st.border}` }}>
                {order.status_text}
              </span>
            </div>
            <p className="text-xs mt-0.5" style={{ color: '#94a3b8' }}>
              {order.order_type_text}{order.table_number ? ` · Table ${order.table_number}` : ''} ·{' '}
              {new Date(order.order_date).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}
            </p>
            <div className="flex flex-wrap gap-1 mt-2">
              {order.items?.slice(0, 3).map((item, i) => (
                <span key={i} className="text-xs px-1.5 py-0.5 rounded"
                  style={{ background: '#f8fafc', color: '#374151' }}>
                  {item.quantity}× {item.dish?.nom ?? 'Plat'}
                </span>
              ))}
              {(order.items?.length ?? 0) > 3 && (
                <span className="text-xs px-1.5 py-0.5 rounded" style={{ background: '#f8fafc', color: '#94a3b8' }}>
                  +{order.items.length - 3}
                </span>
              )}
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <div className="text-right">
            <p className="font-bold text-base" style={{ color: '#0f172a' }}>{order.formatted_total}</p>
            <p className="text-xs" style={{ color: '#94a3b8' }}>{order.payment_method}</p>
          </div>
          {/* Status actions */}
          <div className="flex gap-1.5">
            {order.status === 'pending' && (<>
              <button onClick={() => onUpdateStatus(order.id, 'confirmed')}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold text-white"
                style={{ background: '#2563eb' }}>Confirmer</button>
              <button onClick={() => onUpdateStatus(order.id, 'cancelled')}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold"
                style={{ background: '#fef2f2', color: '#dc2626' }}>Annuler</button>
            </>)}
            {order.status === 'confirmed' && (
              <button onClick={() => onUpdateStatus(order.id, 'preparing')}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold text-white"
                style={{ background: '#7c3aed' }}>Préparer</button>
            )}
            {order.status === 'preparing' && (
              <button onClick={() => onUpdateStatus(order.id, 'ready')}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold text-white"
                style={{ background: '#16a34a' }}>Prête</button>
            )}
            {order.status === 'ready' && (
              <button onClick={() => onUpdateStatus(order.id, 'delivered')}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold text-white"
                style={{ background: '#0891b2' }}>Livrer</button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

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
