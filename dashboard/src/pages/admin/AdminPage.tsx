import { useCallback, useEffect, useState } from 'react';
import {
    Users, Store, ShoppingBag, TrendingUp, Search, RefreshCw,
    Shield, ShieldOff, Trash2, Plus, X, Eye, EyeOff, Check,
    Activity, Edit2, FileText,
} from 'lucide-react';
import { adminApi } from '../../services/api';
import type { AdminAuditLog, AdminRestaurant, AdminStats, AdminUser } from '../../types';

// ── helpers ──────────────────────────────────────────────────────────────────

function fmt(n: number) {
    return n.toLocaleString('fr-FR');
}

function fmtFcfa(n: number) {
    if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1).replace('.', ',')} M FCFA`;
    if (n >= 1_000) return `${Math.round(n / 1_000)} k FCFA`;
    return `${fmt(n)} FCFA`;
}

function userInitials(name: string) {
    return name.split(' ').slice(0, 2).map(p => p[0]?.toUpperCase() ?? '').join('');
}

const GRAD: Record<number, string> = {
    0: 'linear-gradient(135deg,#f97316,#ea580c)',
    1: 'linear-gradient(135deg,#3b82f6,#1d4ed8)',
    2: 'linear-gradient(135deg,#22c55e,#15803d)',
    3: 'linear-gradient(135deg,#a855f7,#6d28d9)',
};
function avatarGrad(id: number) { return GRAD[id % 4]; }

// ── ConfirmModal ──────────────────────────────────────────────────────────────

function ConfirmModal({ message, onConfirm, onCancel }: { message: string; onConfirm: () => void; onCancel: () => void }) {
    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.6)' }}>
            <div className="w-full max-w-sm rounded-2xl overflow-hidden" style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
                <div className="p-6 space-y-3 text-center">
                    <div className="w-12 h-12 rounded-2xl flex items-center justify-center mx-auto" style={{ background: '#fef2f2' }}>
                        <Trash2 className="h-6 w-6" style={{ color: '#dc2626' }} />
                    </div>
                    <p className="font-bold text-base" style={{ color: '#0f172a' }}>Confirmer la suppression</p>
                    <p className="text-sm" style={{ color: '#64748b' }}>{message}</p>
                </div>
                <div className="flex gap-3 px-6 pb-6">
                    <button onClick={onCancel} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium"
                        style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>Annuler</button>
                    <button onClick={onConfirm} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium text-white"
                        style={{ background: 'linear-gradient(135deg,#dc2626,#b91c1c)' }}>Supprimer</button>
                </div>
            </div>
        </div>
    );
}

// ── CreateUserModal ───────────────────────────────────────────────────────────

interface UserForm { name: string; email: string; phone: string; password: string; is_admin: boolean }
const EMPTY_FORM: UserForm = { name: '', email: '', phone: '', password: '', is_admin: false };

function CreateUserModal({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
    const [form, setForm] = useState<UserForm>(EMPTY_FORM);
    const [showPwd, setShowPwd] = useState(false);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSaving(true); setError(null);
        try {
            await adminApi.createUser({ ...form, phone: form.phone || undefined });
            onSaved(); onClose();
        } catch (err: unknown) {
            const e = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
            const msg = e.response?.data?.message ?? 'Erreur lors de la création';
            const detail = e.response?.data?.errors ? Object.values(e.response.data.errors).flat().join(' · ') : '';
            setError(detail || msg);
        } finally { setSaving(false); }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.6)' }}>
            <div className="w-full max-w-md rounded-2xl overflow-hidden" style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
                <div className="flex items-center justify-between px-6 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <h2 className="text-base font-bold" style={{ color: '#0f172a' }}>Nouvel utilisateur</h2>
                    <button onClick={onClose} className="p-1.5 rounded-lg" style={{ color: '#94a3b8' }}><X size={18} /></button>
                </div>
                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {error && (
                        <div className="px-4 py-3 rounded-xl text-sm" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>{error}</div>
                    )}
                    <div className="grid grid-cols-2 gap-4">
                        <div className="col-span-2">
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Nom complet *</label>
                            <input required value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} className="input-pro" placeholder="Jean Dupont" />
                        </div>
                        <div>
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Email *</label>
                            <input required type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} className="input-pro" placeholder="jean@example.com" />
                        </div>
                        <div>
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Téléphone</label>
                            <input value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} className="input-pro" placeholder="+226 70 00 00 00" />
                        </div>
                        <div className="col-span-2">
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Mot de passe *</label>
                            <div className="relative">
                                <input required type={showPwd ? 'text' : 'password'} value={form.password}
                                    onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                                    className="input-pro pr-10" placeholder="••••••••" />
                                <button type="button" onClick={() => setShowPwd(v => !v)}
                                    className="absolute right-3 top-1/2 -translate-y-1/2" style={{ color: '#94a3b8' }}>
                                    {showPwd ? <EyeOff size={16} /> : <Eye size={16} />}
                                </button>
                            </div>
                        </div>
                    </div>
                    <label className="flex items-center gap-2.5 cursor-pointer select-none">
                        <div onClick={() => setForm(f => ({ ...f, is_admin: !f.is_admin }))}
                            className="w-5 h-5 rounded-md flex items-center justify-center flex-shrink-0 transition-colors"
                            style={{ background: form.is_admin ? '#f97316' : 'white', border: `2px solid ${form.is_admin ? '#f97316' : '#d1d5db'}` }}>
                            {form.is_admin && <Check size={12} color="white" strokeWidth={3} />}
                        </div>
                        <span className="text-sm" style={{ color: '#374151' }}>Accès Super Admin</span>
                    </label>
                    <div className="flex gap-3 pt-1">
                        <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium"
                            style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>Annuler</button>
                        <button type="submit" disabled={saving} className="flex-1 btn-primary">
                            {saving ? 'Création…' : 'Créer'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}

// ── EditUserModal ─────────────────────────────────────────────────────────────

function EditUserModal({ user, onClose, onSaved }: { user: AdminUser; onClose: () => void; onSaved: () => void }) {
    const [form, setForm] = useState({ name: user.name, email: user.email, phone: user.phone ?? '' });
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSaving(true); setError(null);
        try {
            await adminApi.updateUser(user.id, { name: form.name, email: form.email, phone: form.phone || undefined });
            onSaved(); onClose();
        } catch (err: unknown) {
            const e = err as { response?: { data?: { message?: string } } };
            setError(e.response?.data?.message ?? 'Erreur lors de la mise à jour');
        } finally { setSaving(false); }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.6)' }}>
            <div className="w-full max-w-sm rounded-2xl overflow-hidden" style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
                <div className="flex items-center justify-between px-6 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <h2 className="text-base font-bold" style={{ color: '#0f172a' }}>Modifier l'utilisateur</h2>
                    <button onClick={onClose} className="p-1.5 rounded-lg" style={{ color: '#94a3b8' }}><X size={18} /></button>
                </div>
                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {error && (
                        <div className="px-4 py-3 rounded-xl text-sm" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>{error}</div>
                    )}
                    <div>
                        <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Nom complet</label>
                        <input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} className="input-pro" />
                    </div>
                    <div>
                        <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Email</label>
                        <input type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} className="input-pro" />
                    </div>
                    <div>
                        <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Téléphone</label>
                        <input value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} className="input-pro" placeholder="+226 70 00 00 00" />
                    </div>
                    <div className="flex gap-3 pt-1">
                        <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium"
                            style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>Annuler</button>
                        <button type="submit" disabled={saving} className="flex-1 btn-primary">{saving ? 'Sauvegarde…' : 'Sauvegarder'}</button>
                    </div>
                </form>
            </div>
        </div>
    );
}

// ── StatCard ──────────────────────────────────────────────────────────────────

function StatCard({ label, value, sub, icon: Icon, grad, shadow }: {
    label: string; value: string; sub?: string;
    icon: React.ElementType; grad: string; shadow: string;
}) {
    return (
        <div className="rounded-2xl p-5" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
            <div className="flex items-center justify-between mb-4">
                <span className="text-xs font-semibold uppercase tracking-wide" style={{ color: '#94a3b8' }}>{label}</span>
                <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: grad, boxShadow: `0 4px 12px ${shadow}` }}>
                    <Icon className="h-4.5 w-4.5 text-white" style={{ width: 18, height: 18 }} />
                </div>
            </div>
            <p className="text-3xl font-black" style={{ color: '#0f172a' }}>{value}</p>
            {sub && <p className="text-xs mt-1" style={{ color: '#94a3b8' }}>{sub}</p>}
        </div>
    );
}

// ── UserRow ───────────────────────────────────────────────────────────────────

function UserRow({ user, onToggleAdmin, onEdit, onDelete }: {
    user: AdminUser;
    onToggleAdmin: () => void;
    onEdit: () => void;
    onDelete: () => void;
}) {
    const grad = avatarGrad(user.id);
    const initials = userInitials(user.name);
    return (
        <tr className="table-row-hover" style={{ borderBottom: '1px solid #f8fafc' }}>
            <td className="px-5 py-3.5">
                <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm flex-shrink-0 text-white"
                        style={{ background: grad }}>
                        {initials || '?'}
                    </div>
                    <div className="min-w-0">
                        <p className="font-semibold text-sm truncate" style={{ color: '#0f172a' }}>{user.name}</p>
                        <p className="text-xs truncate" style={{ color: '#94a3b8' }}>{user.email}</p>
                        {user.phone && <p className="text-xs" style={{ color: '#94a3b8' }}>{user.phone}</p>}
                    </div>
                </div>
            </td>
            <td className="px-5 py-3.5">
                {user.is_admin ? (
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold"
                        style={{ background: '#fff7ed', color: '#c2410c', border: '1px solid #fed7aa' }}>
                        <Shield size={11} /> Super Admin
                    </span>
                ) : (
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold"
                        style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>
                        Utilisateur
                    </span>
                )}
            </td>
            <td className="px-5 py-3.5 text-sm text-center" style={{ color: '#374151' }}>
                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-lg text-xs font-semibold"
                    style={{ background: '#f0fdf4', color: '#16a34a' }}>
                    <Store size={10} /> {user.restaurants_count}
                </span>
            </td>
            <td className="px-5 py-3.5 text-xs" style={{ color: '#94a3b8' }}>
                {new Date(user.created_at).toLocaleDateString('fr-FR')}
            </td>
            <td className="px-5 py-3.5 text-right">
                <div className="flex items-center justify-end gap-1.5">
                    <button onClick={onEdit} title="Modifier" className="p-1.5 rounded-lg transition-colors" style={{ color: '#94a3b8' }}
                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#eff6ff'; (e.currentTarget as HTMLButtonElement).style.color = '#2563eb'; }}
                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                        <Edit2 size={14} />
                    </button>
                    <button onClick={onToggleAdmin} title={user.is_admin ? 'Retirer admin' : 'Accorder admin'}
                        className="p-1.5 rounded-lg transition-colors" style={{ color: '#94a3b8' }}
                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fff7ed'; (e.currentTarget as HTMLButtonElement).style.color = '#f97316'; }}
                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                        {user.is_admin ? <ShieldOff size={14} /> : <Shield size={14} />}
                    </button>
                    <button onClick={onDelete} title="Supprimer" className="p-1.5 rounded-lg transition-colors" style={{ color: '#94a3b8' }}
                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fef2f2'; (e.currentTarget as HTMLButtonElement).style.color = '#dc2626'; }}
                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                        <Trash2 size={14} />
                    </button>
                </div>
            </td>
        </tr>
    );
}

// ── RestaurantRow ─────────────────────────────────────────────────────────────

function RestaurantRow({
    restaurant, onToggle, onLicenseChange,
}: {
    restaurant: AdminRestaurant;
    onToggle: () => void;
    onLicenseChange: (status: 'active' | 'suspended' | 'expired' | 'trial') => void;
}) {
    return (
        <tr className="table-row-hover" style={{ borderBottom: '1px solid #f8fafc', opacity: restaurant.is_active ? 1 : 0.6 }}>
            <td className="px-5 py-3.5">
                <div className="flex items-center gap-3">
                    {restaurant.logo_url ? (
                        <img src={restaurant.logo_url} alt="" className="w-9 h-9 rounded-xl object-cover flex-shrink-0" style={{ border: '1px solid #f1f5f9' }} />
                    ) : (
                        <div className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0" style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                            <Store size={16} className="text-white" />
                        </div>
                    )}
                    <div className="min-w-0">
                        <p className="font-semibold text-sm truncate" style={{ color: '#0f172a' }}>{restaurant.nom}</p>
                        <p className="text-xs truncate" style={{ color: '#94a3b8' }}>{restaurant.adresse}</p>
                    </div>
                </div>
            </td>
            <td className="px-5 py-3.5 text-sm" style={{ color: '#374151' }}>
                <p className="font-medium">{restaurant.user?.name ?? '—'}</p>
                <p className="text-xs" style={{ color: '#94a3b8' }}>{restaurant.user?.email}</p>
            </td>
            <td className="px-5 py-3.5 text-xs text-center" style={{ color: '#64748b' }}>
                {restaurant.orders_count}
            </td>
            <td className="px-5 py-3.5">
                <button onClick={onToggle}
                    className="text-xs px-2.5 py-1 rounded-lg font-semibold transition-colors"
                    style={restaurant.is_active
                        ? { background: '#f0fdf4', color: '#16a34a', border: '1px solid #bbf7d0' }
                        : { background: '#f8fafc', color: '#94a3b8', border: '1px solid #e2e8f0' }}>
                    {restaurant.is_active ? <><Check size={12} className="inline mr-0.5" />Actif</> : 'Inactif'}
                </button>
            </td>
            <td className="px-5 py-3.5">
                <select
                    value={restaurant.license_status ?? 'active'}
                    onChange={(e) => onLicenseChange(e.target.value as 'active' | 'suspended' | 'expired' | 'trial')}
                    className="text-xs px-2.5 py-1.5 rounded-lg font-semibold"
                    style={{ background: '#f8fafc', color: '#334155', border: '1px solid #e2e8f0' }}
                >
                    <option value="active">Active</option>
                    <option value="trial">Trial</option>
                    <option value="suspended">Suspendue</option>
                    <option value="expired">Expirée</option>
                </select>
            </td>
            <td className="px-5 py-3.5 text-xs" style={{ color: '#94a3b8' }}>
                {new Date(restaurant.created_at).toLocaleDateString('fr-FR')}
            </td>
        </tr>
    );
}

// ── Main page ─────────────────────────────────────────────────────────────────

type Tab = 'users' | 'restaurants' | 'logs';

export default function AdminPage() {
    const [tab, setTab] = useState<Tab>('users');
    const [stats, setStats] = useState<AdminStats | null>(null);
    const [users, setUsers] = useState<AdminUser[]>([]);
    const [restaurants, setRestaurants] = useState<AdminRestaurant[]>([]);
    const [auditLogs, setAuditLogs] = useState<AdminAuditLog[]>([]);
    const [userSearch, setUserSearch] = useState('');
    const [restSearch, setRestSearch] = useState('');
    const [isLoading, setIsLoading] = useState(true);
    const [isRefreshing, setIsRefreshing] = useState(false);
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [editUser, setEditUser] = useState<AdminUser | null>(null);
    const [confirmDelete, setConfirmDelete] = useState<AdminUser | null>(null);

    const loadStats = useCallback(async () => {
        try {
            const r = await adminApi.getStats();
            setStats(r.data.data);
        } catch { /* non-bloquant */ }
    }, []);

    const loadUsers = useCallback(async () => {
        try {
            const r = await adminApi.listUsers({ search: userSearch || undefined, per_page: 50 });
            const payload = r.data.data;
            setUsers(payload.data ?? payload);
        } catch { /* ignore */ }
    }, [userSearch]);

    const loadRestaurants = useCallback(async () => {
        try {
            const r = await adminApi.listRestaurants({ search: restSearch || undefined, per_page: 50 });
            const payload = r.data.data;
            setRestaurants(payload.data ?? payload);
        } catch { /* ignore */ }
    }, [restSearch]);

    const loadAuditLogs = useCallback(async () => {
        try {
            const r = await adminApi.listAuditLogs({ per_page: 50 });
            const payload = r.data.data;
            setAuditLogs(payload.data ?? payload);
        } catch { /* ignore */ }
    }, []);

    const loadAll = useCallback(async (silent = false) => {
        if (!silent) setIsRefreshing(true);
        await Promise.all([loadStats(), loadUsers(), loadRestaurants(), loadAuditLogs()]);
        setIsLoading(false);
        setIsRefreshing(false);
    }, [loadStats, loadUsers, loadRestaurants, loadAuditLogs]);

    useEffect(() => { loadAll(); }, [loadAll]);

    // Re-filter users on search change
    useEffect(() => { loadUsers(); }, [loadUsers]);
    useEffect(() => { loadRestaurants(); }, [loadRestaurants]);
    useEffect(() => { loadAuditLogs(); }, [loadAuditLogs]);

    const handleToggleAdmin = async (user: AdminUser) => {
        try {
            await adminApi.toggleAdmin(user.id);
            loadUsers(); loadStats();
        } catch { /* ignore */ }
    };

    const handleDeleteUser = async (user: AdminUser) => {
        try {
            await adminApi.deleteUser(user.id);
            setConfirmDelete(null);
            loadUsers(); loadStats();
        } catch { /* ignore */ }
    };

    const handleToggleRestaurant = async (r: AdminRestaurant) => {
        try {
            await adminApi.toggleRestaurantActive(r.id);
            loadRestaurants(); loadStats();
        } catch { /* ignore */ }
    };

    const handleLicenseStatusChange = async (
        restaurant: AdminRestaurant,
        status: 'active' | 'suspended' | 'expired' | 'trial'
    ) => {
        try {
            await adminApi.updateRestaurantLicense(restaurant.id, {
                license_status: status,
                license_plan: restaurant.license_plan ?? null,
                license_expires_at: restaurant.license_expires_at ?? null,
                license_max_staff: restaurant.license_max_staff ?? null,
            });
            loadRestaurants();
            loadAuditLogs();
        } catch { /* ignore */ }
    };

    if (isLoading) {
        return (
            <div className="flex items-center justify-center min-h-96">
                <div className="flex flex-col items-center gap-3">
                    <div className="w-12 h-12 rounded-2xl flex items-center justify-center animate-pulse"
                        style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                        <Activity className="h-6 w-6 text-white" />
                    </div>
                    <p className="text-sm font-medium" style={{ color: '#64748b' }}>Chargement…</p>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-fadeIn">

            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: '#0f172a' }}>Super Admin</h1>
                    <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>Vue plateforme — gestion globale</p>
                </div>
                <button onClick={() => loadAll()} disabled={isRefreshing}
                    className="p-2.5 rounded-xl transition-all disabled:opacity-50"
                    style={{ background: 'white', border: '1px solid #e2e8f0', color: '#64748b' }}>
                    <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
                </button>
            </div>

            {/* Platform stat cards */}
            {stats && (
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                    <StatCard label="Utilisateurs" value={fmt(stats.users.total)}
                        sub={`+${stats.users.this_month} ce mois`}
                        icon={Users} grad="linear-gradient(135deg,#f97316,#ea580c)" shadow="rgba(249,115,22,0.25)" />
                    <StatCard label="Restaurants" value={fmt(stats.restaurants.total)}
                        sub={`${stats.restaurants.active} actifs`}
                        icon={Store} grad="linear-gradient(135deg,#3b82f6,#1d4ed8)" shadow="rgba(59,130,246,0.25)" />
                    <StatCard label="Commandes" value={fmt(stats.orders.total)}
                        sub={`${stats.orders.today} aujourd'hui · ${stats.orders.pending} en attente`}
                        icon={ShoppingBag} grad="linear-gradient(135deg,#22c55e,#15803d)" shadow="rgba(34,197,94,0.25)" />
                    <StatCard label="Revenu total" value={fmtFcfa(stats.revenue.total)}
                        sub={`${fmtFcfa(stats.revenue.this_month)} ce mois`}
                        icon={TrendingUp} grad="linear-gradient(135deg,#a855f7,#6d28d9)" shadow="rgba(168,85,247,0.25)" />
                </div>
            )}

            {/* Tab navigation */}
            <div className="flex gap-1 p-1 rounded-xl" style={{ background: '#f1f5f9', width: 'fit-content' }}>
                {([
                    { key: 'users', label: `Utilisateurs (${users.length})`, icon: Users },
                    { key: 'restaurants', label: `Restaurants (${restaurants.length})`, icon: Store },
                    { key: 'logs', label: `Journaux (${auditLogs.length})`, icon: FileText },
                ] as { key: Tab; label: string; icon: React.ElementType }[]).map(t => (
                    <button key={t.key} onClick={() => setTab(t.key)}
                        className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all"
                        style={tab === t.key
                            ? { background: 'white', color: '#0f172a', boxShadow: '0 1px 4px rgba(0,0,0,0.08)' }
                            : { color: '#64748b' }}>
                        <t.icon size={15} />{t.label}
                    </button>
                ))}
            </div>

            {/* ── USERS TAB ── */}
            {tab === 'users' && (
                <div className="space-y-4">
                    <div className="flex items-center gap-3 flex-wrap">
                        <div className="relative flex-1 min-w-56">
                            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: '#94a3b8' }} />
                            <input value={userSearch} onChange={e => setUserSearch(e.target.value)}
                                placeholder="Rechercher un utilisateur…" className="input-pro pl-10 w-full" />
                        </div>
                        <button onClick={() => setShowCreateModal(true)} className="btn-primary text-sm">
                            <Plus size={15} /> Nouvel utilisateur
                        </button>
                    </div>

                    <div className="rounded-2xl overflow-hidden" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                        {users.length === 0 ? (
                            <div className="text-center py-16">
                                <Users className="h-10 w-10 mx-auto mb-3" style={{ color: '#cbd5e1' }} />
                                <p className="font-medium" style={{ color: '#374151' }}>Aucun utilisateur trouvé</p>
                            </div>
                        ) : (
                            <table className="w-full text-sm">
                                <thead>
                                    <tr style={{ borderBottom: '1px solid #f1f5f9', background: '#f8fafc' }}>
                                        {['Utilisateur', 'Rôle', 'Restaurants', 'Inscrit le', 'Actions'].map(h => (
                                            <th key={h} className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>{h}</th>
                                        ))}
                                    </tr>
                                </thead>
                                <tbody>
                                    {users.map(u => (
                                        <UserRow key={u.id} user={u}
                                            onToggleAdmin={() => handleToggleAdmin(u)}
                                            onEdit={() => setEditUser(u)}
                                            onDelete={() => setConfirmDelete(u)} />
                                    ))}
                                </tbody>
                            </table>
                        )}
                    </div>
                </div>
            )}

            {/* ── RESTAURANTS TAB ── */}
            {tab === 'restaurants' && (
                <div className="space-y-4">
                    <div className="relative max-w-md">
                        <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: '#94a3b8' }} />
                        <input value={restSearch} onChange={e => setRestSearch(e.target.value)}
                            placeholder="Rechercher un restaurant…" className="input-pro pl-10 w-full" />
                    </div>

                    <div className="rounded-2xl overflow-hidden" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                        {restaurants.length === 0 ? (
                            <div className="text-center py-16">
                                <Store className="h-10 w-10 mx-auto mb-3" style={{ color: '#cbd5e1' }} />
                                <p className="font-medium" style={{ color: '#374151' }}>Aucun restaurant trouvé</p>
                            </div>
                        ) : (
                            <table className="w-full text-sm">
                                <thead>
                                    <tr style={{ borderBottom: '1px solid #f1f5f9', background: '#f8fafc' }}>
                                        {['Restaurant', 'Propriétaire', 'Commandes', 'Activation', 'Licence', 'Créé le'].map(h => (
                                            <th key={h} className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>{h}</th>
                                        ))}
                                    </tr>
                                </thead>
                                <tbody>
                                    {restaurants.map(r => (
                                        <RestaurantRow
                                            key={r.id}
                                            restaurant={r}
                                            onToggle={() => handleToggleRestaurant(r)}
                                            onLicenseChange={(status) => handleLicenseStatusChange(r, status)}
                                        />
                                    ))}
                                </tbody>
                            </table>
                        )}
                    </div>
                </div>
            )}

            {/* ── LOGS TAB ── */}
            {tab === 'logs' && (
                <div className="rounded-2xl overflow-hidden" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                    {auditLogs.length === 0 ? (
                        <div className="text-center py-16">
                            <FileText className="h-10 w-10 mx-auto mb-3" style={{ color: '#cbd5e1' }} />
                            <p className="font-medium" style={{ color: '#374151' }}>Aucun journal d’audit</p>
                        </div>
                    ) : (
                        <table className="w-full text-sm">
                            <thead>
                                <tr style={{ borderBottom: '1px solid #f1f5f9', background: '#f8fafc' }}>
                                    {['Action', 'Cible', 'Admin', 'Date'].map(h => (
                                        <th key={h} className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>{h}</th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody>
                                {auditLogs.map((log) => (
                                    <tr key={log.id} style={{ borderBottom: '1px solid #f8fafc' }}>
                                        <td className="px-5 py-3.5 text-xs font-semibold" style={{ color: '#0f172a' }}>{log.action}</td>
                                        <td className="px-5 py-3.5 text-xs" style={{ color: '#64748b' }}>
                                            {log.target_type ?? '—'}{log.target_id ? ` #${log.target_id}` : ''}
                                        </td>
                                        <td className="px-5 py-3.5 text-xs" style={{ color: '#64748b' }}>
                                            {log.admin_user?.name ?? 'Système'}
                                        </td>
                                        <td className="px-5 py-3.5 text-xs" style={{ color: '#94a3b8' }}>
                                            {new Date(log.created_at).toLocaleString('fr-FR')}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )}
                </div>
            )}

            {/* Modals */}
            {showCreateModal && (
                <CreateUserModal onClose={() => setShowCreateModal(false)} onSaved={() => { loadUsers(); loadStats(); }} />
            )}
            {editUser && (
                <EditUserModal user={editUser} onClose={() => setEditUser(null)} onSaved={() => { loadUsers(); setEditUser(null); }} />
            )}
            {confirmDelete && (
                <ConfirmModal
                    message={`Supprimer l'utilisateur « ${confirmDelete.name} » ? Cette action est irréversible.`}
                    onConfirm={() => handleDeleteUser(confirmDelete)}
                    onCancel={() => setConfirmDelete(null)}
                />
            )}
        </div>
    );
}
