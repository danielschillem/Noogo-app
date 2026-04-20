import { useState, useEffect, useCallback } from 'react';
import { useParams } from 'react-router-dom';
import {
    Users, Plus, Trash2, Edit2, Check, X, ShieldCheck, ChefHat,
    CreditCard, UtensilsCrossed, Search, UserCheck, UserX,
    LayoutGrid, List,
} from 'lucide-react';
import { staffApi } from '../../services/api';
import type { StaffMember, StaffRole } from '../../types';
import { STAFF_ROLE_LABELS } from '../../types';

const ROLE_STYLE: Record<string, { bg: string; color: string; border: string; grad: string }> = {
    owner: { bg: '#fff7ed', color: '#c2410c', border: '#fed7aa', grad: 'linear-gradient(135deg,#f97316,#ea580c)' },
    manager: { bg: '#eff6ff', color: '#1d4ed8', border: '#bfdbfe', grad: 'linear-gradient(135deg,#3b82f6,#1d4ed8)' },
    cashier: { bg: '#f0fdf4', color: '#15803d', border: '#bbf7d0', grad: 'linear-gradient(135deg,#22c55e,#15803d)' },
    waiter: { bg: '#faf5ff', color: '#6d28d9', border: '#ddd6fe', grad: 'linear-gradient(135deg,#a855f7,#6d28d9)' },
};

const ROLE_ICONS: Record<StaffRole, React.ReactNode> = {
    owner: <ShieldCheck size={14} />,
    manager: <ChefHat size={14} />,
    cashier: <CreditCard size={14} />,
    waiter: <UtensilsCrossed size={14} />,
};

const ROLE_PERMISSIONS_FR: Record<string, string> = {
    manage_staff: 'Gérer le personnel',
    edit_restaurant: 'Modifier le restaurant',
    manage_menu: 'Gérer le menu',
    manage_orders: 'Gérer les commandes',
    view_stats: 'Voir les stats',
};

function StaffAvatar({ member, size = 40 }: { member: StaffMember; size?: number }) {
    const st = ROLE_STYLE[member.role] ?? ROLE_STYLE.waiter;
    const initials = member.name.split(' ').slice(0, 2).map(p => p[0]?.toUpperCase() ?? '').join('');
    return (
        <div style={{
            width: size, height: size, borderRadius: size * 0.3,
            background: st.grad, display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0, color: '#fff', fontWeight: 700, fontSize: size * 0.35,
            boxShadow: `0 3px 10px ${st.border}`, letterSpacing: 0.5,
        }}>
            {initials || '?'}
        </div>
    );
}

function ConfirmModal({ message, onConfirm, onCancel }: { message: string; onConfirm: () => void; onCancel: () => void }) {
    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.55)' }}>
            <div className="w-full max-w-sm rounded-2xl overflow-hidden" style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
                <div className="p-6 text-center space-y-3">
                    <div className="w-12 h-12 rounded-2xl flex items-center justify-center mx-auto" style={{ background: '#fef2f2' }}>
                        <Trash2 className="h-6 w-6" style={{ color: '#dc2626' }} />
                    </div>
                    <p className="font-bold text-base" style={{ color: '#0f172a' }}>Confirmer la suppression</p>
                    <p className="text-sm" style={{ color: '#64748b' }}>{message}</p>
                </div>
                <div className="flex gap-3 px-6 pb-6">
                    <button onClick={onCancel} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium" style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>Annuler</button>
                    <button onClick={onConfirm} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium text-white" style={{ background: 'linear-gradient(135deg,#dc2626,#b91c1c)' }}>Supprimer</button>
                </div>
            </div>
        </div>
    );
}

