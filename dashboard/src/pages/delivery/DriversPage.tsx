import { useCallback, useEffect, useState } from 'react';
import {
    Truck,
    Plus,
    Search,
    RefreshCw,
    X,
    MapPin,
    Phone,
    User,
    Edit2,
    Trash2,
} from 'lucide-react';
import { deliveryApi } from '../../services/api';
import type { DeliveryDriver, DriverStatus } from '../../types';

const STATUS_CFG: Record<DriverStatus, { label: string; bg: string; color: string; border: string }> = {
    available: { label: 'Disponible', bg: '#f0fdf4', color: '#16a34a', border: '#bbf7d0' },
    busy: { label: 'En course', bg: '#fff7ed', color: '#c2410c', border: '#fed7aa' },
    offline: { label: 'Hors ligne', bg: '#f8fafc', color: '#94a3b8', border: '#e2e8f0' },
};

export default function DriversPage() {
    const [drivers, setDrivers] = useState<DeliveryDriver[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [showModal, setShowModal] = useState(false);
    const [editDriver, setEditDriver] = useState<DeliveryDriver | null>(null);
    const [form, setForm] = useState({ name: '', phone: '', zone: '' });
    const [error, setError] = useState('');
    const [saving, setSaving] = useState(false);

    const fetchDrivers = useCallback(async () => {
        try {
            const res = await deliveryApi.getDrivers({
                search: search || undefined,
                status: statusFilter || undefined,
            });
            setDrivers(res.data.data?.data ?? res.data.data ?? []);
        } catch { /* silently ignore */ }
        finally { setIsLoading(false); }
    }, [search, statusFilter]);

    useEffect(() => { fetchDrivers(); }, [fetchDrivers]);

    const openCreate = () => {
        setEditDriver(null);
        setForm({ name: '', phone: '', zone: '' });
        setError('');
        setShowModal(true);
    };

    const openEdit = (d: DeliveryDriver) => {
        setEditDriver(d);
        setForm({ name: d.name, phone: d.phone, zone: d.zone ?? '' });
        setError('');
        setShowModal(true);
    };

    const handleSave = async () => {
        if (!form.name.trim() || !form.phone.trim()) {
            setError('Nom et téléphone sont obligatoires.');
            return;
        }
        setSaving(true);
        setError('');
        try {
            if (editDriver) {
                await deliveryApi.updateDriver(editDriver.id, {
                    name: form.name,
                    phone: form.phone,
                    zone: form.zone || undefined,
                });
            } else {
                await deliveryApi.createDriver({
                    name: form.name,
                    phone: form.phone,
                    zone: form.zone || undefined,
                });
            }
            setShowModal(false);
            fetchDrivers();
        } catch (e: unknown) {
            const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message;
            setError(msg || 'Erreur lors de la sauvegarde.');
        } finally { setSaving(false); }
    };

    const handleDelete = async (id: number) => {
        try {
            await deliveryApi.deleteDriver(id);
            fetchDrivers();
        } catch { /* ignore */ }
    };

    const toggleStatus = async (d: DeliveryDriver) => {
        const next: DriverStatus = d.status === 'available' ? 'offline' : 'available';
        await deliveryApi.updateDriver(d.id, { status: next });
        fetchDrivers();
    };

    // — Stats —
    const total = drivers.length;
    const available = drivers.filter(d => d.status === 'available').length;
    const busy = drivers.filter(d => d.status === 'busy').length;
    const offline = drivers.filter(d => d.status === 'offline').length;

    const stats = [
        { label: 'Total', value: total, gradient: 'linear-gradient(135deg,#3b82f6,#1d4ed8)', shadow: 'rgba(59,130,246,0.35)' },
        { label: 'Disponibles', value: available, gradient: 'linear-gradient(135deg,#22c55e,#15803d)', shadow: 'rgba(34,197,94,0.35)' },
        { label: 'En course', value: busy, gradient: 'linear-gradient(135deg,#f97316,#ea580c)', shadow: 'rgba(249,115,22,0.35)' },
        { label: 'Hors ligne', value: offline, gradient: 'linear-gradient(135deg,#64748b,#475569)', shadow: 'rgba(100,116,139,0.35)' },
    ];

    if (isLoading) {
        return (
            <div className="flex items-center justify-center h-64">
                <Truck className="h-8 w-8 animate-pulse" style={{ color: '#f97316' }} />
                <span className="ml-3 text-sm font-medium" style={{ color: '#64748b' }}>Chargement…</span>
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-fadeIn">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: '#0f172a' }}>Livreurs</h1>
                    <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>Gestion de votre flotte de livreurs</p>
                </div>
                <div className="flex gap-2">
                    <button onClick={() => fetchDrivers()} className="p-2.5 rounded-xl" style={{ background: 'white', border: '1px solid #e2e8f0', color: '#64748b' }}>
                        <RefreshCw size={16} />
                    </button>
                    <button onClick={openCreate} className="btn-primary text-sm flex items-center gap-1.5">
                        <Plus size={15} /> Ajouter un livreur
                    </button>
                </div>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                {stats.map(s => (
                    <div key={s.label} className="rounded-2xl p-5" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
                        <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: s.gradient, boxShadow: `0 4px 12px ${s.shadow}` }}>
                                <Truck size={16} className="text-white" />
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
            <div className="flex gap-3 flex-wrap">
                <div className="relative flex-1 min-w-[200px]">
                    <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: '#94a3b8' }} />
                    <input
                        className="input-pro pl-10 w-full"
                        placeholder="Rechercher un livreur…"
                        value={search}
                        onChange={e => setSearch(e.target.value)}
                    />
                </div>
                <div className="flex gap-1 p-1 rounded-xl" style={{ background: '#f1f5f9' }}>
                    {[{ key: '', label: 'Tous' }, { key: 'available', label: 'Dispo' }, { key: 'busy', label: 'En course' }, { key: 'offline', label: 'Hors ligne' }].map(f => (
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
            </div>

            {/* Table */}
            {drivers.length === 0 ? (
                <div className="text-center py-16">
                    <Truck size={48} style={{ color: '#cbd5e1', margin: '0 auto' }} />
                    <p className="mt-3 font-medium" style={{ color: '#374151' }}>Aucun livreur trouvé</p>
                    <p className="text-sm" style={{ color: '#94a3b8' }}>Ajoutez votre premier livreur pour commencer.</p>
                </div>
            ) : (
                <div className="rounded-2xl overflow-hidden" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                    <table className="w-full text-sm">
                        <thead>
                            <tr style={{ borderBottom: '1px solid #f1f5f9', background: '#f8fafc' }}>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Livreur</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Téléphone</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Zone</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Statut</th>
                                <th className="text-right px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {drivers.map(d => {
                                const s = STATUS_CFG[d.status];
                                return (
                                    <tr key={d.id} className="table-row-hover" style={{ borderBottom: '1px solid #f8fafc' }}>
                                        <td className="px-5 py-3.5">
                                            <div className="flex items-center gap-3">
                                                <div className="w-9 h-9 rounded-full flex items-center justify-center text-white text-xs font-bold"
                                                    style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                                                    {d.name.charAt(0).toUpperCase()}
                                                </div>
                                                <span className="font-medium" style={{ color: '#0f172a' }}>{d.name}</span>
                                            </div>
                                        </td>
                                        <td className="px-5 py-3.5">
                                            <div className="flex items-center gap-1.5" style={{ color: '#475569' }}>
                                                <Phone size={13} /> {d.phone}
                                            </div>
                                        </td>
                                        <td className="px-5 py-3.5">
                                            {d.zone ? (
                                                <div className="flex items-center gap-1.5" style={{ color: '#475569' }}>
                                                    <MapPin size={13} /> {d.zone}
                                                </div>
                                            ) : (
                                                <span style={{ color: '#cbd5e1' }}>—</span>
                                            )}
                                        </td>
                                        <td className="px-5 py-3.5">
                                            <button
                                                onClick={() => toggleStatus(d)}
                                                className="px-2.5 py-1 rounded-full text-xs font-semibold cursor-pointer"
                                                style={{ background: s.bg, color: s.color, border: `1px solid ${s.border}` }}
                                            >
                                                {s.label}
                                            </button>
                                        </td>
                                        <td className="px-5 py-3.5 text-right">
                                            <div className="flex gap-1 justify-end">
                                                <button onClick={() => openEdit(d)} className="p-2 rounded-lg hover:bg-gray-50" style={{ color: '#64748b' }}>
                                                    <Edit2 size={14} />
                                                </button>
                                                <button onClick={() => handleDelete(d.id)} className="p-2 rounded-lg hover:bg-red-50" style={{ color: '#ef4444' }}>
                                                    <Trash2 size={14} />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            )}

            {/* Modal Create / Edit */}
            {showModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.6)' }}>
                    <div className="w-full max-w-sm rounded-2xl overflow-hidden" style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
                        <div className="flex items-center justify-between px-6 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <h3 className="font-bold" style={{ color: '#0f172a' }}>{editDriver ? 'Modifier le livreur' : 'Nouveau livreur'}</h3>
                            <button onClick={() => setShowModal(false)} className="p-1 rounded-lg hover:bg-gray-100"><X size={18} style={{ color: '#64748b' }} /></button>
                        </div>
                        <div className="p-6 space-y-4">
                            {error && (
                                <div className="px-4 py-3 rounded-xl text-sm" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                                    {error}
                                </div>
                            )}
                            <div>
                                <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>
                                    <User size={12} className="inline mr-1" /> Nom
                                </label>
                                <input className="input-pro w-full" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="Nom complet" />
                            </div>
                            <div>
                                <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>
                                    <Phone size={12} className="inline mr-1" /> Téléphone
                                </label>
                                <input className="input-pro w-full" value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} placeholder="+226 70 00 00 00" />
                            </div>
                            <div>
                                <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>
                                    <MapPin size={12} className="inline mr-1" /> Zone
                                </label>
                                <input className="input-pro w-full" value={form.zone} onChange={e => setForm(f => ({ ...f, zone: e.target.value }))} placeholder="Ex: Ouagadougou Centre" />
                            </div>
                        </div>
                        <div className="flex gap-3 px-6 py-4" style={{ borderTop: '1px solid #f1f5f9' }}>
                            <button onClick={() => setShowModal(false)} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium" style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>
                                Annuler
                            </button>
                            <button onClick={handleSave} disabled={saving} className="flex-1 btn-primary text-sm">
                                {saving ? 'En cours…' : editDriver ? 'Modifier' : 'Créer'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
