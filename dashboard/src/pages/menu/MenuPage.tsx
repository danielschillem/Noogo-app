import { useEffect, useState } from 'react';
import {
    Plus, Pencil, Trash2, ToggleLeft, ToggleRight, Star, UtensilsCrossed, X,
    Search, LayoutGrid, List, ChevronDown, Filter,
} from 'lucide-react';
import { categoriesApi, dishesApi, restaurantsApi } from '../../services/api';
import type { Category, Dish, Restaurant } from '../../types';

function buildImageUrl(path?: string | null): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = (import.meta.env.VITE_IMAGE_BASE_URL || '').replace(/\/$/, '');
    return `${base}/storage/${path.replace(/^\//, '')}`;
}

// ── Modal wrapper ─────────────────────────────────────────────────────────────

function ModalWrapper({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.6)' }}>
            <div className="w-full max-w-md rounded-2xl overflow-hidden max-h-[90vh] flex flex-col" style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
                <div className="flex items-center justify-between px-6 py-4" style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <h2 className="text-base font-bold" style={{ color: '#0f172a' }}>{title}</h2>
                    <button onClick={onClose} className="p-1.5 rounded-lg" style={{ color: '#94a3b8' }}
                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#f8fafc'; }}
                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}>
                        <X size={18} />
                    </button>
                </div>
                <div className="overflow-y-auto flex-1">{children}</div>
            </div>
        </div>
    );
}

// ── Category modal ────────────────────────────────────────────────────────────

function CategoryModal({ restaurantId, category, onClose, onSaved }: { restaurantId: number; category: Category | null; onClose: () => void; onSaved: () => void; }) {
    const [nom, setNom] = useState(category?.nom ?? '');
    const [description, setDescription] = useState(category?.description ?? '');
    const [image, setImage] = useState<File | null>(null);
    const [isSaving, setIsSaving] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!nom.trim()) { setError('Le nom est requis'); return; }
        setIsSaving(true); setError('');
        try {
            const fd = new FormData();
            fd.append('nom', nom.trim());
            if (description) fd.append('description', description);
            if (image) fd.append('image', image);
            category ? await categoriesApi.update(restaurantId, category.id, fd) : await categoriesApi.create(restaurantId, fd);
            onSaved(); onClose();
        } catch { setError('Erreur lors de la sauvegarde'); }
        finally { setIsSaving(false); }
    };

    return (
        <ModalWrapper title={category ? 'Modifier la catégorie' : 'Nouvelle catégorie'} onClose={onClose}>
            <form onSubmit={handleSubmit} className="p-6 space-y-4">
                {error && <div className="px-4 py-3 rounded-xl text-sm" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>{error}</div>}
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Nom *</label>
                    <input value={nom} onChange={e => setNom(e.target.value)} className="input-pro" placeholder="Ex: Entrées" />
                </div>
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Description</label>
                    <textarea value={description} onChange={e => setDescription(e.target.value)} rows={2} className="input-pro resize-none" />
                </div>
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Image</label>
                    <input type="file" accept="image/*" onChange={e => setImage(e.target.files?.[0] ?? null)} className="w-full text-sm" style={{ color: '#64748b' }} />
                </div>
                <div className="flex gap-3 pt-1">
                    <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium" style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>Annuler</button>
                    <button type="submit" disabled={isSaving} className="flex-1 btn-primary">{isSaving ? 'Sauvegarde…' : 'Sauvegarder'}</button>
                </div>
            </form>
        </ModalWrapper>
    );
}

// ── Dish modal ────────────────────────────────────────────────────────────────