function EditRoleModal({ member, restaurantId, onClose, onSaved }: { member: StaffMember; restaurantId: string; onClose: () => void; onSaved: () => void }) {
    const [role, setRole] = useState<StaffRole>(member.role);
    const [saving, setSaving] = useState(false);
    const st = ROLE_STYLE[role] ?? ROLE_STYLE.waiter;
    const handleSave = async () => {
        setSaving(true);
        try { await staffApi.update(Number(restaurantId), member.id, { role }); onSaved(); onClose(); }
        catch { alert('Erreur lors de la mise à jour'); }
        finally { setSaving(false); }
    };
    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.55)' }}>
            <div className="w-full max-w-sm rounded-2xl overflow-hidden" style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
                <div className="flex items-center justify-between px-6 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <h2 className="text-base font-bold" style={{ color: '#0f172a' }}>Modifier le rôle</h2>
                    <button onClick={onClose} className="p-1.5 rounded-lg" style={{ color: '#94a3b8' }}><X size={18} /></button>
                </div>
                <div className="p-6 space-y-4">
                    <div className="flex items-center gap-3">
                        <StaffAvatar member={member} size={44} />
                        <div>
                            <p className="font-semibold text-sm" style={{ color: '#0f172a' }}>{member.name}</p>
                            <p className="text-xs" style={{ color: '#94a3b8' }}>{member.email}</p>
                        </div>
                    </div>
                    <div>
                        <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Rôle</label>
                        <select value={role} onChange={e => setRole(e.target.value as StaffRole)} className="input-pro">
                            <option value="manager">Gérant</option>
                            <option value="cashier">Caissier</option>
                            <option value="waiter">Serveur</option>
                        </select>
                    </div>
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold" style={{ background: st.bg, color: st.color, border: `1px solid ${st.border}` }}>
                        {ROLE_ICONS[role]} Aperçu : {STAFF_ROLE_LABELS[role]}
                    </span>
                    <div className="flex gap-3 pt-1">
                        <button onClick={onClose} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium" style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>Annuler</button>
                        <button onClick={handleSave} disabled={saving} className="flex-1 btn-primary">{saving ? 'Sauvegarde…' : 'Sauvegarder'}</button>
                    </div>
                </div>
            </div>
        </div>
    );
}

function StaffCardGrid({ staff, onToggleActive, onEdit, onRemove }: {
    staff: StaffMember[];
    onToggleActive: (m: StaffMember) => void;
    onEdit: (m: StaffMember) => void;
    onRemove: (m: StaffMember) => void;
}) {
    return (
        <div className="grid gap-4" style={{ gridTemplateColumns: 'repeat(auto-fill,minmax(220px,1fr))' }}>
            {staff.map(member => {
                const st = ROLE_STYLE[member.role] ?? ROLE_STYLE.waiter;
                const initials = member.name.split(' ').slice(0, 2).map(p => p[0]?.toUpperCase() ?? '').join('');
                return (
                    <div key={member.id} className="rounded-2xl overflow-hidden flex flex-col transition-all duration-200"
                        style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 2px 8px rgba(0,0,0,0.05)', opacity: member.is_active ? 1 : 0.6 }}>
                        {/* Gradient header */}
                        <div className="relative h-20 flex-shrink-0" style={{ background: st.grad }}>
                            <div className="absolute -bottom-7 left-1/2 -translate-x-1/2">
                                <div style={{ width: 52, height: 52, borderRadius: 16, background: 'white', padding: 3, boxShadow: '0 4px 12px rgba(0,0,0,0.12)' }}>
                                    <div style={{ width: '100%', height: '100%', borderRadius: 13, background: st.grad, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontWeight: 700, fontSize: 18 }}>
                                        {initials || '?'}
                                    </div>
                                </div>
                            </div>
                        </div>
                        {/* Body */}
                        <div className="pt-9 pb-3 px-4 text-center">
                            <p className="font-bold text-sm" style={{ color: '#0f172a' }}>{member.name}</p>
                            <p className="text-xs mb-2" style={{ color: '#94a3b8' }}>{member.email}</p>
                            {member.phone && <p className="text-xs mb-2" style={{ color: '#94a3b8' }}>{member.phone}</p>}
                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold" style={{ background: st.bg, color: st.color, border: `1px solid ${st.border}` }}>
                                {ROLE_ICONS[member.role]} {member.role_label}
                            </span>
                        </div>
                        {/* Permissions */}
                        {member.permissions.length > 0 && (
                            <div className="px-4 pb-3 flex flex-wrap gap-1 justify-center">
                                {member.permissions.slice(0, 3).map(p => (
                                    <span key={p} className="text-[10px] px-1.5 py-0.5 rounded font-medium" style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>
                                        {ROLE_PERMISSIONS_FR[p] ?? p}
                                    </span>
                                ))}
                                {member.permissions.length > 3 && (
                                    <span className="text-[10px] px-1.5 py-0.5 rounded font-medium" style={{ background: '#f8fafc', color: '#94a3b8' }}>+{member.permissions.length - 3}</span>
                                )}
                            </div>
                        )}
                        {/* Actions */}
                        <div className="flex items-center border-t px-3 py-2.5 gap-1.5 mt-auto" style={{ borderColor: '#f1f5f9' }}>
                            <button onClick={() => onToggleActive(member)}
                                className="flex-1 text-xs py-1.5 rounded-lg font-semibold transition-colors"
                                style={member.is_active ? { background: '#f0fdf4', color: '#16a34a', border: '1px solid #bbf7d0' } : { background: '#f8fafc', color: '#94a3b8', border: '1px solid #e2e8f0' }}>
                                {member.is_active ? '✓ Actif' : 'Inactif'}
                            </button>
                            {member.role !== 'owner' && (
                                <>
                                    <button onClick={() => onEdit(member)}
                                        className="p-1.5 rounded-lg transition-colors" style={{ color: '#94a3b8' }}
                                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#eff6ff'; (e.currentTarget as HTMLButtonElement).style.color = '#2563eb'; }}
                                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                                        <Edit2 size={14} />
                                    </button>
                                    <button onClick={() => onRemove(member)}
                                        className="p-1.5 rounded-lg transition-colors" style={{ color: '#94a3b8' }}
                                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fef2f2'; (e.currentTarget as HTMLButtonElement).style.color = '#dc2626'; }}
                                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                                        <Trash2 size={14} />
                                    </button>
                                </>
                            )}
                        </div>
                    </div>
                );
            })}
        </div>
    );
}

