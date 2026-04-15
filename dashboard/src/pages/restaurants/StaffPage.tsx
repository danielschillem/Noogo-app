import { useState, useEffect, useCallback } from 'react';
import { useParams } from 'react-router-dom';
import {
    Users, Plus, Trash2, Edit2, Check, X, ShieldCheck, ChefHat, CreditCard, UtensilsCrossed,
} from 'lucide-react';
import { staffApi } from '../../services/api';
import type { StaffMember, StaffRole } from '../../types';
import { STAFF_ROLE_LABELS, STAFF_ROLE_COLORS } from '../../types';
import { useAuth } from '../../context/AuthContext';

const ROLE_ICONS: Record<StaffRole, React.ReactNode> = {
    owner: <ShieldCheck size={14} />,
    manager: <ChefHat size={14} />,
    cashier: <CreditCard size={14} />,
    waiter: <UtensilsCrossed size={14} />,
};

const ROLE_PERMISSIONS_FR: Record<string, string> = {
    manage_staff: 'GÃ©rer le personnel',
    edit_restaurant: 'Modifier le restaurant',
    manage_menu: 'GÃ©rer le menu',
    manage_orders: 'GÃ©rer les commandes',
    view_stats: 'Voir les statistiques',
};

interface StaffForm {
    name: string;
    email: string;
    phone: string;
    role: StaffRole;
    password: string;
}

const EMPTY_FORM: StaffForm = { name: '', email: '', phone: '', role: 'waiter', password: '' };

