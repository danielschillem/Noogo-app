import { useEffect, useState, useCallback } from 'react';
import { Plus, Pencil, Trash2, Tag, X, ToggleLeft, ToggleRight, Ticket } from 'lucide-react';
import { flashInfosApi, restaurantsApi, couponsApi } from '../../services/api';
import type { FlashInfo, Restaurant, Coupon } from '../../types';

const TYPE_LABELS: Record<string, string> = {
    promotion: 'Promotion',
    info: 'Information',
    event: 'Événement',
    offre: 'Offre spéciale',
};

const TYPE_COLORS: Record<string, string> = {
    promotion: 'bg-orange-100 text-orange-700',
    info: 'bg-blue-100 text-blue-700',
    event: 'bg-purple-100 text-purple-700',
    offre: 'bg-green-100 text-green-700',
};

// ─── Flash Info Modal ────────────────────────────────────────────────────────

function FlashInfoModal({
    restaurantId,
    flashInfo,
    onClose,
    onSaved,
}: {
    restaurantId: number;
    flashInfo: FlashInfo | null;
    onClose: () => void;
    onSaved: () => void;
}) {
    const [titre, setTitre] = useState(flashInfo?.titre ?? '');
    const [description, setDescription] = useState(flashInfo?.description ?? '');
    const [type, setType] = useState<string>(flashInfo?.type ?? 'promotion');
    const [reduction, setReduction] = useState(flashInfo?.reduction_percentage?.toString() ?? '');
    const [prixSpecial, setPrixSpecial] = useState(flashInfo?.prix_special?.toString() ?? '');
    const [dateDebut, setDateDebut] = useState(flashInfo?.date_debut ?? '');
    const [dateFin, setDateFin] = useState(flashInfo?.date_fin ?? '');
    const [image, setImage] = useState<File | null>(null);
    const [isSaving, setIsSaving] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!titre.trim()) { setError('Le titre est requis'); return; }
        setIsSaving(true);
        setError('');
        try {
            const fd = new FormData();
            fd.append('titre', titre.trim());
            fd.append('type', type);
            if (description) fd.append('description', description);
            if (reduction) fd.append('reduction_percentage', reduction);
            if (prixSpecial) fd.append('prix_special', prixSpecial);
            if (dateDebut) fd.append('date_debut', dateDebut);
            if (dateFin) fd.append('date_fin', dateFin);
            if (image) fd.append('image', image);
            if (flashInfo) {
                await flashInfosApi.update(restaurantId, flashInfo.id, fd);
            } else {
                await flashInfosApi.create(restaurantId, fd);
            }
            onSaved();
            onClose();
        } catch {
            setError('Erreur lors de la sauvegarde');
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-xl w-full max-w-lg shadow-xl max-h-[90vh] overflow-y-auto">
                <div className="flex items-center justify-between p-6 border-b sticky top-0 bg-white">
                    <h2 className="text-lg font-semibold">{flashInfo ? 'Modifier la promotion' : 'Nouvelle promotion'}</h2>
                    <button onClick={onClose}><X className="h-5 w-5 text-gray-400" /></button>
                </div>
                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {error && <p className="text-sm text-red-600 bg-red-50 px-3 py-2 rounded-lg">{error}</p>}

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Titre *</label>
                        <input value={titre} onChange={e => setTitre(e.target.value)}
                            className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500"
                            placeholder="Ex: -20% sur les boissons" />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                        <select value={type} onChange={e => setType(e.target.value)}
                            className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500">
                            {Object.entries(TYPE_LABELS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
                        </select>
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                        <textarea value={description} onChange={e => setDescription(e.target.value)}
                            rows={3} className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 resize-none" />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Réduction (%)</label>
                            <input type="number" value={reduction} onChange={e => setReduction(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500"
                                placeholder="20" min="0" max="100" />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Prix spécial (FCFA)</label>
                            <input type="number" value={prixSpecial} onChange={e => setPrixSpecial(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500"
                                placeholder="1000" min="0" />
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Début</label>
                            <input type="date" value={dateDebut} onChange={e => setDateDebut(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500" />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Fin</label>
                            <input type="date" value={dateFin} onChange={e => setDateFin(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500" />
                        </div>
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Image</label>
                        <input type="file" accept="image/*" onChange={e => setImage(e.target.files?.[0] ?? null)}
                            className="w-full text-sm text-gray-600" />
                    </div>

                    <div className="flex gap-3 pt-2">
                        <button type="button" onClick={onClose} className="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-gray-600 hover:bg-gray-50">Annuler</button>
                        <button type="submit" disabled={isSaving}
                            className="flex-1 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 disabled:opacity-50">
                            {isSaving ? 'Sauvegarde...' : 'Sauvegarder'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}

// ─── Coupon Modal ─────────────────────────────────────────────────────────────

function CouponModal({
    restaurantId,
    coupon,
    onClose,
    onSaved,
}: {
    restaurantId: number;
    coupon: Coupon | null;
    onClose: () => void;
    onSaved: () => void;
}) {
    const [code, setCode] = useState(coupon?.code ?? '');
    const [type, setType] = useState<'percentage' | 'fixed'>(coupon?.type ?? 'percentage');
    const [value, setValue] = useState(coupon?.value?.toString() ?? '');
    const [minOrder, setMinOrder] = useState(coupon?.min_order?.toString() ?? '');
    const [maxDiscount, setMaxDiscount] = useState(coupon?.max_discount?.toString() ?? '');
    const [maxUses, setMaxUses] = useState(coupon?.max_uses?.toString() ?? '');
    const [startsAt, setStartsAt] = useState(coupon?.starts_at?.substring(0, 10) ?? '');
    const [expiresAt, setExpiresAt] = useState(coupon?.expires_at?.substring(0, 10) ?? '');
    const [isActive, setIsActive] = useState(coupon?.is_active ?? true);
    const [isSaving, setIsSaving] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!code.trim()) { setError('Le code est requis'); return; }
        if (!value || Number(value) <= 0) { setError('La valeur doit être supérieure à 0'); return; }
        setIsSaving(true);
        setError('');
        try {
            const payload = {
                code: code.trim().toUpperCase(),
                type,
                value: Number(value),
                min_order: minOrder ? Number(minOrder) : undefined,
                max_discount: maxDiscount ? Number(maxDiscount) : undefined,
                max_uses: maxUses ? Number(maxUses) : undefined,
                starts_at: startsAt || undefined,
                expires_at: expiresAt || undefined,
                is_active: isActive,
            };
            if (coupon) {
                await couponsApi.update(restaurantId, coupon.id, payload);
            } else {
                await couponsApi.create(restaurantId, payload);
            }
            onSaved();
            onClose();
        } catch (err: unknown) {
            const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
            setError(msg ?? 'Erreur lors de la sauvegarde');
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-xl w-full max-w-lg shadow-xl max-h-[90vh] overflow-y-auto">
                <div className="flex items-center justify-between p-6 border-b sticky top-0 bg-white">
                    <h2 className="text-lg font-semibold">{coupon ? 'Modifier le coupon' : 'Nouveau coupon'}</h2>
                    <button onClick={onClose}><X className="h-5 w-5 text-gray-400" /></button>
                </div>
                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {error && <p className="text-sm text-red-600 bg-red-50 px-3 py-2 rounded-lg">{error}</p>}

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Code *</label>
                            <input value={code} onChange={e => setCode(e.target.value.toUpperCase())}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 font-mono uppercase"
                                placeholder="NOOGO20" />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Type *</label>
                            <select value={type} onChange={e => setType(e.target.value as 'percentage' | 'fixed')}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500">
                                <option value="percentage">Pourcentage (%)</option>
                                <option value="fixed">Montant fixe (FCFA)</option>
                            </select>
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">
                                Valeur * {type === 'percentage' ? '(%)' : '(FCFA)'}
                            </label>
                            <input type="number" value={value} onChange={e => setValue(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500"
                                placeholder={type === 'percentage' ? '20' : '1000'} min="0" max={type === 'percentage' ? '100' : undefined} />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Commande min (FCFA)</label>
                            <input type="number" value={minOrder} onChange={e => setMinOrder(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500"
                                placeholder="5000" min="0" />
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        {type === 'percentage' && (
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1">Plafond (FCFA)</label>
                                <input type="number" value={maxDiscount} onChange={e => setMaxDiscount(e.target.value)}
                                    className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500"
                                    placeholder="2000" min="0" />
                            </div>
                        )}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Utilisations max</label>
                            <input type="number" value={maxUses} onChange={e => setMaxUses(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500"
                                placeholder="100" min="1" />
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Début</label>
                            <input type="date" value={startsAt} onChange={e => setStartsAt(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500" />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Expiration</label>
                            <input type="date" value={expiresAt} onChange={e => setExpiresAt(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500" />
                        </div>
                    </div>

                    <div className="flex items-center gap-3">
                        <button type="button" onClick={() => setIsActive(v => !v)}
                            className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm border ${isActive ? 'border-green-300 text-green-700 bg-green-50' : 'border-gray-200 text-gray-500 bg-gray-50'}`}>
                            {isActive ? <ToggleRight className="h-4 w-4" /> : <ToggleLeft className="h-4 w-4" />}
                            {isActive ? 'Actif' : 'Inactif'}
                        </button>
                    </div>

                    <div className="flex gap-3 pt-2">
                        <button type="button" onClick={onClose} className="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-gray-600 hover:bg-gray-50">Annuler</button>
                        <button type="submit" disabled={isSaving}
                            className="flex-1 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 disabled:opacity-50">
                            {isSaving ? 'Sauvegarde...' : 'Sauvegarder'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}

// ─── Confirm Dialog ───────────────────────────────────────────────────────────

function ConfirmDialog({ message, onConfirm, onCancel }: { message: string; onConfirm: () => void; onCancel: () => void }) {
    return (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onCancel}>
            <div className="bg-white rounded-xl shadow-xl w-full max-w-sm p-6" onClick={e => e.stopPropagation()}>
                <p className="text-gray-800 text-sm mb-6">{message}</p>
                <div className="flex gap-3 justify-end">
                    <button onClick={onCancel} className="px-4 py-2 text-sm border border-gray-200 rounded-lg text-gray-600 hover:bg-gray-50">Annuler</button>
                    <button onClick={onConfirm} className="px-4 py-2 text-sm bg-red-500 text-white rounded-lg hover:bg-red-600">Supprimer</button>
                </div>
            </div>
        </div>
    );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function PromotionsPage() {
    const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
    const [selectedRestaurantId, setSelectedRestaurantId] = useState<number | null>(null);
    const [activeTab, setActiveTab] = useState<'flash' | 'coupons'>('flash');

    // Flash infos state
    const [flashInfos, setFlashInfos] = useState<FlashInfo[]>([]);
    const [flashLoading, setFlashLoading] = useState(false);
    const [flashModal, setFlashModal] = useState<{ open: boolean; flashInfo: FlashInfo | null }>({ open: false, flashInfo: null });

    // Coupons state
    const [coupons, setCoupons] = useState<Coupon[]>([]);
    const [couponsLoading, setCouponsLoading] = useState(false);
    const [couponModal, setCouponModal] = useState<{ open: boolean; coupon: Coupon | null }>({ open: false, coupon: null });

    // Confirm dialog state
    const [confirmDialog, setConfirmDialog] = useState<{ message: string; onConfirm: () => void } | null>(null);

    useEffect(() => {
        restaurantsApi.getAll().then(r => {
            const list: Restaurant[] = r.data.data.data || r.data.data;
            setRestaurants(list);
            if (list.length > 0) setSelectedRestaurantId(list[0].id);
        }).catch(console.error);
    }, []);

    const fetchFlashInfos = useCallback(() => {
        if (!selectedRestaurantId) return;
        setFlashLoading(true);
        flashInfosApi.getAll(selectedRestaurantId)
            .then(r => setFlashInfos(r.data.data || r.data))
            .catch(console.error)
            .finally(() => setFlashLoading(false));
    }, [selectedRestaurantId]);

    useEffect(() => { fetchFlashInfos(); }, [fetchFlashInfos]);

    const fetchCoupons = useCallback(() => {
        if (!selectedRestaurantId) return;
        setCouponsLoading(true);
        couponsApi.getAll(selectedRestaurantId)
            .then(r => setCoupons(r.data.data || r.data))
            .catch(console.error)
            .finally(() => setCouponsLoading(false));
    }, [selectedRestaurantId]);

    useEffect(() => { fetchCoupons(); }, [fetchCoupons]);

    const handleFlashToggle = async (fi: FlashInfo) => {
        if (!selectedRestaurantId) return;
        await flashInfosApi.toggleActive(selectedRestaurantId, fi.id);
        fetchFlashInfos();
    };

    const handleFlashDelete = async (fi: FlashInfo) => {
        if (!selectedRestaurantId) return;
        setConfirmDialog({
            message: `Supprimer "${fi.titre}" ?`,
            onConfirm: async () => {
                setConfirmDialog(null);
                await flashInfosApi.delete(selectedRestaurantId, fi.id);
                fetchFlashInfos();
            },
        });
    };

    const handleCouponToggle = async (c: Coupon) => {
        if (!selectedRestaurantId) return;
        await couponsApi.toggleActive(selectedRestaurantId, c.id);
        fetchCoupons();
    };

    const handleCouponDelete = async (c: Coupon) => {
        if (!selectedRestaurantId) return;
        setConfirmDialog({
            message: `Supprimer le coupon "${c.code}" ?`,
            onConfirm: async () => {
                setConfirmDialog(null);
                await couponsApi.delete(selectedRestaurantId, c.id);
                fetchCoupons();
            },
        });
    };

    const isLoading = activeTab === 'flash' ? flashLoading : couponsLoading;

    return (
        <div className="space-y-6">
            {confirmDialog && (
                <ConfirmDialog
                    message={confirmDialog.message}
                    onConfirm={confirmDialog.onConfirm}
                    onCancel={() => setConfirmDialog(null)}
                />
            )}
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Promotions</h1>
                    <p className="text-gray-600">Gérez les offres, flash infos et codes promo</p>
                </div>
                <div className="flex items-center gap-3">
                    <select
                        value={selectedRestaurantId ?? ''}
                        onChange={e => setSelectedRestaurantId(Number(e.target.value))}
                        className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-orange-500"
                    >
                        {restaurants.map(r => <option key={r.id} value={r.id}>{r.nom}</option>)}
                    </select>
                    {activeTab === 'flash' ? (
                        <button
                            onClick={() => setFlashModal({ open: true, flashInfo: null })}
                            className="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 text-sm"
                        >
                            <Plus className="h-4 w-4" /> Nouvelle promotion
                        </button>
                    ) : (
                        <button
                            onClick={() => setCouponModal({ open: true, coupon: null })}
                            className="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 text-sm"
                        >
                            <Plus className="h-4 w-4" /> Nouveau coupon
                        </button>
                    )}
                </div>
            </div>

            {/* Tabs */}
            <div className="flex gap-1 bg-gray-100 p-1 rounded-lg w-fit">
                <button
                    onClick={() => setActiveTab('flash')}
                    className={`inline-flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${activeTab === 'flash' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}
                >
                    <Tag className="h-4 w-4" /> Flash Infos
                </button>
                <button
                    onClick={() => setActiveTab('coupons')}
                    className={`inline-flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${activeTab === 'coupons' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}
                >
                    <Ticket className="h-4 w-4" /> Codes promo
                    {coupons.length > 0 && (
                        <span className="bg-orange-100 text-orange-700 text-xs px-1.5 py-0.5 rounded-full">{coupons.length}</span>
                    )}
                </button>
            </div>

            {isLoading ? (
                <div className="flex justify-center py-16">
                    <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-orange-500" />
                </div>
            ) : activeTab === 'flash' ? (
                /* ─── Flash Infos Tab ─── */
                flashInfos.length === 0 ? (
                    <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
                        <Tag className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                        <h3 className="text-lg font-medium text-gray-900 mb-2">Aucune promotion</h3>
                        <p className="text-gray-500 mb-4">Créez votre première promotion pour attirer des clients</p>
                        <button
                            onClick={() => setFlashModal({ open: true, flashInfo: null })}
                            className="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600"
                        >
                            <Plus className="h-4 w-4" /> Ajouter une promotion
                        </button>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                        {flashInfos.map(fi => (
                            <div key={fi.id} className={`bg-white rounded-xl border overflow-hidden ${fi.is_active ? 'border-orange-200' : 'border-gray-200 opacity-70'}`}>
                                {fi.image_url && (
                                    <img src={fi.image_url} alt={fi.titre} className="w-full h-36 object-cover" />
                                )}
                                <div className="p-4 space-y-3">
                                    <div className="flex items-start justify-between gap-2">
                                        <div>
                                            <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${TYPE_COLORS[fi.type] ?? 'bg-gray-100 text-gray-600'}`}>
                                                {TYPE_LABELS[fi.type] ?? fi.type}
                                            </span>
                                            <h3 className="font-semibold text-gray-900 mt-1">{fi.titre}</h3>
                                        </div>
                                    </div>
                                    {fi.description && <p className="text-sm text-gray-500 line-clamp-2">{fi.description}</p>}
                                    <div className="flex gap-2 text-xs text-gray-400">
                                        {fi.reduction_percentage && (
                                            <span className="bg-orange-50 text-orange-600 px-2 py-0.5 rounded-full font-semibold">
                                                -{fi.reduction_percentage}%
                                            </span>
                                        )}
                                        {fi.prix_special && (
                                            <span className="bg-green-50 text-green-600 px-2 py-0.5 rounded-full font-semibold">
                                                {fi.prix_special.toLocaleString()} FCFA
                                            </span>
                                        )}
                                        {fi.date_fin && <span>Expire le {new Date(fi.date_fin).toLocaleDateString('fr-FR')}</span>}
                                    </div>
                                    <div className="flex items-center gap-2 pt-1 border-t border-gray-100">
                                        <button onClick={() => handleFlashToggle(fi)}
                                            className={`flex-1 inline-flex items-center justify-center gap-1 px-3 py-1.5 rounded-lg text-sm ${fi.is_active ? 'text-green-600 bg-green-50 hover:bg-green-100' : 'text-gray-500 bg-gray-50 hover:bg-gray-100'}`}>
                                            {fi.is_active ? <ToggleRight className="h-4 w-4" /> : <ToggleLeft className="h-4 w-4" />}
                                            {fi.is_active ? 'Active' : 'Inactive'}
                                        </button>
                                        <button onClick={() => setFlashModal({ open: true, flashInfo: fi })}
                                            className="p-1.5 text-gray-400 hover:bg-gray-50 rounded-lg">
                                            <Pencil className="h-4 w-4" />
                                        </button>
                                        <button onClick={() => handleFlashDelete(fi)}
                                            className="p-1.5 text-red-400 hover:bg-red-50 rounded-lg">
                                            <Trash2 className="h-4 w-4" />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )
            ) : (
                /* ─── Coupons Tab ─── */
                coupons.length === 0 ? (
                    <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
                        <Ticket className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                        <h3 className="text-lg font-medium text-gray-900 mb-2">Aucun code promo</h3>
                        <p className="text-gray-500 mb-4">Créez des codes promo pour fidéliser vos clients</p>
                        <button
                            onClick={() => setCouponModal({ open: true, coupon: null })}
                            className="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600"
                        >
                            <Plus className="h-4 w-4" /> Créer un coupon
                        </button>
                    </div>
                ) : (
                    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
                        <table className="w-full text-sm">
                            <thead className="bg-gray-50 border-b border-gray-200">
                                <tr>
                                    <th className="text-left px-4 py-3 font-medium text-gray-600">Code</th>
                                    <th className="text-left px-4 py-3 font-medium text-gray-600">Réduction</th>
                                    <th className="text-left px-4 py-3 font-medium text-gray-600">Min commande</th>
                                    <th className="text-left px-4 py-3 font-medium text-gray-600">Utilisations</th>
                                    <th className="text-left px-4 py-3 font-medium text-gray-600">Expiration</th>
                                    <th className="text-left px-4 py-3 font-medium text-gray-600">Statut</th>
                                    <th className="px-4 py-3"></th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {coupons.map(c => (
                                    <tr key={c.id} className={c.is_active ? '' : 'opacity-50'}>
                                        <td className="px-4 py-3">
                                            <span className="font-mono font-semibold text-gray-900 bg-gray-100 px-2 py-0.5 rounded">
                                                {c.code}
                                            </span>
                                        </td>
                                        <td className="px-4 py-3 text-orange-600 font-semibold">
                                            {c.type === 'percentage' ? `-${c.value}%` : `-${Number(c.value).toLocaleString()} FCFA`}
                                            {c.max_discount && c.type === 'percentage' && (
                                                <span className="text-xs text-gray-400 ml-1">(max {Number(c.max_discount).toLocaleString()})</span>
                                            )}
                                        </td>
                                        <td className="px-4 py-3 text-gray-500">
                                            {c.min_order ? `${Number(c.min_order).toLocaleString()} FCFA` : '—'}
                                        </td>
                                        <td className="px-4 py-3 text-gray-500">
                                            {c.used_count}{c.max_uses ? `/${c.max_uses}` : ''}
                                        </td>
                                        <td className="px-4 py-3 text-gray-500">
                                            {c.expires_at ? new Date(c.expires_at).toLocaleDateString('fr-FR') : '—'}
                                        </td>
                                        <td className="px-4 py-3">
                                            <button onClick={() => handleCouponToggle(c)}
                                                className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${c.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                                                {c.is_active ? <ToggleRight className="h-3.5 w-3.5" /> : <ToggleLeft className="h-3.5 w-3.5" />}
                                                {c.is_active ? 'Actif' : 'Inactif'}
                                            </button>
                                        </td>
                                        <td className="px-4 py-3">
                                            <div className="flex items-center gap-1">
                                                <button onClick={() => setCouponModal({ open: true, coupon: c })}
                                                    className="p-1.5 text-gray-400 hover:bg-gray-50 rounded-lg">
                                                    <Pencil className="h-4 w-4" />
                                                </button>
                                                <button onClick={() => handleCouponDelete(c)}
                                                    className="p-1.5 text-red-400 hover:bg-red-50 rounded-lg">
                                                    <Trash2 className="h-4 w-4" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )
            )}

            {flashModal.open && selectedRestaurantId && (
                <FlashInfoModal
                    restaurantId={selectedRestaurantId}
                    flashInfo={flashModal.flashInfo}
                    onClose={() => setFlashModal({ open: false, flashInfo: null })}
                    onSaved={fetchFlashInfos}
                />
            )}

            {couponModal.open && selectedRestaurantId && (
                <CouponModal
                    restaurantId={selectedRestaurantId}
                    coupon={couponModal.coupon}
                    onClose={() => setCouponModal({ open: false, coupon: null })}
                    onSaved={fetchCoupons}
                />
            )}
        </div>
    );
}