interface StaffForm { name: string; email: string; phone: string; role: StaffRole; password: string; }
const EMPTY_FORM: StaffForm = { name: '', email: '', phone: '', role: 'waiter', password: '' };

function AddMemberModal({ onClose, onSaved, restaurantId }: { onClose: () => void; onSaved: () => void; restaurantId: string; }) {
    const [form, setForm] = useState<StaffForm>(EMPTY_FORM);
    const [submitting, setSubmitting] = useState(false);
    const [formError, setFormError] = useState<string | null>(null);

    const handleCreate = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true); setFormError(null);
        try {
            await staffApi.create(Number(restaurantId), {
                name: form.name, email: form.email,
                phone: form.phone || undefined, role: form.role, password: form.password || undefined,
            });
            onSaved(); onClose();
        } catch (err: unknown) {
            const e = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
            const msg = e.response?.data?.message ?? "Erreur lors de l'ajout";
            const detail = e.response?.data?.errors ? Object.values(e.response.data.errors).flat().join(' · ') : '';
            setFormError(detail || msg);
        } finally { setSubmitting(false); }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.55)' }}>
            <div className="w-full max-w-lg rounded-2xl overflow-hidden" style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
                <div className="flex items-center justify-between px-6 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <h2 className="text-base font-bold" style={{ color: '#0f172a' }}>Nouveau membre</h2>
                    <button onClick={onClose} className="p-1.5 rounded-lg" style={{ color: '#94a3b8' }}><X size={18} /></button>
                </div>
                <form onSubmit={handleCreate} className="p-6 space-y-4">
                    {formError && <div className="px-4 py-3 rounded-xl text-sm" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>{formError}</div>}
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Nom complet *</label>
                            <input required value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} className="input-pro" placeholder="Jean Dupont" />
                        </div>
                        <div>
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Email *</label>
                            <input required type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} className="input-pro" placeholder="jean@example.com" />
                        </div>
                        <div>
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Téléphone</label>
                            <input value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} className="input-pro" placeholder="+226 70000000" />
                        </div>
                        <div>
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Rôle *</label>
                            <select value={form.role} onChange={e => setForm(f => ({ ...f, role: e.target.value as StaffRole }))} className="input-pro">
                                <option value="manager">Gérant</option>
                                <option value="cashier">Caissier</option>
                                <option value="waiter">Serveur</option>
                            </select>
                        </div>
                        <div className="col-span-2">
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Mot de passe <span style={{ color: '#94a3b8', fontWeight: 400 }}>(optionnel)</span></label>
                            <input type="password" value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))} className="input-pro" placeholder="••••••••" />
                        </div>
                    </div>
                    <div className="flex gap-3 pt-1">
                        <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium" style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>Annuler</button>
                        <button type="submit" disabled={submitting} className="flex-1 btn-primary">{submitting ? 'Ajout…' : 'Ajouter le membre'}</button>
                    </div>
                </form>
            </div>
        </div>
    );
}

