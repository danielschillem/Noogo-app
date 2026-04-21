import { useEffect, useState, useRef, useCallback } from 'react';
import { useParams, Link } from 'react-router-dom';
import {
  ArrowLeft,
  ChefHat,
  Clock,
  CheckCircle,
  Package,
  RefreshCw,
  Volume2,
  VolumeX,
  Wifi,
  WifiOff,
  AlertCircle,
} from 'lucide-react';
import { ordersApi, restaurantsApi } from '../../services/api';
import { usePusher } from '../../hooks/usePusher';
import type { Order, OrderStatus, Restaurant } from '../../types';

/* ── Status config ── */
const KDS_STATUSES: { status: string; label: string; color: string; bg: string; border: string; next?: OrderStatus }[] = [
  { status: 'pending',   label: 'En attente',      color: '#ca8a04', bg: '#fefce8', border: '#fde68a', next: 'confirmed' },
  { status: 'confirmed', label: 'Confirmées',       color: '#2563eb', bg: '#eff6ff', border: '#bfdbfe', next: 'preparing' },
  { status: 'preparing', label: 'En préparation',   color: '#7c3aed', bg: '#faf5ff', border: '#ddd6fe', next: 'ready' },
  { status: 'ready',     label: 'Prêtes à servir',  color: '#16a34a', bg: '#f0fdf4', border: '#bbf7d0', next: 'delivered' },
];

const KITCHEN_STATUSES = KDS_STATUSES.map(s => s.status);

function elapsedTime(dateStr: string): string {
  const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000);
  if (diff < 60) return `${diff}s`;
  if (diff < 3600) return `${Math.floor(diff / 60)}min`;
  return `${Math.floor(diff / 3600)}h${String(Math.floor((diff % 3600) / 60)).padStart(2, '0')}`;
}

function urgencyColor(dateStr: string): string {
  const mins = Math.floor((Date.now() - new Date(dateStr).getTime()) / 60000);
  if (mins >= 20) return '#dc2626'; // rouge
  if (mins >= 10) return '#f97316'; // orange
  return '#16a34a'; // vert
}

/* ── Order ticket ── */
function OrderTicket({
  order,
  onAdvance,
}: {
  order: Order;
  onAdvance: (id: number, next: OrderStatus) => void;
}) {
  const cfg = KDS_STATUSES.find(s => s.status === order.status) ?? KDS_STATUSES[0];
  const elapsed = elapsedTime(order.order_date);
  const tColor = urgencyColor(order.order_date);

  return (
    <div
      className="flex flex-col rounded-2xl overflow-hidden animate-fadeIn"
      style={{
        background: '#1e293b',
        border: `2px solid ${cfg.border}33`,
        boxShadow: '0 4px 20px rgba(0,0,0,0.4)',
      }}
    >
      {/* Ticket header */}
      <div
        className="flex items-center justify-between px-4 py-3"
        style={{ background: `${cfg.color}22`, borderBottom: `1px solid ${cfg.border}44` }}
      >
        <div className="flex items-center gap-2">
          <span className="text-lg font-black" style={{ color: cfg.color }}>#{order.id}</span>
          {order.table_number && (
            <span className="px-2 py-0.5 rounded-full text-xs font-semibold" style={{ background: '#334155', color: '#94a3b8' }}>
              Table {order.table_number}
            </span>
          )}
        </div>
        <div className="flex items-center gap-1.5" style={{ color: tColor }}>
          <Clock className="h-3.5 w-3.5" />
          <span className="text-sm font-bold">{elapsed}</span>
        </div>
      </div>

      {/* Items */}
      <div className="flex-1 p-4 space-y-2">
        {(order.items ?? []).map((item, i) => (
          <div key={i} className="flex items-start gap-3">
            <span
              className="flex-shrink-0 w-7 h-7 rounded-lg flex items-center justify-center text-sm font-black"
              style={{ background: '#f97316', color: 'white' }}
            >
              {item.quantity}
            </span>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold truncate" style={{ color: '#f1f5f9' }}>
                {item.dish?.nom ?? `Plat #${item.dish_id}`}
              </p>
              {(item.notes ?? item.special_instructions) && (
                <p className="text-xs mt-0.5 truncate" style={{ color: '#f97316' }}>
                  ⚠ {item.notes ?? item.special_instructions}
                </p>
              )}
            </div>
          </div>
        ))}
        {(!order.items || order.items.length === 0) && (
          <p className="text-sm" style={{ color: '#475569' }}>Aucun article</p>
        )}
      </div>

      {/* Footer : advance button */}
      {cfg.next && (
        <div className="px-4 pb-4">
          <button
            onClick={() => onAdvance(order.id, cfg.next!)}
            className="w-full py-2.5 rounded-xl text-sm font-bold transition-all hover:opacity-90 active:scale-95"
            style={{ background: cfg.color, color: 'white' }}
          >
            {cfg.next === 'confirmed'  && '✓ Confirmer'}
            {cfg.next === 'preparing'  && '👨‍🍳 En préparation'}
            {cfg.next === 'ready'      && '✅ Prêt à servir'}
            {cfg.next === 'delivered'  && '🚀 Servi / Livré'}
          </button>
        </div>
      )}
    </div>
  );
}

