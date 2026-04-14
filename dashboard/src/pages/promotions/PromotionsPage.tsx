import { useEffect, useState, useCallback } from 'react';
import { Plus, Pencil, Trash2, Tag, X, ToggleLeft, ToggleRight } from 'lucide-react';
import { flashInfosApi, restaurantsApi } from '../../services/api';
import type { FlashInfo, Restaurant } from '../../types';

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

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function PromotionsPage() {
    const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
    const [selectedRestaurantId, setSelectedRestaurantId] = useState<number | null>(null);
    const [flashInfos, setFlashInfos] = useState<FlashInfo[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [modal, setModal] = useState<{ open: boolean; flashInfo: FlashInfo | null }>({ open: false, flashInfo: null });

    useEffect(() => {
        restaurantsApi.getAll().then(r => {
            const list: Restaurant[] = r.data.data.data || r.data.data;
            setRestaurants(list);
            if (list.length > 0) setSelectedRestaurantId(list[0].id);
        }).catch(console.error);
    }, []);

    const fetchFlashInfos = useCallback(() => {
        if (!selectedRestaurantId) return;
        setIsLoading(true);
        flashInfosApi.getAll(selectedRestaurantId)
            .then(r => setFlashInfos(r.data.data || r.data))
            .catch(console.error)
            .finally(() => setIsLoading(false));
    }, [selectedRestaurantId]);

    useEffect(() => { fetchFlashInfos(); }, [fetchFlashInfos]);

    const handleToggleActive = async (fi: FlashInfo) => {
        if (!selectedRestaurantId) return;
        await flashInfosApi.toggleActive(selectedRestaurantId, fi.id);
        fetchFlashInfos();
    };

    const handleDelete = async (fi: FlashInfo) => {
        if (!selectedRestaurantId) return;
        if (!confirm(`Supprimer "${fi.titre}" ?`)) return;
        await flashInfosApi.delete(selectedRestaurantId, fi.id);
        fetchFlashInfos();
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Promotions</h1>
                    <p className="text-gray-600">Gérez les offres et flash infos</p>
                </div>
                <div className="flex items-center gap-3">
                    <select
                        value={selectedRestaurantId ?? ''}
                        onChange={e => setSelectedRestaurantId(Number(e.target.value))}
                        className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-orange-500"
                    >
                        {restaurants.map(r => <option key={r.id} value={r.id}>{r.nom}</option>)}
                    </select>
                    <button
                        onClick={() => setModal({ open: true, flashInfo: null })}
                        className="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 text-sm"
                    >
                        <Plus className="h-4 w-4" /> Nouvelle promotion
                    </button>
                </div>
            </div>

            {isLoading ? (
                <div className="flex justify-center py-16">
                    <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-orange-500" />
                </div>
            ) : flashInfos.length === 0 ? (
                <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
                    <Tag className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">Aucune promotion</h3>
                    <p className="text-gray-500 mb-4">Créez votre première promotion pour attirer des clients</p>
                    <button
                        onClick={() => setModal({ open: true, flashInfo: null })}
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
                                    <button onClick={() => handleToggleActive(fi)}
                                        className={`flex-1 inline-flex items-center justify-center gap-1 px-3 py-1.5 rounded-lg text-sm ${fi.is_active ? 'text-green-600 bg-green-50 hover:bg-green-100' : 'text-gray-500 bg-gray-50 hover:bg-gray-100'}`}>
                                        {fi.is_active ? <ToggleRight className="h-4 w-4" /> : <ToggleLeft className="h-4 w-4" />}
                                        {fi.is_active ? 'Active' : 'Inactive'}
                                    </button>
                                    <button onClick={() => setModal({ open: true, flashInfo: fi })}
                                        className="p-1.5 text-gray-400 hover:bg-gray-50 rounded-lg">
                                        <Pencil className="h-4 w-4" />
                                    </button>
                                    <button onClick={() => handleDelete(fi)}
                                        className="p-1.5 text-red-400 hover:bg-red-50 rounded-lg">
                                        <Trash2 className="h-4 w-4" />
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {modal.open && selectedRestaurantId && (
                <FlashInfoModal
                    restaurantId={selectedRestaurantId}
                    flashInfo={modal.flashInfo}
                    onClose={() => setModal({ open: false, flashInfo: null })}
                    onSaved={fetchFlashInfos}
                />
            )}
        </div>
    );
}