function DishModal({ restaurantId, categories, dish, defaultCategoryId, onClose, onSaved }: { restaurantId: number; categories: Category[]; dish: Dish | null; defaultCategoryId?: number; onClose: () => void; onSaved: () => void; }) {
    const [nom, setNom] = useState(dish?.nom ?? '');
    const [description, setDescription] = useState(dish?.description ?? '');
    const [prix, setPrix] = useState(dish?.prix?.toString() ?? '');
    const [categoryId, setCategoryId] = useState<number>(dish?.category_id ?? defaultCategoryId ?? categories[0]?.id ?? 0);
    const [tempsPrep, setTempsPrep] = useState(dish?.temps_preparation?.toString() ?? '15');
    const [image, setImage] = useState<File | null>(null);
    const [isSaving, setIsSaving] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!nom.trim()) { setError('Le nom est requis'); return; }
        if (!prix || isNaN(Number(prix)) || Number(prix) <= 0) { setError('Prix invalide'); return; }
        if (!categoryId) { setError('Sélectionnez une catégorie'); return; }
        setIsSaving(true); setError('');
        try {
            const fd = new FormData();
            fd.append('nom', nom.trim()); fd.append('prix', prix);
            fd.append('category_id', categoryId.toString()); fd.append('temps_preparation', tempsPrep || '15');
            if (description) fd.append('description', description);
            if (image) fd.append('image', image);
            dish ? await dishesApi.update(restaurantId, dish.id, fd) : await dishesApi.create(restaurantId, fd);
            onSaved(); onClose();
        } catch { setError('Erreur lors de la sauvegarde'); }
        finally { setIsSaving(false); }
    };

    return (
        <ModalWrapper title={dish ? 'Modifier le plat' : 'Nouveau plat'} onClose={onClose}>
            <form onSubmit={handleSubmit} className="p-6 space-y-4">
                {error && <div className="px-4 py-3 rounded-xl text-sm" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>{error}</div>}
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Nom *</label>
                    <input value={nom} onChange={e => setNom(e.target.value)} className="input-pro" placeholder="Ex: Riz gras" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Prix (FCFA) *</label>
                        <input type="number" value={prix} onChange={e => setPrix(e.target.value)} className="input-pro" placeholder="1500" min="0" />
                    </div>
                    <div>
                        <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Temps prépa (min)</label>
                        <input type="number" value={tempsPrep} onChange={e => setTempsPrep(e.target.value)} className="input-pro" placeholder="15" min="1" />
                    </div>
                </div>
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Catégorie *</label>
                    <select value={categoryId} onChange={e => setCategoryId(Number(e.target.value))} className="input-pro">
                        {categories.map(c => <option key={c.id} value={c.id}>{c.nom}</option>)}
                    </select>
                </div>
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Description</label>
                    <textarea value={description} onChange={e => setDescription(e.target.value)} rows={3} className="input-pro resize-none" />
                </div>
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Image</label>
                    <input type="file" accept="image/*" onChange={e => setImage(e.target.files?.[0] ?? null)} className="w-full text-sm" style={{ color: '#64748b' }} />
                </div>
                <div className="flex gap-3 pt-1">
                    <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium" style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>Annuler</button>
                    <button type="submit" disabled={isSaving} className="flex-1 btn-primary">{isSaving ? 'Sauvegarde…' : 'Sauvegarder'}</button>
                </div>
            </form>
        </ModalWrapper>
    );
}

// ── Dish card (grid view) ─────────────────────────────────────────────────────