export default function StaffPage() {
    const { id: restaurantId } = useParams<{ id: string }>();
    const [staff, setStaff] = useState<StaffMember[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [showModal, setShowModal] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [editRole, setEditRole] = useState<StaffRole>('waiter');
    const [search, setSearch] = useState('');
    const [viewMode, setViewMode] = useState<'table' | 'cards'>('cards');
    const [confirmModal, setConfirmModal] = useState<{ member: StaffMember } | null>(null);
    const [editModal, setEditModal] = useState<{ member: StaffMember } | null>(null);

    const load = useCallback(async () => {
        if (!restaurantId) return;
        setLoading(true);
        try { const res = await staffApi.getAll(Number(restaurantId)); setStaff(res.data.data); }
        catch { setError('Impossible de charger le personnel'); }
        finally { setLoading(false); }
    }, [restaurantId]);

    useEffect(() => { load(); }, [load]);

    const handleUpdateRole = async (member: StaffMember) => {
        if (!restaurantId) return;
        try { await staffApi.update(Number(restaurantId), member.id, { role: editRole }); setEditingId(null); load(); }
        catch { alert('Erreur lors de la mise à jour du rôle'); }
    };

    const handleToggleActive = async (member: StaffMember) => {
        if (!restaurantId) return;
        try { await staffApi.update(Number(restaurantId), member.id, { is_active: !member.is_active }); load(); }
        catch { alert('Erreur lors de la mise à jour'); }
    };

    const handleRemove = (member: StaffMember) => { setConfirmModal({ member }); };
    const executeRemove = async (member: StaffMember) => {
        if (!restaurantId) return;
        try { await staffApi.remove(Number(restaurantId), member.id); load(); }
        catch (err: unknown) {
            const e = err as { response?: { data?: { message?: string } } };
            alert(e.response?.data?.message ?? 'Erreur lors de la suppression');
        }
        setConfirmModal(null);
    };

    if (loading) return (
        <div className="flex items-center justify-center h-48">
            <div className="w-10 h-10 rounded-xl flex items-center justify-center animate-pulse" style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                <Users className="h-5 w-5 text-white" />
            </div>
        </div>
    );

    if (error) return (
        <div className="p-8 text-center rounded-2xl" style={{ background: '#fef2f2', border: '1px solid #fecaca' }}>
            <p className="text-sm font-medium" style={{ color: '#dc2626' }}>{error}</p>
            <button onClick={load} className="mt-3 text-sm font-medium" style={{ color: '#f97316' }}>Réessayer</button>
        </div>
    );

    const activeCount = staff.filter(s => s.is_active).length;
    const inactiveCount = staff.length - activeCount;
    const filtered = search.trim()
        ? staff.filter(s => s.name.toLowerCase().includes(search.toLowerCase()) || s.email.toLowerCase().includes(search.toLowerCase()) || s.role_label.toLowerCase().includes(search.toLowerCase()))
        : staff;

    return (
        <div className="space-y-5 animate-fadeIn">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: '#0f172a' }}>Personnel</h1>
                    <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>{staff.length} membre{staff.length !== 1 ? 's' : ''} · {activeCount} actif{activeCount !== 1 ? 's' : ''}</p>
                </div>
                <div className="flex items-center gap-2 flex-wrap">
                    <div className="flex rounded-xl overflow-hidden" style={{ border: '1px solid #e2e8f0' }}>
                        <button onClick={() => setViewMode('cards')} className="flex items-center gap-1.5 px-3 py-2 text-sm font-medium transition-colors"
                            style={{ background: viewMode === 'cards' ? '#0f172a' : 'white', color: viewMode === 'cards' ? 'white' : '#64748b' }}>
                            <LayoutGrid className="h-4 w-4" /> Cartes
                        </button>
                        <button onClick={() => setViewMode('table')} className="flex items-center gap-1.5 px-3 py-2 text-sm font-medium transition-colors"
                            style={{ background: viewMode === 'table' ? '#0f172a' : 'white', color: viewMode === 'table' ? 'white' : '#64748b' }}>
                            <List className="h-4 w-4" /> Tableau
                        </button>
                    </div>
                    <button onClick={() => setShowModal(true)} className="btn-primary text-sm"><Plus size={16} /> Ajouter un membre</button>
                </div>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {([
                    { label: 'Total', value: staff.length, icon: <Users size={18} />, grad: 'linear-gradient(135deg,#f97316,#ea580c)', shadow: 'rgba(249,115,22,0.2)' },
                    { label: 'Actifs', value: activeCount, icon: <UserCheck size={18} />, grad: 'linear-gradient(135deg,#22c55e,#15803d)', shadow: 'rgba(34,197,94,0.2)' },
                    { label: 'Inactifs', value: inactiveCount, icon: <UserX size={18} />, grad: 'linear-gradient(135deg,#94a3b8,#64748b)', shadow: 'rgba(100,116,139,0.2)' },
                    { label: 'Gérants', value: staff.filter(s => s.role === 'manager').length, icon: <ChefHat size={18} />, grad: 'linear-gradient(135deg,#3b82f6,#1d4ed8)', shadow: 'rgba(59,130,246,0.2)' },
                ] as const).map(c => (
                    <div key={c.label} className="rounded-2xl p-4" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                        <div className="flex items-center justify-between mb-3">
                            <span className="text-xs font-semibold" style={{ color: '#64748b' }}>{c.label}</span>
                            <div className="w-8 h-8 rounded-lg flex items-center justify-center text-white" style={{ background: c.grad, boxShadow: `0 3px 8px ${c.shadow}` }}>{c.icon}</div>
                        </div>
                        <p className="text-2xl font-bold" style={{ color: '#0f172a' }}>{c.value}</p>
                    </div>
                ))}
            </div>

            <div className="flex flex-wrap gap-2">
                {(Object.entries(STAFF_ROLE_LABELS) as [StaffRole, string][]).filter(([r]) => r !== 'owner').map(([role, label]) => {
                    const st = ROLE_STYLE[role] ?? ROLE_STYLE.waiter;
                    const count = staff.filter(s => s.role === role).length;
                    return (
                        <span key={role} className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold" style={{ background: st.bg, color: st.color, border: `1px solid ${st.border}` }}>
                            {ROLE_ICONS[role]} {label} ({count})
                        </span>
                    );
                })}
            </div>

            {staff.length > 5 && (
                <div className="relative">
                    <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: '#94a3b8' }} />
                    <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Rechercher un membre…" className="input-pro pl-10" style={{ width: '100%', maxWidth: 380 }} />
                </div>
            )}

            {filtered.length === 0 ? (
                <div className="text-center py-20 rounded-2xl" style={{ background: 'white', border: '1px solid #f1f5f9' }}>
                    <div className="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-4" style={{ background: '#f8fafc' }}><Users className="h-8 w-8" style={{ color: '#cbd5e1' }} /></div>
                    <p className="font-semibold" style={{ color: '#374151' }}>{search ? 'Aucun résultat' : 'Aucun membre'}</p>
                    <p className="text-sm mt-1" style={{ color: '#94a3b8' }}>{search ? 'Essayez un autre terme' : 'Ajoutez gérants, caissiers ou serveurs'}</p>
                </div>
            ) : viewMode === 'cards' ? (
                <StaffCardGrid staff={filtered} onToggleActive={handleToggleActive} onEdit={(m) => setEditModal({ member: m })} onRemove={handleRemove} />
            ) : (
                <div className="rounded-2xl overflow-hidden" style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                    <table className="w-full text-sm">
                        <thead>
                            <tr style={{ borderBottom: '1px solid #f1f5f9', background: '#f8fafc' }}>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Membre</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Rôle</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold hidden md:table-cell" style={{ color: '#64748b' }}>Permissions</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Statut</th>
                                <th className="text-right px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filtered.map((member, idx) => {
                                const st = ROLE_STYLE[member.role] ?? ROLE_STYLE.waiter;
                                return (
                                    <tr key={member.id} className="table-row-hover" style={{ borderBottom: idx < filtered.length - 1 ? '1px solid #f8fafc' : 'none', opacity: member.is_active ? 1 : 0.55 }}>
                                        <td className="px-5 py-4">
                                            <div className="flex items-center gap-3">
                                                <StaffAvatar member={member} size={40} />
                                                <div className="min-w-0">
                                                    <p className="font-semibold truncate" style={{ color: '#0f172a' }}>{member.name}</p>
                                                    <p className="text-xs truncate" style={{ color: '#94a3b8' }}>{member.email}</p>
                                                    {member.phone && <p className="text-xs" style={{ color: '#94a3b8' }}>{member.phone}</p>}
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-5 py-4">
                                            {editingId === member.id ? (
                                                <div className="flex items-center gap-2">
                                                    <select value={editRole} onChange={e => setEditRole(e.target.value as StaffRole)} className="text-xs px-2 py-1.5 rounded-lg border" style={{ borderColor: '#e2e8f0' }}>
                                                        <option value="manager">Gérant</option>
                                                        <option value="cashier">Caissier</option>
                                                        <option value="waiter">Serveur</option>
                                                    </select>
                                                    <button onClick={() => handleUpdateRole(member)} className="p-1 rounded-lg" style={{ background: '#f0fdf4', color: '#16a34a' }}><Check size={14} /></button>
                                                    <button onClick={() => setEditingId(null)} className="p-1 rounded-lg" style={{ background: '#f8fafc', color: '#64748b' }}><X size={14} /></button>
                                                </div>
                                            ) : (
                                                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold" style={{ background: st.bg, color: st.color, border: `1px solid ${st.border}` }}>
                                                    {ROLE_ICONS[member.role]} {member.role_label}
                                                </span>
                                            )}
                                        </td>
                                        <td className="px-5 py-4 hidden md:table-cell">
                                            <div className="flex flex-wrap gap-1">
                                                {member.permissions.map(p => (
                                                    <span key={p} className="text-[10px] px-1.5 py-0.5 rounded font-medium" style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>
                                                        {ROLE_PERMISSIONS_FR[p] ?? p}
                                                    </span>
                                                ))}
                                            </div>
                                        </td>
                                        <td className="px-5 py-4">
                                            <button onClick={() => handleToggleActive(member)} className="text-xs px-2.5 py-1 rounded-lg font-semibold transition-colors"
                                                style={member.is_active ? { background: '#f0fdf4', color: '#16a34a', border: '1px solid #bbf7d0' } : { background: '#f8fafc', color: '#94a3b8', border: '1px solid #e2e8f0' }}>
                                                {member.is_active ? '✓ Actif' : 'Inactif'}
                                            </button>
                                        </td>
                                        <td className="px-5 py-4 text-right">
                                            <div className="flex items-center justify-end gap-1.5">
                                                {member.role !== 'owner' && editingId !== member.id && (
                                                    <button onClick={() => { setEditingId(member.id); setEditRole(member.role); }} className="p-1.5 rounded-lg transition-colors" style={{ color: '#94a3b8' }}
                                                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#eff6ff'; (e.currentTarget as HTMLButtonElement).style.color = '#2563eb'; }}
                                                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                                                        <Edit2 size={14} />
                                                    </button>
                                                )}
                                                {member.role !== 'owner' && (
                                                    <button onClick={() => handleRemove(member)} className="p-1.5 rounded-lg transition-colors" style={{ color: '#94a3b8' }}
                                                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fef2f2'; (e.currentTarget as HTMLButtonElement).style.color = '#dc2626'; }}
                                                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                                                        <Trash2 size={14} />
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

            {showModal && restaurantId && (
                <AddMemberModal restaurantId={restaurantId} onClose={() => setShowModal(false)} onSaved={load} />
            )}
            {confirmModal && (
                <ConfirmModal
                    message={`Retirer ${confirmModal.member.name} de l'équipe ? Cette action est irréversible.`}
                    onConfirm={() => executeRemove(confirmModal.member)}
                    onCancel={() => setConfirmModal(null)}
                />
            )}
            {editModal && restaurantId && (
                <EditRoleModal
                    member={editModal.member}
                    restaurantId={restaurantId}
                    onClose={() => setEditModal(null)}
                    onSaved={() => { load(); setEditModal(null); }}
                />
            )}
        </div>
    );
}