/* ── KDS Column ── */
function KdsColumn({
  config,
  orders,
  onAdvance,
}: {
  config: typeof KDS_STATUSES[number];
  orders: Order[];
  onAdvance: (id: number, next: OrderStatus) => void;
}) {
  return (
    <div className="flex flex-col min-w-0" style={{ minWidth: 260 }}>
      {/* Column header */}
      <div
        className="flex items-center justify-between px-4 py-3 rounded-xl mb-3"
        style={{ background: `${config.color}18`, border: `1px solid ${config.border}44` }}
      >
        <div className="flex items-center gap-2">
          <span className="text-base font-bold" style={{ color: config.color }}>{config.label}</span>
        </div>
        <span
          className="w-7 h-7 rounded-full flex items-center justify-center text-sm font-black"
          style={{ background: config.color, color: 'white' }}
        >
          {orders.length}
        </span>
      </div>

      {/* Cards */}
      <div className="flex flex-col gap-3 flex-1 overflow-y-auto pr-1" style={{ maxHeight: 'calc(100vh - 220px)' }}>
        {orders.map(o => (
          <OrderTicket key={o.id} order={o} onAdvance={onAdvance} />
        ))}
        {orders.length === 0 && (
          <div
            className="flex flex-col items-center justify-center py-12 rounded-2xl"
            style={{ border: '2px dashed #334155', color: '#475569' }}
          >
            <CheckCircle className="h-8 w-8 mb-2 opacity-40" />
            <p className="text-sm">Aucune commande</p>
          </div>
        )}
      </div>
    </div>
  );
}