function DishCard({ dish, onEdit, onDelete, onToggleAvail, onTogglePdj }: {
    dish: Dish;
    onEdit: () => void;
    onDelete: () => void;
    onToggleAvail: () => void;
    onTogglePdj: () => void;
}) {
    const imgUrl = buildImageUrl(dish.image_url);
    return (
        <div className="rounded-2xl overflow-hidden flex flex-col transition-all duration-150"
            style={{
                background: 'white',
                border: '1px solid #f1f5f9',
                boxShadow: '0 2px 8px rgba(0,0,0,0.05)',
                opacity: dish.disponibilite ? 1 : 0.65,
            }}>
            {/* Image */}
            <div className="relative" style={{ paddingTop: '62%', background: '#f8fafc', flexShrink: 0 }}>
                {imgUrl ? (
                    <img src={imgUrl} alt={dish.nom} className="absolute inset-0 w-full h-full object-cover" />
                ) : (
                    <div className="absolute inset-0 flex items-center justify-center">
                        <UtensilsCrossed className="h-10 w-10" style={{ color: '#e2e8f0' }} />
                    </div>
                )}
                {/* Badges overlay */}
                <div className="absolute top-2 left-2 flex gap-1 flex-wrap">
                    {dish.is_plat_du_jour && (
                        <span className="text-[10px] px-1.5 py-0.5 rounded-md font-semibold" style={{ background: '#fefce8', color: '#a16207', border: '1px solid #fde68a' }}>
                            ★ Plat du jour
                        </span>
                    )}
                    {!dish.disponibilite && (
                        <span className="text-[10px] px-1.5 py-0.5 rounded-md font-semibold" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                            Indisponible
                        </span>
                    )}
                </div>
            </div>

            {/* Body */}
            <div className="p-3 flex-1 flex flex-col gap-1">
                <p className="font-semibold text-sm leading-snug" style={{ color: '#0f172a' }}>{dish.nom}</p>
                {dish.description && (
                    <p className="text-xs line-clamp-2" style={{ color: '#94a3b8' }}>{dish.description}</p>
                )}
                <p className="text-sm font-bold mt-auto pt-1" style={{ color: '#f97316' }}>
                    {dish.prix?.toLocaleString()} FCFA
                </p>
                {dish.temps_preparation > 0 && (
                    <p className="text-[11px]" style={{ color: '#cbd5e1' }}>⏱ {dish.temps_preparation} min</p>
                )}
            </div>

            {/* Actions */}
            <div className="flex items-center border-t px-3 py-2 gap-1" style={{ borderColor: '#f8fafc' }}>
                <button onClick={onToggleAvail} title={dish.disponibilite ? 'Marquer indisponible' : 'Marquer disponible'}
                    className="p-1.5 rounded-lg flex-1 flex justify-center transition-colors"
                    style={{ color: dish.disponibilite ? '#16a34a' : '#cbd5e1' }}
                    onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = dish.disponibilite ? '#f0fdf4' : '#f8fafc'; }}
                    onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}>
                    {dish.disponibilite ? <ToggleRight size={20} /> : <ToggleLeft size={20} />}
                </button>
                <button onClick={onTogglePdj} title="Plat du jour"
                    className="p-1.5 rounded-lg flex-1 flex justify-center transition-colors"
                    style={{ color: dish.is_plat_du_jour ? '#ca8a04' : '#cbd5e1' }}
                    onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fefce8'; }}
                    onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}>
                    <Star size={15} />
                </button>
                <button onClick={onEdit} title="Modifier"
                    className="p-1.5 rounded-lg flex-1 flex justify-center transition-colors"
                    style={{ color: '#94a3b8' }}
                    onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#eff6ff'; (e.currentTarget as HTMLButtonElement).style.color = '#2563eb'; }}
                    onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                    <Pencil size={14} />
                </button>
                <button onClick={onDelete} title="Supprimer"
                    className="p-1.5 rounded-lg flex-1 flex justify-center transition-colors"
                    style={{ color: '#94a3b8' }}
                    onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fef2f2'; (e.currentTarget as HTMLButtonElement).style.color = '#dc2626'; }}
                    onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                    <Trash2 size={14} />
                </button>
            </div>
        </div>
    );
}

// ── Main page ─────────────────────────────────────────────────────────────────