export default function StaffPage() {
    const { id: restaurantId } = useParams<{ id: string }>();
    const { user } = useAuth();
    const [staff, setStaff] = useState<StaffMember[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [showForm, setShowForm] = useState(false);
    const [form, setForm] = useState<StaffForm>(EMPTY_FORM);
    const [submitting, setSubmitting] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [editRole, setEditRole] = useState<StaffRole>('waiter');
    const [formError, setFormError] = useState<string | null>(null);

    const load = useCallback(async () => {
        if (!restaurantId) return;
        setLoading(true);
        try {
            const res = await staffApi.getAll(Number(restaurantId));
            setStaff(res.data.data);
        } catch {
            setError('Impossible de charger le personnel');
        } finally {
            setLoading(false);
        }
    }, [restaurantId]);

    useEffect(() => { load(); }, [load]);

    const handleCreate = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!restaurantId) return;
        setSubmitting(true);
        setFormError(null);
        try {
            const payload = {
                name: form.name,
                email: form.email,
                phone: form.phone || undefined,
                role: form.role,
                password: form.password || undefined,
            };
            await staffApi.create(Number(restaurantId), payload);
            setShowForm(false);
            setForm(EMPTY_FORM);
            load();
        } catch (err: unknown) {
            const e = err as { response?: { data?: { message?: string; errors?: Record<string, string[]> } } };
            const msg = e.response?.data?.message ?? 'Erreur lors de l\'ajout';
            const fieldErrors = e.response?.data?.errors;
            const detail = fieldErrors ? Object.values(fieldErrors).flat().join(' Â· ') : '';
            setFormError(detail || msg);
        } finally {
            setSubmitting(false);
        }
    };

    const handleUpdateRole = async (member: StaffMember) => {
        if (!restaurantId) return;
        try {
            await staffApi.update(Number(restaurantId), member.id, { role: editRole });
            setEditingId(null);
            load();
        } catch {
            alert('Erreur lors de la mise Ã  jour du rÃ´le');
        }
    };

    const handleToggleActive = async (member: StaffMember) => {
        if (!restaurantId) return;
        try {
            await staffApi.update(Number(restaurantId), member.id, { is_active: !member.is_active });
            load();
        } catch {
            alert('Erreur lors de la mise Ã  jour');
        }
    };

    const handleRemove = async (member: StaffMember) => {
        if (!restaurantId) return;
        if (!confirm(`Retirer ${member.name} de l'Ã©quipe ?`)) return;
        try {
            await staffApi.remove(Number(restaurantId), member.id);
            load();
        } catch (err: unknown) {
            const e = err as { response?: { data?: { message?: string } } };
            alert(e.response?.data?.message ?? 'Erreur lors de la suppression');
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-48">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center animate-pulse"
                    style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                    <Users className="h-5 w-5 text-white" />
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="p-8 text-center rounded-2xl" style={{ background: '#fef2f2', border: '1px solid #fecaca' }}>
                <p className="text-sm font-medium" style={{ color: '#dc2626' }}>{error}</p>
                <button onClick={load} className="mt-3 text-sm font-medium" style={{ color: '#f97316' }}>RÃ©essayer</button>
            </div>
        );
    }

    const ROLE_STYLE: Record<string, { bg: string; color: string; border: string }> = {
        owner: { bg: '#fff7ed', color: '#c2410c', border: '#fed7aa' },
        manager: { bg: '#eff6ff', color: '#1d4ed8', border: '#bfdbfe' },
        cashier: { bg: '#f0fdf4', color: '#15803d', border: '#bbf7d0' },
        waiter: { bg: '#faf5ff', color: '#6d28d9', border: '#ddd6fe' },
    };

    return (
        <div className="space-y-5 animate-fadeIn">

            {/* â”€â”€ Header â”€â”€ */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: '#0f172a' }}>Personnel</h1>
                    <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>
                        {staff.length} membre{staff.length !== 1 ? 's' : ''} dans l'Ã©quipe
                    </p>
                </div>
                <button onClick={() => { setShowForm(true); setFormError(null); setForm(EMPTY_FORM); }}
                    className="btn-primary text-sm">
                    <Plus size={16} /> Ajouter
                </button>
            </div>

            {/* â”€â”€ Role summary cards â”€â”€ */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                {(Object.entries(STAFF_ROLE_LABELS) as [StaffRole, string][]).filter(([r]) => r !== 'owner').map(([role, label]) => {
                    const count = staff.filter(s => s.role === role && s.is_active).length;
                    const st = ROLE_STYLE[role] ?? ROLE_STYLE.waiter;
                    return (
                        <div key={role} className="p-4 rounded-2xl"
                            style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                            <div className="flex items-center gap-2 mb-3">
                                <div className="w-8 h-8 rounded-lg flex items-center justify-center"
                                    style={{ background: st.bg, border: `1px solid ${st.border}`, color: st.color }}>
                                    {ROLE_ICONS[role]}
                                </div>
                                <span className="text-xs font-semibold" style={{ color: st.color }}>{label}</span>
                            </div>
                            <p className="text-2xl font-bold" style={{ color: '#0f172a' }}>{count}</p>
                            <p className="text-xs" style={{ color: '#94a3b8' }}>actif{count !== 1 ? 's' : ''}</p>
                        </div>
                    );
                })}
            </div>

            {/* â”€â”€ Add form â”€â”€ */}
            {showForm && (
                <form onSubmit={handleCreate} className="rounded-2xl p-6"
                    style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
                    <h2 className="text-base font-bold mb-4" style={{ color: '#0f172a' }}>Nouveau membre</h2>
                    {formError && (
                        <div className="mb-4 px-4 py-3 rounded-xl text-sm"
                            style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                            {formError}
                        </div>
                    )}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Nom complet *</label>
                            <input required value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                                className="input-pro" placeholder="Jean Dupont" />
                        </div>
                        <div>
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Email *</label>
                            <input required type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                                className="input-pro" placeholder="jean@example.com" />
                        </div>
                        <div>
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>TÃ©lÃ©phone</label>
                            <input value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                                className="input-pro" placeholder="+226 70000000" />
                        </div>
                        <div>
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>RÃ´le *</label>
                            <select value={form.role} onChange={e => setForm(f => ({ ...f, role: e.target.value as StaffRole }))}
                                className="input-pro">
                                <option value="manager">GÃ©rant</option>
                                <option value="cashier">Caissier</option>
                                <option value="waiter">Serveur</option>
                            </select>
                        </div>
                        <div className="sm:col-span-2">
                            <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>
                                Mot de passe <span style={{ color: '#94a3b8', fontWeight: 400 }}>(optionnel)</span>
                            </label>
                            <input type="password" value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                                className="input-pro" placeholder="â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢" />
                        </div>
                    </div>
                    <div className="flex justify-end gap-3 mt-5">
                        <button type="button" onClick={() => setShowForm(false)}
                            className="px-4 py-2 rounded-xl text-sm font-medium transition-colors"
                            style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>
                            Annuler
                        </button>
                        <button type="submit" disabled={submitting} className="btn-primary">
                            {submitting ? 'Ajoutâ€¦' : 'Ajouter le membre'}
                        </button>
                    </div>
                </form>
            )}

            {/* â”€â”€ Staff list â”€â”€ */}
            {staff.length === 0 ? (
                <div className="text-center py-20 rounded-2xl"
                    style={{ background: 'white', border: '1px solid #f1f5f9' }}>
                    <div className="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-4"
                        style={{ background: '#f8fafc' }}>
                        <Users className="h-8 w-8" style={{ color: '#cbd5e1' }} />
                    </div>
                    <p className="font-semibold" style={{ color: '#374151' }}>Aucun membre</p>
                    <p className="text-sm mt-1" style={{ color: '#94a3b8' }}>Ajoutez gÃ©rants, caissiers ou serveurs</p>
                </div>
            ) : (
                <div className="rounded-2xl overflow-hidden"
                    style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                    <table className="w-full text-sm">
                        <thead>
                            <tr style={{ borderBottom: '1px solid #f1f5f9', background: '#f8fafc' }}>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Membre</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>RÃ´le</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold hidden md:table-cell" style={{ color: '#64748b' }}>Permissions</th>
                                <th className="text-left px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Statut</th>
                                <th className="text-right px-5 py-3.5 text-xs font-semibold" style={{ color: '#64748b' }}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {staff.map((member, idx) => {
                                const st = ROLE_STYLE[member.role] ?? ROLE_STYLE.waiter;
                                return (
                                    <tr key={member.id} className="table-row-hover"
                                        style={{
                                            borderBottom: idx < staff.length - 1 ? '1px solid #f8fafc' : 'none',
                                            opacity: member.is_active ? 1 : 0.55
                                        }}>
                                        <td className="px-5 py-4">
                                            <div className="flex items-center gap-3">
                                                <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0 font-bold text-sm"
                                                    style={{ background: st.bg, color: st.color, border: `1px solid ${st.border}` }}>
                                                    {member.name.charAt(0).toUpperCase()}
                                                </div>
                                                <div className="min-w-0">
                                                    <p className="font-semibold truncate" style={{ color: '#0f172a' }}>{member.name}</p>
                                                    <p className="text-xs truncate" style={{ color: '#94a3b8' }}>{member.email}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-5 py-4">
                                            {editingId === member.id ? (
                                                <div className="flex items-center gap-2">
                                                    <select value={editRole} onChange={e => setEditRole(e.target.value as StaffRole)}
                                                        className="text-xs px-2 py-1.5 rounded-lg border" style={{ borderColor: '#e2e8f0' }}>
                                                        <option value="manager">GÃ©rant</option>
                                                        <option value="cashier">Caissier</option>
                                                        <option value="waiter">Serveur</option>
                                                    </select>
                                                    <button onClick={() => handleUpdateRole(member)}
                                                        className="p-1 rounded-lg" style={{ background: '#f0fdf4', color: '#16a34a' }}>
                                                        <Check size={14} />
                                                    </button>
                                                    <button onClick={() => setEditingId(null)}
                                                        className="p-1 rounded-lg" style={{ background: '#f8fafc', color: '#64748b' }}>
                                                        <X size={14} />
                                                    </button>
                                                </div>
                                            ) : (
                                                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold"
                                                    style={{ background: st.bg, color: st.color, border: `1px solid ${st.border}` }}>
                                                    {ROLE_ICONS[member.role]} {member.role_label}
                                                </span>
                                            )}
                                        </td>
                                        <td className="px-5 py-4 hidden md:table-cell">
                                            <div className="flex flex-wrap gap-1">
                                                {member.permissions.map(p => (
                                                    <span key={p} className="text-[10px] px-1.5 py-0.5 rounded font-medium"
                                                        style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>
                                                        {ROLE_PERMISSIONS_FR[p] ?? p}
                                                    </span>
                                                ))}
                                            </div>
                                        </td>
                                        <td className="px-5 py-4">
                                            <button onClick={() => handleToggleActive(member)}
                                                className="text-xs px-2.5 py-1 rounded-lg font-semibold transition-colors"
                                                style={member.is_active
                                                    ? { background: '#f0fdf4', color: '#16a34a', border: '1px solid #bbf7d0' }
                                                    : { background: '#f8fafc', color: '#94a3b8', border: '1px solid #e2e8f0' }}>
                                                {member.is_active ? 'Actif' : 'Inactif'}
                                            </button>
                                        </td>
                                        <td className="px-5 py-4 text-right">
                                            <div className="flex items-center justify-end gap-1.5">
                                                {member.role !== 'owner' && editingId !== member.id && (
                                                    <button onClick={() => { setEditingId(member.id); setEditRole(member.role); }}
                                                        className="p-1.5 rounded-lg transition-colors"
                                                        style={{ color: '#94a3b8' }}
                                                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#eff6ff'; (e.currentTarget as HTMLButtonElement).style.color = '#2563eb'; }}
                                                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                                                        <Edit2 size={14} />
                                                    </button>
                                                )}
                                                {member.role !== 'owner' && (
                                                    <button onClick={() => handleRemove(member)}
                                                        className="p-1.5 rounded-lg transition-colors"
                                                        style={{ color: '#94a3b8' }}
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
        </div>
    );
}
                                                        className="p-1.5 rounded-lg transition-colors"
                                                        style={{ color: '#94a3b8' }}
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
        </div>
    );
}
