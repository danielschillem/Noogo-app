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
    manage_staff: 'Gérer le personnel',
    edit_restaurant: 'Modifier le restaurant',
    manage_menu: 'Gérer le menu',
    manage_orders: 'Gérer les commandes',
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
            const detail = fieldErrors ? Object.values(fieldErrors).flat().join(' · ') : '';
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
            alert('Erreur lors de la mise à jour du rôle');
        }
    };

    const handleToggleActive = async (member: StaffMember) => {
        if (!restaurantId) return;
        try {
            await staffApi.update(Number(restaurantId), member.id, { is_active: !member.is_active });
            load();
        } catch {
            alert('Erreur lors de la mise à jour');
        }
    };

    const handleRemove = async (member: StaffMember) => {
        if (!restaurantId) return;
        if (!confirm(`Retirer ${member.name} de l'équipe ?`)) return;
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
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500" />
            </div>
        );
    }

    if (error) {
        return (
            <div className="p-6 text-center text-red-600">
                <p>{error}</p>
                <button onClick={load} className="mt-3 text-sm text-orange-500 hover:underline">Réessayer</button>
            </div>
        );
    }

    return (
        <div className="p-6 max-w-4xl mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                    <Users className="text-orange-500" size={24} />
                    <div>
                        <h1 className="text-xl font-bold text-gray-900">Personnel</h1>
                        <p className="text-sm text-gray-500">{staff.length} membre{staff.length > 1 ? 's' : ''}</p>
                    </div>
                </div>
                {(user?.is_admin || true) && (
                    <button
                        onClick={() => { setShowForm(true); setFormError(null); setForm(EMPTY_FORM); }}
                        className="flex items-center gap-2 px-4 py-2 bg-orange-500 hover:bg-orange-600 text-white rounded-lg text-sm font-medium transition-colors"
                    >
                        <Plus size={16} /> Ajouter un membre
                    </button>
                )}
            </div>

            {/* Formulaire d'ajout */}
            {showForm && (
                <form onSubmit={handleCreate} className="bg-white border border-gray-200 rounded-xl p-5 mb-6 shadow-sm">
                    <h2 className="text-base font-semibold text-gray-800 mb-4">Nouveau membre</h2>
                    {formError && (
                        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">{formError}</div>
                    )}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Nom complet *</label>
                            <input
                                required value={form.name}
                                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400"
                                placeholder="Jean Dupont"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Email *</label>
                            <input
                                required type="email" value={form.email}
                                onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400"
                                placeholder="jean@example.com"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Téléphone</label>
                            <input
                                value={form.phone}
                                onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400"
                                placeholder="+226 70000000"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Rôle *</label>
                            <select
                                value={form.role}
                                onChange={e => setForm(f => ({ ...f, role: e.target.value as StaffRole }))}
                                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400"
                            >
                                <option value="manager">Gérant</option>
                                <option value="cashier">Caissier</option>
                                <option value="waiter">Serveur</option>
                            </select>
                        </div>
                        <div className="sm:col-span-2">
                            <label className="block text-sm font-medium text-gray-700 mb-1">
                                Mot de passe <span className="text-gray-400 font-normal">(optionnel — généré automatiquement si vide)</span>
                            </label>
                            <input
                                type="password" value={form.password}
                                onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange-400"
                                placeholder="••••••••"
                            />
                        </div>
                    </div>
                    <div className="flex justify-end gap-3 mt-4">
                        <button
                            type="button" onClick={() => setShowForm(false)}
                            className="px-4 py-2 text-sm text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50"
                        >
                            Annuler
                        </button>
                        <button
                            type="submit" disabled={submitting}
                            className="px-4 py-2 text-sm font-medium text-white bg-orange-500 hover:bg-orange-600 rounded-lg disabled:opacity-50"
                        >
                            {submitting ? 'Ajout…' : 'Ajouter'}
                        </button>
                    </div>
                </form>
            )}

            {/* Rôles explication */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-6">
                {(Object.entries(STAFF_ROLE_LABELS) as [StaffRole, string][])
                    .filter(([r]) => r !== 'owner')
                    .map(([role, label]) => {
                        const roleStaff = staff.filter(s => s.role === role && s.is_active);
                        return (
                            <div key={role} className="bg-white border border-gray-200 rounded-xl p-3">
                                <div className={`inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium mb-2 ${STAFF_ROLE_COLORS[role]}`}>
                                    {ROLE_ICONS[role]} {label}
                                </div>
                                <p className="text-2xl font-bold text-gray-900">{roleStaff.length}</p>
                                <p className="text-xs text-gray-500 mt-0.5">actif{roleStaff.length > 1 ? 's' : ''}</p>
                            </div>
                        );
                    })}
            </div>

            {/* Liste du personnel */}
            {staff.length === 0 ? (
                <div className="text-center py-16 text-gray-400">
                    <Users size={48} className="mx-auto mb-3 opacity-30" />
                    <p className="font-medium">Aucun membre du personnel</p>
                    <p className="text-sm mt-1">Ajoutez un gérant, caissier ou serveur</p>
                </div>
            ) : (
                <div className="bg-white border border-gray-200 rounded-xl overflow-hidden">
                    <table className="w-full text-sm">
                        <thead className="bg-gray-50 border-b border-gray-200">
                            <tr>
                                <th className="text-left px-4 py-3 font-semibold text-gray-600">Membre</th>
                                <th className="text-left px-4 py-3 font-semibold text-gray-600">Rôle</th>
                                <th className="text-left px-4 py-3 font-semibold text-gray-600 hidden md:table-cell">Permissions</th>
                                <th className="text-left px-4 py-3 font-semibold text-gray-600">Statut</th>
                                <th className="text-right px-4 py-3 font-semibold text-gray-600">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {staff.map(member => (
                                <tr key={member.id} className={`hover:bg-gray-50 transition-colors ${!member.is_active ? 'opacity-50' : ''}`}>
                                    <td className="px-4 py-3">
                                        <div className="font-medium text-gray-900">{member.name}</div>
                                        <div className="text-xs text-gray-500">{member.email}</div>
                                        {member.phone && <div className="text-xs text-gray-400">{member.phone}</div>}
                                    </td>
                                    <td className="px-4 py-3">
                                        {editingId === member.id ? (
                                            <div className="flex items-center gap-2">
                                                <select
                                                    value={editRole}
                                                    onChange={e => setEditRole(e.target.value as StaffRole)}
                                                    className="border border-gray-300 rounded px-2 py-1 text-xs"
                                                >
                                                    <option value="manager">Gérant</option>
                                                    <option value="cashier">Caissier</option>
                                                    <option value="waiter">Serveur</option>
                                                </select>
                                                <button onClick={() => handleUpdateRole(member)} className="text-green-600 hover:text-green-700">
                                                    <Check size={14} />
                                                </button>
                                                <button onClick={() => setEditingId(null)} className="text-gray-400 hover:text-gray-600">
                                                    <X size={14} />
                                                </button>
                                            </div>
                                        ) : (
                                            <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${STAFF_ROLE_COLORS[member.role]}`}>
                                                {ROLE_ICONS[member.role]} {member.role_label}
                                            </span>
                                        )}
                                    </td>
                                    <td className="px-4 py-3 hidden md:table-cell">
                                        <div className="flex flex-wrap gap-1">
                                            {member.permissions.map(p => (
                                                <span key={p} className="text-xs bg-gray-100 text-gray-600 px-1.5 py-0.5 rounded">
                                                    {ROLE_PERMISSIONS_FR[p] ?? p}
                                                </span>
                                            ))}
                                        </div>
                                    </td>
                                    <td className="px-4 py-3">
                                        <button
                                            onClick={() => handleToggleActive(member)}
                                            className={`text-xs px-2 py-1 rounded-full font-medium ${member.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}
                                        >
                                            {member.is_active ? 'Actif' : 'Inactif'}
                                        </button>
                                    </td>
                                    <td className="px-4 py-3 text-right">
                                        <div className="flex items-center justify-end gap-2">
                                            {member.role !== 'owner' && editingId !== member.id && (
                                                <button
                                                    onClick={() => { setEditingId(member.id); setEditRole(member.role); }}
                                                    className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                                    title="Modifier le rôle"
                                                >
                                                    <Edit2 size={14} />
                                                </button>
                                            )}
                                            {member.role !== 'owner' && (
                                                <button
                                                    onClick={() => handleRemove(member)}
                                                    className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                                    title="Retirer de l'équipe"
                                                >
                                                    <Trash2 size={14} />
                                                </button>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
}