export default function MenuPage() {
    const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
    const [selectedRestaurantId, setSelectedRestaurantId] = useState<number | null>(null);
    const [categories, setCategories] = useState<Category[]>([]);
    const [dishes, setDishes] = useState<Dish[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
    const [selectedCategoryId, setSelectedCategoryId] = useState<number | null>(null);
    const [search, setSearch] = useState('');
    const [showUnavailable, setShowUnavailable] = useState(true);
    const [categoryModal, setCategoryModal] = useState<{ open: boolean; category: Category | null }>({ open: false, category: null });
    const [dishModal, setDishModal] = useState<{ open: boolean; dish: Dish | null; categoryId?: number }>({ open: false, dish: null });

    useEffect(() => {
        restaurantsApi.getAll().then(r => {
            const list: Restaurant[] = r.data.data.data || r.data.data;
            setRestaurants(list);
            if (list.length > 0) setSelectedRestaurantId(list[0].id);
        }).catch(console.error);
    }, []);

    useEffect(() => {
        if (!selectedRestaurantId) return;
        setIsLoading(true);
        Promise.all([categoriesApi.getAll(selectedRestaurantId), dishesApi.getAll(selectedRestaurantId)])
            .then(([catRes, dishRes]) => {
                const cats: Category[] = catRes.data.data || catRes.data;
                const dis: Dish[] = dishRes.data.data?.data ?? dishRes.data.data ?? dishRes.data;
                setCategories(Array.isArray(cats) ? cats : []);
                setDishes(Array.isArray(dis) ? dis : []);
            }).catch(console.error).finally(() => setIsLoading(false));
    }, [selectedRestaurantId]);

    const reload = () => {
        if (!selectedRestaurantId) return;
        Promise.all([categoriesApi.getAll(selectedRestaurantId), dishesApi.getAll(selectedRestaurantId)])
            .then(([catRes, dishRes]) => {
                const cats = catRes.data.data || catRes.data;
                const dis = dishRes.data.data?.data ?? dishRes.data.data ?? dishRes.data;
                setCategories(Array.isArray(cats) ? cats : []);
                setDishes(Array.isArray(dis) ? dis : []);
            }).catch(console.error);
    };

    const handleDeleteDish = async (dish: Dish) => {
        if (!selectedRestaurantId) return;
        if (!confirm(`Supprimer le plat "${dish.nom}" ?`)) return;
        await dishesApi.delete(selectedRestaurantId, dish.id); reload();
    };

    const handleToggleDishAvailability = async (dish: Dish) => {
        if (!selectedRestaurantId) return;
        await dishesApi.toggleAvailability(selectedRestaurantId, dish.id); reload();
    };

    const handleTogglePlatDuJour = async (dish: Dish) => {
        if (!selectedRestaurantId) return;
        await dishesApi.togglePlatDuJour(selectedRestaurantId, dish.id); reload();
    };

    // ── Filtering ──
    let filteredDishes = dishes;
    if (selectedCategoryId) filteredDishes = filteredDishes.filter(d => d.category_id === selectedCategoryId);
    if (!showUnavailable) filteredDishes = filteredDishes.filter(d => d.disponibilite);
    if (search.trim()) filteredDishes = filteredDishes.filter(d => d.nom.toLowerCase().includes(search.toLowerCase()) || d.description?.toLowerCase().includes(search.toLowerCase()));

    const totalDishes = dishes.length;
    const availableDishes = dishes.filter(d => d.disponibilite).length;

    return (
        <div className="space-y-5 animate-fadeIn">

            {/* ── Header ── */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: '#0f172a' }}>Menu</h1>
                    <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>
                        {categories.length} catégorie{categories.length !== 1 ? 's' : ''} · {totalDishes} plat{totalDishes !== 1 ? 's' : ''} · {availableDishes} disponible{availableDishes !== 1 ? 's' : ''}
                    </p>
                </div>
                <div className="flex items-center gap-2 flex-wrap">
                    {restaurants.length > 1 && (
                        <select value={selectedRestaurantId ?? ''} onChange={e => setSelectedRestaurantId(Number(e.target.value))} className="input-pro text-sm" style={{ width: 'auto' }}>
                            {restaurants.map(r => <option key={r.id} value={r.id}>{r.nom}</option>)}
                        </select>
                    )}
                    <button onClick={() => setCategoryModal({ open: true, category: null })} className="px-3 py-2 rounded-xl text-sm font-medium flex items-center gap-1.5" style={{ background: '#f8fafc', color: '#374151', border: '1px solid #e2e8f0' }}>
                        <Plus size={15} /> Catégorie
                    </button>
                    <button onClick={() => setDishModal({ open: true, dish: null, categoryId: selectedCategoryId ?? undefined })} className="btn-primary text-sm">
                        <Plus size={15} /> Plat
                    </button>
                </div>
            </div>

            {/* ── Stats ── */}
            <div className="grid grid-cols-3 gap-3">
                {[
                    { label: 'Catégories', value: categories.length, color: '#7c3aed', bg: '#faf5ff' },
                    { label: 'Plats', value: totalDishes, color: '#f97316', bg: '#fff7ed' },
                    { label: 'Disponibles', value: availableDishes, color: '#16a34a', bg: '#f0fdf4' },
                ].map(s => (
                    <div key={s.label} className="rounded-2xl p-4 text-center" style={{ background: 'white', border: '1px solid #f1f5f9' }}>
                        <p className="text-2xl font-bold" style={{ color: s.color }}>{s.value}</p>
                        <p className="text-xs font-semibold mt-0.5" style={{ color: '#64748b' }}>{s.label}</p>
                    </div>
                ))}
            </div>

            {/* ── Toolbar ── */}
            <div className="flex flex-wrap items-center gap-3">
                {/* Search */}
                <div className="relative flex-1 min-w-48">
                    <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: '#94a3b8' }} />
                    <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Rechercher un plat…"
                        className="input-pro pl-10 w-full" />
                </div>

                {/* Category filter */}
                <div className="relative">
                    <Filter className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 pointer-events-none" style={{ color: '#94a3b8' }} />
                    <select value={selectedCategoryId ?? ''} onChange={e => setSelectedCategoryId(e.target.value ? Number(e.target.value) : null)}
                        className="input-pro pl-8 pr-8 text-sm" style={{ appearance: 'none', minWidth: 150 }}>
                        <option value="">Toutes les catégories</option>
                        {categories.map(c => <option key={c.id} value={c.id}>{c.nom}</option>)}
                    </select>
                    <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 pointer-events-none" style={{ color: '#94a3b8' }} />
                </div>

                {/* Toggle unavailable */}
                <button onClick={() => setShowUnavailable(v => !v)}
                    className="text-xs px-3 py-2 rounded-xl font-medium flex items-center gap-1.5 transition-colors"
                    style={showUnavailable ? { background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' } : { background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                    {showUnavailable ? '👁 Tous' : '🚫 Masqués'}
                </button>

                {/* View toggle */}
                <div className="flex rounded-xl overflow-hidden" style={{ border: '1px solid #e2e8f0' }}>
                    <button onClick={() => setViewMode('grid')} className="p-2 transition-colors"
                        style={{ background: viewMode === 'grid' ? '#f97316' : 'white', color: viewMode === 'grid' ? 'white' : '#94a3b8' }}>
                        <LayoutGrid size={16} />
                    </button>
                    <button onClick={() => setViewMode('list')} className="p-2 transition-colors"
                        style={{ background: viewMode === 'list' ? '#f97316' : 'white', color: viewMode === 'list' ? 'white' : '#94a3b8' }}>
                        <List size={16} />
                    </button>
                </div>
            </div>

            {/* ── Category tabs ── */}
            {categories.length > 0 && (
                <div className="flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
                    <button onClick={() => setSelectedCategoryId(null)}
                        className="px-4 py-1.5 rounded-xl text-sm font-semibold flex-shrink-0 transition-colors"
                        style={!selectedCategoryId ? { background: '#f97316', color: 'white' } : { background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>
                        Tous ({dishes.length})
                    </button>
                    {categories.map(cat => {
                        const count = dishes.filter(d => d.category_id === cat.id).length;
                        const isActive = selectedCategoryId === cat.id;
                        return (
                            <button key={cat.id} onClick={() => setSelectedCategoryId(isActive ? null : cat.id)}
                                className="px-4 py-1.5 rounded-xl text-sm font-semibold flex-shrink-0 transition-colors flex items-center gap-2"
                                style={isActive ? { background: '#f97316', color: 'white' } : { background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>
                                {cat.image_url && <img src={buildImageUrl(cat.image_url)} alt="" className="w-4 h-4 rounded object-cover" />}
                                {cat.nom} ({count})
                            </button>
                        );
                    })}
                </div>
            )}

            {/* ── Content ── */}
            {isLoading ? (
                <div className="flex justify-center py-20">
                    <div className="w-10 h-10 rounded-xl flex items-center justify-center animate-pulse" style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                        <UtensilsCrossed className="h-5 w-5 text-white" />
                    </div>
                </div>
            ) : filteredDishes.length === 0 ? (
                <div className="text-center py-20 rounded-2xl" style={{ background: 'white', border: '1px solid #f1f5f9' }}>
                    <div className="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-4" style={{ background: '#f8fafc' }}>
                        <UtensilsCrossed className="h-8 w-8" style={{ color: '#cbd5e1' }} />
                    </div>
                    <p className="font-semibold" style={{ color: '#374151' }}>{search || selectedCategoryId ? 'Aucun résultat' : 'Aucun plat'}</p>
                    <p className="text-sm mt-1 mb-5" style={{ color: '#94a3b8' }}>
                        {search ? 'Essayez un autre terme' : selectedCategoryId ? 'Cette catégorie est vide' : 'Créez votre premier plat'}
                    </p>
                    {!search && <button onClick={() => setDishModal({ open: true, dish: null })} className="btn-primary"><Plus size={16} /> Ajouter un plat</button>}
                </div>
            ) : viewMode === 'grid' ? (
                /* ─ Image grid ─ */
                <div className="grid gap-4" style={{ gridTemplateColumns: 'repeat(auto-fill,minmax(200px,1fr))' }}>
                    {filteredDishes.map(dish => (
                        <DishCard key={dish.id} dish={dish}
                            onEdit={() => setDishModal({ open: true, dish, categoryId: dish.category_id })}
                            onDelete={() => handleDeleteDish(dish)}
                            onToggleAvail={() => handleToggleDishAvailability(dish)}
                            onTogglePdj={() => handleTogglePlatDuJour(dish)}
                        />
                    ))}
                </div>
            ) : (
                /* ─ List view ─ */
                <div className="rounded-2xl overflow-hidden" style={{ background: 'white', border: '1px solid #f1f5f9' }}>
                    {filteredDishes.map((dish, idx) => {
                        const imgUrl = buildImageUrl(dish.image_url);
                        return (
                            <div key={dish.id} className="flex items-center gap-3 px-4 py-3 transition-colors"
                                style={{ borderTop: idx === 0 ? 'none' : '1px solid #f8fafc', opacity: dish.disponibilite ? 1 : 0.6 }}>
                                {imgUrl ? (
                                    <img src={imgUrl} alt={dish.nom} className="w-12 h-12 rounded-xl object-cover flex-shrink-0" style={{ border: '1px solid #f1f5f9' }} />
                                ) : (
                                    <div className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0" style={{ background: '#f8fafc' }}>
                                        <UtensilsCrossed className="h-5 w-5" style={{ color: '#cbd5e1' }} />
                                    </div>
                                )}
                                <div className="flex-1 min-w-0">
                                    <div className="flex items-center gap-2">
                                        <p className="font-semibold text-sm truncate" style={{ color: '#0f172a' }}>{dish.nom}</p>
                                        {dish.is_plat_du_jour && (
                                            <span className="text-[10px] px-1.5 py-0.5 rounded-md font-semibold flex-shrink-0" style={{ background: '#fefce8', color: '#a16207', border: '1px solid #fde68a' }}>★ Plat du jour</span>
                                        )}
                                    </div>
                                    <p className="text-sm font-bold" style={{ color: '#f97316' }}>{dish.prix?.toLocaleString()} FCFA</p>
                                    {dish.description && <p className="text-xs truncate" style={{ color: '#94a3b8' }}>{dish.description}</p>}
                                </div>
                                <div className="flex items-center gap-0.5 flex-shrink-0">
                                    <button onClick={() => handleToggleDishAvailability(dish)} className="p-1.5 rounded-lg transition-colors"
                                        style={{ color: dish.disponibilite ? '#16a34a' : '#cbd5e1' }}
                                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#f0fdf4'; }}
                                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}>
                                        {dish.disponibilite ? <ToggleRight size={20} /> : <ToggleLeft size={20} />}
                                    </button>
                                    <button onClick={() => handleTogglePlatDuJour(dish)} className="p-1.5 rounded-lg transition-colors"
                                        style={{ color: dish.is_plat_du_jour ? '#ca8a04' : '#cbd5e1' }}
                                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fefce8'; }}
                                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}>
                                        <Star size={14} />
                                    </button>
                                    <button onClick={() => setDishModal({ open: true, dish, categoryId: dish.category_id })}
                                        className="p-1.5 rounded-lg transition-colors" style={{ color: '#94a3b8' }}
                                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#eff6ff'; (e.currentTarget as HTMLButtonElement).style.color = '#2563eb'; }}
                                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                                        <Pencil size={14} />
                                    </button>
                                    <button onClick={() => handleDeleteDish(dish)}
                                        className="p-1.5 rounded-lg transition-colors" style={{ color: '#94a3b8' }}
                                        onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fef2f2'; (e.currentTarget as HTMLButtonElement).style.color = '#dc2626'; }}
                                        onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                                        <Trash2 size={14} />
                                    </button>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}

            {/* Modals */}
            {categoryModal.open && selectedRestaurantId && (
                <CategoryModal restaurantId={selectedRestaurantId} category={categoryModal.category}
                    onClose={() => setCategoryModal({ open: false, category: null })} onSaved={reload} />
            )}
            {dishModal.open && selectedRestaurantId && (
                <DishModal restaurantId={selectedRestaurantId} categories={categories}
                    dish={dishModal.dish} defaultCategoryId={dishModal.categoryId}
                    onClose={() => setDishModal({ open: false, dish: null })} onSaved={reload} />
            )}
        </div>
    );
}
