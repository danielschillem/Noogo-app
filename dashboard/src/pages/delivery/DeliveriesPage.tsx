import { useCallback, useEffect, useState } from 'react';
import {
    Package,
    RefreshCw,
    MapPin,
    Clock,
    CheckCircle2,
    XCircle,
    Truck,
    User,
    Download,
    Map as MapIcon,
    List,
} from 'lucide-react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { deliveryApi } from '../../services/api';
import { getPusher } from '../../hooks/usePusher';
import type { Delivery, DeliveryDriver, DeliveryStatus } from '../../types';

const STATUS_CFG: Record<DeliveryStatus, { label: string; bg: string; color: string; border: string }> = {
    pending_assignment: { label: 'En attente', bg: '#fef3c7', color: '#92400e', border: '#fde68a' },
    assigned: { label: 'Assignée', bg: '#dbeafe', color: '#1e40af', border: '#93c5fd' },
    picked_up: { label: 'Récupérée', bg: '#e0e7ff', color: '#3730a3', border: '#a5b4fc' },
    on_way: { label: 'En route', bg: '#fff7ed', color: '#c2410c', border: '#fed7aa' },
    delivered: { label: 'Livrée', bg: '#f0fdf4', color: '#16a34a', border: '#bbf7d0' },
    failed: { label: 'Échouée', bg: '#fef2f2', color: '#dc2626', border: '#fecaca' },
};

// ── Leaflet custom icons ─────────────────────────────────────────────────────

const driverIcon = (status: DeliveryStatus) => {
    const colors: Record<string, string> = {
        assigned: '#2563eb',
        picked_up: '#7c3aed',
        on_way: '#f97316',
        delivered: '#16a34a',
        failed: '#dc2626',
        pending_assignment: '#94a3b8',
    };
    const c = colors[status] ?? '#94a3b8';
    return L.divIcon({
        className: '',
        iconSize: [32, 32],
        iconAnchor: [16, 32],
        popupAnchor: [0, -32],
        html: `<div style="width:32px;height:32px;border-radius:50%;background:${c};border:3px solid white;box-shadow:0 2px 6px rgba(0,0,0,.3);display:flex;align-items:center;justify-content:center">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2"><path d="M10 17h4V5h2l-5-3-5 3h2v12z"/><circle cx="7.5" cy="20.5" r="1.5"/><circle cx="16.5" cy="20.5" r="1.5"/></svg></div>`,
    });
};

const clientIcon = L.divIcon({
    className: '',
    iconSize: [24, 24],
    iconAnchor: [12, 24],
    popupAnchor: [0, -24],
    html: `<div style="width:24px;height:24px;border-radius:50%;background:#dc2626;border:2px solid white;box-shadow:0 2px 6px rgba(0,0,0,.25);display:flex;align-items:center;justify-content:center">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="white"><circle cx="12" cy="12" r="5"/></svg></div>`,
});

// ── Map auto-fit ─────────────────────────────────────────────────────────────

function FitBounds({ positions }: { positions: [number, number][] }) {
    const map = useMap();
    useEffect(() => {
        if (positions.length > 0) {
            const bounds = L.latLngBounds(positions.map(p => L.latLng(p[0], p[1])));
            map.fitBounds(bounds, { padding: [40, 40], maxZoom: 14 });
        }
    }, [positions, map]);
    return null;
}

// ── CSV export ───────────────────────────────────────────────────────────────