/* ── Main KitchenPage ── */
export default function KitchenPage() {
  const { id: restaurantId } = useParams<{ id: string }>();
  const rid = Number(restaurantId);

  const [restaurant, setRestaurant] = useState<Restaurant | null>(null);
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [pusherConnected, setPusherConnected] = useState(false);
  const [lastRefresh, setLastRefresh] = useState(new Date());

  const audioCtxRef = useRef<AudioContext | null>(null);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  /* ── Audio alert ── */
  const playAlert = useCallback(() => {
    if (!soundEnabled) return;
    try {
      if (!audioCtxRef.current) {
        audioCtxRef.current = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)();
      }
      const ctx = audioCtxRef.current;
      // Double bip
      [0, 0.25].forEach(delay => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.frequency.value = 880;
        osc.type = 'sine';
        gain.gain.setValueAtTime(0, ctx.currentTime + delay);
        gain.gain.linearRampToValueAtTime(0.4, ctx.currentTime + delay + 0.01);
        gain.gain.linearRampToValueAtTime(0, ctx.currentTime + delay + 0.18);
        osc.start(ctx.currentTime + delay);
        osc.stop(ctx.currentTime + delay + 0.2);
      });
    } catch { /* ignore */ }
  }, [soundEnabled]);

  /* ── Fetch orders ── */
  const fetchOrders = useCallback(async () => {
    if (!rid) return;
    try {
      const res = await ordersApi.getAll(rid, { status: KITCHEN_STATUSES.join(','), per_page: 100 });
      const data: Order[] = res.data?.data ?? res.data ?? [];
      setOrders(data.filter(o => KITCHEN_STATUSES.includes(o.status)));
      setLastRefresh(new Date());
      setError(null);
    } catch {
      setError('Impossible de charger les commandes');
    }
  }, [rid]);

  /* ── Initial load ── */
  useEffect(() => {
    if (!rid) return;
    Promise.all([
      restaurantsApi.getById(rid),
      ordersApi.getAll(rid, { status: KITCHEN_STATUSES.join(','), per_page: 100 }),
    ])
      .then(([rRes, oRes]) => {
        setRestaurant(rRes.data);
        const data: Order[] = oRes.data?.data ?? oRes.data ?? [];
        setOrders(data.filter(o => KITCHEN_STATUSES.includes(o.status)));
        setLastRefresh(new Date());
      })
      .catch(() => setError('Erreur lors du chargement'))
      .finally(() => setLoading(false));
  }, [rid]);

  /* ── Polling 15s ── */
  useEffect(() => {
    pollRef.current = setInterval(fetchOrders, 15_000);
    return () => { if (pollRef.current) clearInterval(pollRef.current); };
  }, [fetchOrders]);

  /* ── Pusher ── */
  usePusher(rid ? `orders.${rid}` : null, {
    'order.created': (data) => {
      const order = data as Order;
      if (KITCHEN_STATUSES.includes(order.status)) {
        setOrders(prev => [order, ...prev.filter(o => o.id !== order.id)]);
        playAlert();
      }
      setPusherConnected(true);
    },
    'order.updated': (data) => {
      const order = data as Order;
      setOrders(prev => {
        const updated = prev.map(o => o.id === order.id ? order : o);
        return updated.filter(o => KITCHEN_STATUSES.includes(o.status));
      });
      setPusherConnected(true);
    },
  });

  /* ── Advance status ── */
  const handleAdvance = async (orderId: number, nextStatus: OrderStatus) => {
    // Optimistic update
    setOrders(prev => {
      const updated = prev.map(o => o.id === orderId ? { ...o, status: nextStatus } : o);
      return updated.filter(o => KITCHEN_STATUSES.includes(o.status));
    });
    try {
      await ordersApi.updateStatus(rid, orderId, nextStatus);
    } catch {
      // Revert on error
      fetchOrders();
    }
  };

  /* ── Grouped orders ── */
  const grouped = KDS_STATUSES.reduce<Record<string, Order[]>>((acc, s) => {
    acc[s.status] = orders.filter(o => o.status === s.status);
    return acc;
  }, {});

  /* ── Render ── */
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ background: '#0f172a' }}>
        <div className="flex flex-col items-center gap-4">
          <div className="animate-spin rounded-full h-12 w-12 border-4 border-orange-500 border-t-transparent" />
          <p style={{ color: '#94a3b8' }}>Chargement KDS…</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col" style={{ background: '#0f172a', fontFamily: 'system-ui, sans-serif' }}>
      {/* ── Top bar ── */}
      <div
        className="flex items-center justify-between px-6 py-3 flex-shrink-0"
        style={{ background: '#1e293b', borderBottom: '1px solid #334155' }}
      >
        {/* Left */}
        <div className="flex items-center gap-4">
          <Link
            to={`/restaurants/${rid}`}
            className="flex items-center gap-2 px-3 py-1.5 rounded-lg transition-colors"
            style={{ color: '#94a3b8', background: '#0f172a' }}
          >
            <ArrowLeft className="h-4 w-4" />
            <span className="text-sm">Retour</span>
          </Link>

          <div className="flex items-center gap-2">
            <div
              className="w-8 h-8 rounded-lg flex items-center justify-center"
              style={{ background: '#f9731622' }}
            >
              <ChefHat className="h-5 w-5" style={{ color: '#f97316' }} />
            </div>
            <div>
              <p className="text-sm font-bold" style={{ color: '#f1f5f9' }}>
                KDS — {restaurant?.nom ?? 'Cuisine'}
              </p>
              <p className="text-xs" style={{ color: '#64748b' }}>
                Mis à jour {lastRefresh.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
              </p>
            </div>
          </div>
        </div>

        {/* Center: total badge */}
        <div className="flex items-center gap-3">
          {['pending','confirmed','preparing','ready'].map(s => {
            const cfg = KDS_STATUSES.find(k => k.status === s)!;
            const count = grouped[s]?.length ?? 0;
            return (
              <div key={s} className="flex items-center gap-1.5 px-3 py-1 rounded-full"
                style={{ background: `${cfg.color}18`, border: `1px solid ${cfg.border}44` }}>
                <span className="text-xs font-bold" style={{ color: cfg.color }}>{count}</span>
                <span className="text-xs" style={{ color: '#64748b' }}>{cfg.label}</span>
              </div>
            );
          })}
        </div>

        {/* Right: controls */}
        <div className="flex items-center gap-3">
          {/* Pusher status */}
          <div className="flex items-center gap-1.5">
            {pusherConnected
              ? <Wifi className="h-4 w-4" style={{ color: '#22c55e' }} />
              : <WifiOff className="h-4 w-4" style={{ color: '#64748b' }} />}
            <span className="text-xs" style={{ color: pusherConnected ? '#22c55e' : '#64748b' }}>
              {pusherConnected ? 'Live' : 'Polling'}
            </span>
          </div>

          {/* Sound toggle */}
          <button
            onClick={() => setSoundEnabled(s => !s)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg transition-colors"
            style={{ background: soundEnabled ? '#16a34a22' : '#33415544', color: soundEnabled ? '#22c55e' : '#64748b' }}
            title={soundEnabled ? 'Désactiver le son' : 'Activer le son'}
          >
            {soundEnabled ? <Volume2 className="h-4 w-4" /> : <VolumeX className="h-4 w-4" />}
            <span className="text-xs">{soundEnabled ? 'Son ON' : 'Son OFF'}</span>
          </button>

          {/* Manual refresh */}
          <button
            onClick={fetchOrders}
            className="p-2 rounded-lg transition-colors"
            style={{ background: '#334155', color: '#94a3b8' }}
            title="Actualiser"
          >
            <RefreshCw className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* ── Error banner ── */}
      {error && (
        <div className="flex items-center gap-2 px-6 py-2" style={{ background: '#dc262622', color: '#fca5a5' }}>
          <AlertCircle className="h-4 w-4 flex-shrink-0" />
          <span className="text-sm">{error}</span>
        </div>
      )}

      {/* ── Kanban board ── */}
      <div className="flex-1 overflow-x-auto p-6">
        <div className="grid gap-5" style={{ gridTemplateColumns: `repeat(${KDS_STATUSES.length}, minmax(260px, 1fr))`, minWidth: KDS_STATUSES.length * 280 }}>
          {KDS_STATUSES.map(cfg => (
            <KdsColumn
              key={cfg.status}
              config={cfg}
              orders={grouped[cfg.status] ?? []}
              onAdvance={handleAdvance}
            />
          ))}
        </div>
      </div>

      {/* ── Empty state (all columns empty) ── */}
      {orders.length === 0 && !loading && (
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none" style={{ top: 64 }}>
          <div className="flex flex-col items-center gap-3 opacity-30">
            <Package className="h-16 w-16" style={{ color: '#94a3b8' }} />
            <p className="text-xl font-semibold" style={{ color: '#94a3b8' }}>Aucune commande active</p>
            <p className="text-sm" style={{ color: '#64748b' }}>Les nouvelles commandes apparaîtront ici automatiquement</p>
          </div>
        </div>
      )}
    </div>
  );
}