function exportCsv(deliveries: Delivery[]) {
    const header = ['ID', 'Commande', 'Livreur', 'Statut', 'Adresse', 'Frais (FCFA)', 'Date'];
    const rows = deliveries.map(d => [
        d.id,
        d.order_id,
        d.driver?.name ?? '',
        STATUS_CFG[d.status]?.label ?? d.status,
        (d.client_address ?? '').replace(/"/g, '""'),
        d.fee,
        d.created_at ? new Date(d.created_at).toLocaleString('fr-FR') : '',
    ]);
    const csv = [header, ...rows].map(r => r.map(v => `"${v}"`).join(',')).join('\n');
    const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `livraisons_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
}

export default function DeliveriesPage() {
    const [deliveries, setDeliveries] = useState<Delivery[]>([]);
    const [drivers, setDrivers] = useState<DeliveryDriver[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [assignModal, setAssignModal] = useState<Delivery | null>(null);
    const [selectedDriverId, setSelectedDriverId] = useState<number | null>(null);
    const [assigning, setAssigning] = useState(false);
    const [updatingStatusId, setUpdatingStatusId] = useState<number | null>(null);
    const [viewMode, setViewMode] = useState<'list' | 'map'>('list');

    const fetchDeliveries = useCallback(async () => {
        try {
            const res = await deliveryApi.getAll({
                status: statusFilter || undefined,
            });
            setDeliveries(res.data.data?.data ?? res.data.data ?? []);
        } catch { /* ignore */ }
        finally { setIsLoading(false); }
    }, [statusFilter]);

    const fetchDrivers = useCallback(async () => {
        try {
            const res = await deliveryApi.getDrivers({ status: 'available' });
            setDrivers(res.data.data?.data ?? res.data.data ?? []);
        } catch { /* ignore */ }
    }, []);

    useEffect(() => { fetchDeliveries(); }, [fetchDeliveries]);
    useEffect(() => { fetchDrivers(); }, [fetchDrivers]);

    // ── Pusher real-time: driver location + status updates ──
    useEffect(() => {
        const pusher = getPusher();
        if (!pusher) return;

        const orderIds = deliveries
            .filter(d => ['assigned', 'picked_up', 'on_way'].includes(d.status))
            .map(d => d.order_id);

        if (orderIds.length === 0) return;

        const channels = orderIds.map(orderId => {
            const ch = pusher.subscribe(`delivery.${orderId}`);
            ch.bind('driver.location', (data: { order_id: number; lat: number; lng: number }) => {
                setDeliveries(prev => prev.map(d =>
                    d.order_id === data.order_id
                        ? { ...d, driver_lat: data.lat, driver_lng: data.lng, driver_location_at: new Date().toISOString() }
                        : d
                ));
            });
            const refetch = () => { fetchDeliveries(); fetchDrivers(); };
            for (const ev of ['delivery.assigned', 'delivery.picked_up', 'delivery.on_way', 'delivery.delivered', 'delivery.failed']) {
                ch.bind(ev, refetch);
            }
            return ch;
        });

        return () => {
            for (const ch of channels) {
                ch.unbind_all();
                pusher.unsubscribe(ch.name);
            }
        };
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [deliveries.filter(d => ['assigned', 'picked_up', 'on_way'].includes(d.status)).map(d => d.order_id).join(',')]);

    const openAssign = (delivery: Delivery) => {
        setAssignModal(delivery);
        setSelectedDriverId(null);
    };

    const handleAssign = async () => {
        if (!assignModal || !selectedDriverId) return;
        setAssigning(true);
        try {
            await deliveryApi.assign(assignModal.id, selectedDriverId);
            setAssignModal(null);
            fetchDeliveries();
            fetchDrivers();
        } catch { /* ignore */ }
        finally { setAssigning(false); }
    };

    const handleStatusUpdate = async (deliveryId: number, status: DeliveryStatus, failureReason?: string) => {
        setUpdatingStatusId(deliveryId);
        try {
            await deliveryApi.updateStatus(deliveryId, status, failureReason);
            fetchDeliveries();
            fetchDrivers();
        } catch { /* ignore */ }
        finally { setUpdatingStatusId(null); }
    };

    const formatDate = (d: string | null) => {
        if (!d) return '—';
        return new Date(d).toLocaleString('fr-FR', {
            day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit',
        });
    };

    // Stats
    const total = deliveries.length;
    const pending = deliveries.filter(d => d.status === 'pending_assignment').length;
    const inProgress = deliveries.filter(d => ['assigned', 'picked_up', 'on_way'].includes(d.status)).length;
    const completed = deliveries.filter(d => d.status === 'delivered').length;

    const stats = [
        { label: 'Total', value: total, icon: Package, gradient: 'linear-gradient(135deg,#3b82f6,#1d4ed8)', shadow: 'rgba(59,130,246,0.35)' },
        { label: 'En attente', value: pending, icon: Clock, gradient: 'linear-gradient(135deg,#f59e0b,#d97706)', shadow: 'rgba(245,158,11,0.35)' },
        { label: 'En cours', value: inProgress, icon: Truck, gradient: 'linear-gradient(135deg,#f97316,#ea580c)', shadow: 'rgba(249,115,22,0.35)' },
        { label: 'Livrées', value: completed, icon: CheckCircle2, gradient: 'linear-gradient(135deg,#22c55e,#15803d)', shadow: 'rgba(34,197,94,0.35)' },
    ];

    // Map positions
    const mapPositions: [number, number][] = deliveries
        .filter(d => d.driver_lat != null && d.driver_lng != null)
        .map(d => [d.driver_lat!, d.driver_lng!]);

    // Also add client positions for bounds
    const allPositions: [number, number][] = [
        ...mapPositions,
        ...deliveries
            .filter(d => d.client_lat != null && d.client_lng != null)
            .map(d => [d.client_lat!, d.client_lng!] as [number, number]),
    ];

    if (isLoading) {
        return (
            <div className="flex items-center justify-center h-64">
                <Package className="h-8 w-8 animate-pulse" style={{ color: '#f97316' }} />
                <span className="ml-3 text-sm font-medium" style={{ color: '#64748b' }}>Chargement…</span>
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-fadeIn">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: '#0f172a' }}>Livraisons</h1>
                    <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>Suivi et gestion des livraisons</p>
                </div>
                <div className="flex items-center gap-2">
                    {/* View toggle */}
                    <div className="flex rounded-xl overflow-hidden" style={{ border: '1px solid #e2e8f0' }}>
                        <button
                            onClick={() => setViewMode('list')}
                            className="p-2.5"
                            style={{ background: viewMode === 'list' ? '#f97316' : 'white', color: viewMode === 'list' ? 'white' : '#64748b' }}
                        >
                            <List size={16} />
                        </button>
                        <button
                            onClick={() => setViewMode('map')}
                            className="p-2.5"
                            style={{ background: viewMode === 'map' ? '#f97316' : 'white', color: viewMode === 'map' ? 'white' : '#64748b', borderLeft: '1px solid #e2e8f0' }}
                        >
                            <MapIcon size={16} />
                        </button>
                    </div>
                    {/* CSV export */}
                    <button
                        onClick={() => exportCsv(deliveries)}
                        className="p-2.5 rounded-xl"
                        style={{ background: 'white', border: '1px solid #e2e8f0', color: '#64748b' }}
                        title="Exporter CSV"
                    >
                        <Download size={16} />
                    </button>
                    {/* Refresh */}
                    <button onClick={() => { setIsLoading(true); fetchDeliveries(); }} className="p-2.5 rounded-xl" style={{ background: 'white', border: '1px solid #e2e8f0', color: '#64748b' }}>
                        <RefreshCw size={16} />
                    </button>
                </div>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                {stats.map(s => (
                    <div key={s.label} className="rounded-2xl p-5" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
                        <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: s.gradient, boxShadow: `0 4px 12px ${s.shadow}` }}>
                                <s.icon size={16} className="text-white" />
                            </div>
                            <div>
                                <p className="text-2xl font-black" style={{ color: '#0f172a' }}>{s.value}</p>
                                <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: '#94a3b8' }}>{s.label}</p>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* Filters */}
            <div className="flex gap-1 p-1 rounded-xl" style={{ background: '#f1f5f9' }}>
                {[
                    { key: '', label: 'Toutes' },
                    { key: 'pending_assignment', label: 'En attente' },
                    { key: 'assigned', label: 'Assignées' },
                    { key: 'picked_up', label: 'Récupérées' },
                    { key: 'on_way', label: 'En route' },
                    { key: 'delivered', label: 'Livrées' },
                    { key: 'failed', label: 'Échouées' },
                ].map(f => (
                    <button
                        key={f.key}
                        onClick={() => setStatusFilter(f.key)}
                        className="px-3 py-1.5 rounded-lg text-xs font-medium transition-all"
                        style={statusFilter === f.key
                            ? { background: 'white', color: '#0f172a', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }
                            : { color: '#64748b' }}
                    >
                        {f.label}
                    </button>
                ))}
            </div>

            {/* Table / Map */}
            {viewMode === 'map' ? (
                /* ── DEL-D04 : Carte temps réel des livreurs ── */
                <div className="rounded-2xl overflow-hidden" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)', height: 500 }}>
                    {allPositions.length === 0 ? (
                        <div className="flex flex-col items-center justify-center h-full">
                            <MapPin size={48} style={{ color: '#cbd5e1' }} />
                            <p className="mt-3 font-medium" style={{ color: '#374151' }}>Aucune position disponible</p>
                            <p className="text-sm" style={{ color: '#94a3b8' }}>Les positions des livreurs apparaîtront ici en temps réel.</p>
                        </div>
                    ) : (
                        <MapContainer center={[12.37, -1.52]} zoom={13} style={{ height: '100%', width: '100%' }} scrollWheelZoom>
                            <TileLayer
                                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                            />
                            <FitBounds positions={allPositions} />
                            {deliveries.filter(d => d.driver_lat != null && d.driver_lng != null).map(d => (
                                <Marker key={`driver-${d.id}`} position={[d.driver_lat!, d.driver_lng!]} icon={driverIcon(d.status)}>
                                    <Popup>
                                        <div style={{ minWidth: 160 }}>
                                            <p className="font-bold text-sm">{d.driver?.name ?? 'Livreur'}</p>
                                            <p className="text-xs" style={{ color: '#64748b' }}>Cmd #{d.order_id}</p>
                                            <span className="inline-block mt-1 px-2 py-0.5 rounded-full text-xs font-semibold"
                                                style={{ background: STATUS_CFG[d.status].bg, color: STATUS_CFG[d.status].color }}>
                                                {STATUS_CFG[d.status].label}
                                            </span>
                                            {d.client_address && <p className="text-xs mt-1" style={{ color: '#94a3b8' }}>{d.client_address}</p>}
                                        </div>
                                    </Popup>
                                </Marker>
                            ))}
                            {deliveries.filter(d => d.client_lat != null && d.client_lng != null && !['delivered', 'failed'].includes(d.status)).map(d => (
                                <Marker key={`client-${d.id}`} position={[d.client_lat!, d.client_lng!]} icon={clientIcon}>
                                    <Popup>
                                        <div>
                                            <p className="font-bold text-xs">Client — Cmd #{d.order_id}</p>
                                            {d.client_address && <p className="text-xs" style={{ color: '#64748b' }}>{d.client_address}</p>}
                                        </div>
                                    </Popup>
                                </Marker>
                            ))}
                        </MapContainer>
                    )}
                </div>
            ) : deliveries.length === 0 ? (
                <div className="text-center py-16">
                    <Package size={48} style={{ color: '#cbd5e1', margin: '0 auto' }} />
                    <p className="mt-3 font-medium" style={{ color: '#374151' }}>Aucune livraison trouvée</p>
                    <p className="text-sm" style={{ color: '#94a3b8' }}>Les livraisons apparaîtront ici une fois créées.</p>
                </div>
            ) : (
                <div className="rounded-2xl overflow-hidden" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                    <table className="w-full text-sm">
                        <thead>
                            <tr style={{ borderBottom: '1px solid #f1f5f9', background: '#f8fafc' }}>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>#</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Commande</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Livreur</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Adresse</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Frais</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Statut</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Date</th>
                                <th className="text-right px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {deliveries.map(d => {
                                const s = STATUS_CFG[d.status];
                                return (
                                    <tr key={d.id} className="table-row-hover" style={{ borderBottom: '1px solid #f8fafc' }}>
                                        <td className="px-5 py-3.5 font-medium" style={{ color: '#0f172a' }}>#{d.id}</td>
                                        <td className="px-5 py-3.5">
                                            <span className="font-medium" style={{ color: '#475569' }}>
                                                Cmd #{d.order_id}
                                            </span>
                                        </td>
                                        <td className="px-5 py-3.5">
                                            {d.driver ? (
                                                <div className="flex items-center gap-2">
                                                    <div className="w-7 h-7 rounded-full flex items-center justify-center text-white text-xs font-bold"
                                                        style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                                                        {d.driver.name.charAt(0).toUpperCase()}
                                                    </div>
                                                    <span style={{ color: '#475569' }}>{d.driver.name}</span>
                                                </div>
                                            ) : (
                                                <span style={{ color: '#cbd5e1' }}>Non assigné</span>
                                            )}
                                        </td>
                                        <td className="px-5 py-3.5">
                                            {d.client_address ? (
                                                <div className="flex items-center gap-1.5" style={{ color: '#475569' }}>
                                                    <MapPin size={13} />
                                                    <span className="truncate max-w-[160px]">{d.client_address}</span>
                                                </div>
                                            ) : (
                                                <span style={{ color: '#cbd5e1' }}>—</span>
                                            )}
                                        </td>
                                        <td className="px-5 py-3.5 font-medium" style={{ color: '#475569' }}>
                                            {d.fee > 0 ? `${d.fee.toLocaleString('fr-FR')} F` : '—'}
                                        </td>
                                        <td className="px-5 py-3.5">
                                            <span className="px-2.5 py-1 rounded-full text-xs font-semibold"
                                                style={{ background: s.bg, color: s.color, border: `1px solid ${s.border}` }}>
                                                {s.label}
                                            </span>
                                        </td>
                                        <td className="px-5 py-3.5 text-xs" style={{ color: '#94a3b8' }}>
                                            {formatDate(d.created_at)}
                                        </td>
                                        <td className="px-5 py-3.5 text-right">
                                            <div className="flex items-center justify-end gap-1.5">
                                                {d.status === 'pending_assignment' && (
                                                    <button
                                                        onClick={() => openAssign(d)}
                                                        className="px-3 py-1.5 rounded-lg text-xs font-medium"
                                                        style={{ background: '#eff6ff', color: '#2563eb', border: '1px solid #bfdbfe' }}
                                                    >
                                                        Assigner
                                                    </button>
                                                )}
                                                {d.status === 'assigned' && (
                                                    <button
                                                        onClick={() => handleStatusUpdate(d.id, 'picked_up')}
                                                        disabled={updatingStatusId === d.id}
                                                        className="px-3 py-1.5 rounded-lg text-xs font-medium disabled:opacity-50"
                                                        style={{ background: '#e0e7ff', color: '#3730a3', border: '1px solid #a5b4fc' }}
                                                    >
                                                        Récupérée
                                                    </button>
                                                )}
                                                {d.status === 'picked_up' && (
                                                    <button
                                                        onClick={() => handleStatusUpdate(d.id, 'on_way')}
                                                        disabled={updatingStatusId === d.id}
                                                        className="px-3 py-1.5 rounded-lg text-xs font-medium disabled:opacity-50"
                                                        style={{ background: '#fff7ed', color: '#c2410c', border: '1px solid #fed7aa' }}
                                                    >
                                                        En route
                                                    </button>
                                                )}
                                                {d.status === 'on_way' && (
                                                    <button
                                                        onClick={() => handleStatusUpdate(d.id, 'delivered')}
                                                        disabled={updatingStatusId === d.id}
                                                        className="px-3 py-1.5 rounded-lg text-xs font-medium disabled:opacity-50"
                                                        style={{ background: '#f0fdf4', color: '#16a34a', border: '1px solid #bbf7d0' }}
                                                    >
                                                        Livrée ✓
                                                    </button>
                                                )}
                                                {['assigned', 'picked_up', 'on_way'].includes(d.status) && (
                                                    <button
                                                        onClick={() => {
                                                            const reason = prompt('Raison de l\'échec (optionnel):');
                                                            handleStatusUpdate(d.id, 'failed', reason || undefined);
                                                        }}
                                                        disabled={updatingStatusId === d.id}
                                                        className="px-2 py-1.5 rounded-lg text-xs font-medium disabled:opacity-50"
                                                        style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}
                                                    >
                                                        ✕
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            )}

            {/* Assign Modal */}
            {assignModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.6)' }}>
                    <div className="w-full max-w-sm rounded-2xl overflow-hidden" style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
                        <div className="flex items-center justify-between px-6 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <h3 className="font-bold" style={{ color: '#0f172a' }}>Assigner un livreur</h3>
                            <button onClick={() => setAssignModal(null)} className="p-1 rounded-lg hover:bg-gray-100">
                                <XCircle size={18} style={{ color: '#64748b' }} />
                            </button>
                        </div>
                        <div className="p-6 space-y-4">
                            <p className="text-sm" style={{ color: '#475569' }}>
                                Livraison <strong>#{assignModal.id}</strong> — Commande <strong>#{assignModal.order_id}</strong>
                            </p>
                            {drivers.length === 0 ? (
                                <div className="text-center py-4">
                                    <User size={32} style={{ color: '#cbd5e1', margin: '0 auto' }} />
                                    <p className="text-sm mt-2" style={{ color: '#94a3b8' }}>Aucun livreur disponible</p>
                                </div>
                            ) : (
                                <div className="space-y-2 max-h-48 overflow-y-auto">
                                    {drivers.map(dr => (
                                        <button
                                            key={dr.id}
                                            onClick={() => setSelectedDriverId(dr.id)}
                                            className="flex items-center gap-3 w-full p-3 rounded-xl text-left transition-all"
                                            style={{
                                                background: selectedDriverId === dr.id ? '#fff7ed' : '#f8fafc',
                                                border: `2px solid ${selectedDriverId === dr.id ? '#f97316' : '#f1f5f9'}`,
                                            }}
                                        >
                                            <div className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold"
                                                style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                                                {dr.name.charAt(0).toUpperCase()}
                                            </div>
                                            <div className="flex-1">
                                                <p className="text-sm font-medium" style={{ color: '#0f172a' }}>{dr.name}</p>
                                                <p className="text-xs" style={{ color: '#94a3b8' }}>{dr.phone}{dr.zone ? ` · ${dr.zone}` : ''}</p>
                                            </div>
                                            {selectedDriverId === dr.id && <CheckCircle2 size={18} style={{ color: '#f97316' }} />}
                                        </button>
                                    ))}
                                </div>
                            )}
                        </div>
                        <div className="flex gap-3 px-6 py-4" style={{ borderTop: '1px solid #f1f5f9' }}>
                            <button onClick={() => setAssignModal(null)} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium" style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>
                                Annuler
                            </button>
                            <button onClick={handleAssign} disabled={!selectedDriverId || assigning} className="flex-1 btn-primary text-sm disabled:opacity-50">
                                {assigning ? 'En cours…' : 'Assigner'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
