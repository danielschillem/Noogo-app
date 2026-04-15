import { useEffect, useState } from 'react';
import {
    Plus, Pencil, Trash2, ChevronDown, ChevronRight,
    ToggleLeft, ToggleRight, Star, UtensilsCrossed, X, GripVertical,
} from 'lucide-react';
import { categoriesApi, dishesApi, restaurantsApi } from '../../services/api';
import type { Category, Dish, Restaurant } from '../../types';

function buildImageUrl(path?: string | null): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = (import.meta.env.VITE_IMAGE_BASE_URL || '').replace(/\/$/, '');
    return `${base}/storage/${path.replace(/^\//, '')}`;
}

// ─── Shared Modal Wrapper ────────────────────────────────────────────────────

function ModalWrapper({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.6)' }}>
            <div className="w-full max-w-md rounded-2xl overflow-hidden max-h-[90vh] flex flex-col"
                style={{ background: 'white', boxShadow: '0 25px 60px rgba(0,0,0,0.2)' }}>
                <div className="flex items-center justify-between px-6 py-4"
                    style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <h2 className="text-base font-bold" style={{ color: '#0f172a' }}>{title}</h2>
                    <button onClick={onClose} className="p-1.5 rounded-lg transition-colors"
                        style={{ color: '#94a3b8' }}
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

// ─── Category Form Modal ─────────────────────────────────────────────────────

function CategoryModal({ restaurantId, category, onClose, onSaved }: {
    restaurantId: number; category: Category | null; onClose: () => void; onSaved: () => void;
}) {
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
                {error && <div className="px-4 py-3 rounded-xl text-sm"
                    style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>{error}</div>}
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Nom *</label>
                    <input value={nom} onChange={e => setNom(e.target.value)} className="input-pro" placeholder="Ex: Entrées" />
                </div>
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Description</label>
                    <textarea value={description} onChange={e => setDescription(e.target.value)}
                        rows={2} className="input-pro resize-none" />
                </div>
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Image</label>
                    <input type="file" accept="image/*" onChange={e => setImage(e.target.files?.[0] ?? null)}
                        className="w-full text-sm" style={{ color: '#64748b' }} />
                </div>
                <div className="flex gap-3 pt-1">
                    <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium"
                        style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>Annuler</button>
                    <button type="submit" disabled={isSaving} className="flex-1 btn-primary">
                        {isSaving ? 'Sauvegarde…' : 'Sauvegarder'}
                    </button>
                </div>
            </form>
        </ModalWrapper>
    );
}

// ─── Dish Form Modal ─────────────────────────────────────────────────────────

function DishModal({ restaurantId, categories, dish, defaultCategoryId, onClose, onSaved }: {
    restaurantId: number; categories: Category[]; dish: Dish | null;
    defaultCategoryId?: number; onClose: () => void; onSaved: () => void;
}) {
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
            fd.append('nom', nom.trim());
            fd.append('prix', prix);
            fd.append('category_id', categoryId.toString());
            fd.append('temps_preparation', tempsPrep || '15');
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
                {error && <div className="px-4 py-3 rounded-xl text-sm"
                    style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>{error}</div>}
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Nom *</label>
                    <input value={nom} onChange={e => setNom(e.target.value)} className="input-pro" placeholder="Ex: Riz gras" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Prix (FCFA) *</label>
                        <input type="number" value={prix} onChange={e => setPrix(e.target.value)}
                            className="input-pro" placeholder="1500" min="0" />
                    </div>
                    <div>
                        <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Temps prépa (min)</label>
                        <input type="number" value={tempsPrep} onChange={e => setTempsPrep(e.target.value)}
                            className="input-pro" placeholder="15" min="1" />
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
                    <textarea value={description} onChange={e => setDescription(e.target.value)}
                        rows={3} className="input-pro resize-none" />
                </div>
                <div>
                    <label className="block text-xs font-semibold mb-1.5" style={{ color: '#374151' }}>Image</label>
                    <input type="file" accept="image/*" onChange={e => setImage(e.target.files?.[0] ?? null)}
                        className="w-full text-sm" style={{ color: '#64748b' }} />
                </div>
                <div className="flex gap-3 pt-1">
                    <button type="button" onClick={onClose} className="flex-1 px-4 py-2.5 rounded-xl text-sm font-medium"
                        style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0' }}>Annuler</button>
                    <button type="submit" disabled={isSaving} className="flex-1 btn-primary">
                        {isSaving ? 'Sauvegarde…' : 'Sauvegarder'}
                    </button>
                </div>
            </form>
        </ModalWrapper>
    );
}

// ─── Main Page ───────────────────────────────────────────────────────────────

export default function MenuPage() {
    const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
    const [selectedRestaurantId, setSelectedRestaurantId] = useState<number | null>(null);
    const [categories, setCategories] = useState<Category[]>([]);
    const [dishes, setDishes] = useState<Dish[]>([]);
    const [expandedCategories, setExpandedCategories] = useState<Set<number>>(new Set());
    const [isLoading, setIsLoading] = useState(false);
    const [categoryModal, setCategoryModal] = useState<{ open: boolean; category: Category | null }>({ open: false, category: null });
    const [dishModal, setDishModal] = useState<{ open: boolean; dish: Dish | null; categoryId?: number }>({ open: false, dish: null });

    const [dragCatIdx, setDragCatIdx] = useState<number | null>(null);
    const [dragOverCatIdx, setDragOverCatIdx] = useState<number | null>(null);
    const [dragDishId, setDragDishId] = useState<number | null>(null);
    const [dragOverDishId, setDragOverDishId] = useState<number | null>(null);

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
                const dis: Dish[] = dishRes.data.data || dishRes.data;
                setCategories(cats);
                setDishes(dis);
                setExpandedCategories(new Set(cats.map(c => c.id)));
            }).catch(console.error).finally(() => setIsLoading(false));
    }, [selectedRestaurantId]);

    const reload = () => {
        if (!selectedRestaurantId) return;
        Promise.all([categoriesApi.getAll(selectedRestaurantId), dishesApi.getAll(selectedRestaurantId)])
            .then(([catRes, dishRes]) => {
                setCategories(catRes.data.data || catRes.data);
                setDishes(dishRes.data.data || dishRes.data);
            }).catch(console.error);
    };

    const toggleCategory = (id: number) => {
        setExpandedCategories(prev => {
            const next = new Set(prev);
            next.has(id) ? next.delete(id) : next.add(id);
            return next;
        });
    };

    const handleDeleteCategory = async (cat: Category) => {
        if (!selectedRestaurantId) return;
        if (!confirm(`Supprimer la catégorie "${cat.nom}" et tous ses plats ?`)) return;
        await categoriesApi.delete(selectedRestaurantId, cat.id);
        reload();
    };

    const handleDeleteDish = async (dish: Dish) => {
        if (!selectedRestaurantId) return;
        if (!confirm(`Supprimer le plat "${dish.nom}" ?`)) return;
        await dishesApi.delete(selectedRestaurantId, dish.id);
        reload();
    };

    const handleToggleDishAvailability = async (dish: Dish) => {
        if (!selectedRestaurantId) return;
        await dishesApi.toggleAvailability(selectedRestaurantId, dish.id);
        reload();
    };

    const handleTogglePlatDuJour = async (dish: Dish) => {
        if (!selectedRestaurantId) return;
        await dishesApi.togglePlatDuJour(selectedRestaurantId, dish.id);
        reload();
    };

    const dishesInCategory = (categoryId: number) => dishes.filter(d => d.category_id === categoryId);

    const handleCatDrop = (overIdx: number) => {
        if (dragCatIdx === null || dragCatIdx === overIdx) { setDragCatIdx(null); setDragOverCatIdx(null); return; }
        const reordered = [...categories];
        const [item] = reordered.splice(dragCatIdx, 1);
        reordered.splice(overIdx, 0, item);
        setCategories(reordered);
        setDragCatIdx(null); setDragOverCatIdx(null);
        if (selectedRestaurantId)
            categoriesApi.reorder(selectedRestaurantId, reordered.map((c, i) => ({ id: c.id, ordre: i }))).catch(console.error);
    };

    const handleDishDrop = (fromId: number, toId: number, catId: number) => {
        if (fromId === toId) return;
        const catDishes = dishes.filter(d => d.category_id === catId);
        const others = dishes.filter(d => d.category_id !== catId);
        const fromIdx = catDishes.findIndex(d => d.id === fromId);
        const toIdx = catDishes.findIndex(d => d.id === toId);
        if (fromIdx === -1 || toIdx === -1) return;
        const reordered = [...catDishes];
        const [item] = reordered.splice(fromIdx, 1);
        reordered.splice(toIdx, 0, item);
        setDishes([...others, ...reordered]);
        setDragDishId(null); setDragOverDishId(null);
        if (selectedRestaurantId)
            dishesApi.reorder(selectedRestaurantId, reordered.map((d, i) => ({ id: d.id, ordre: i }))).catch(console.error);
    };

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
                <div className="flex items-center gap-3">
                    {restaurants.length > 1 && (
                        <select value={selectedRestaurantId ?? ''} onChange={e => setSelectedRestaurantId(Number(e.target.value))}
                            className="input-pro text-sm" style={{ width: 'auto' }}>
                            {restaurants.map(r => <option key={r.id} value={r.id}>{r.nom}</option>)}
                        </select>
                    )}
                    <button onClick={() => setCategoryModal({ open: true, category: null })} className="btn-primary text-sm">
                        <Plus size={16} /> Catégorie
                    </button>
                </div>
            </div>

            {/* ── Content ── */}
            {isLoading ? (
                <div className="flex justify-center py-20">
                    <div className="w-10 h-10 rounded-xl flex items-center justify-center animate-pulse"
                        style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                        <UtensilsCrossed className="h-5 w-5 text-white" />
                    </div>
                </div>
            ) : categories.length === 0 ? (
                <div className="text-center py-20 rounded-2xl"
                    style={{ background: 'white', border: '1px solid #f1f5f9' }}>
                    <div className="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-4"
                        style={{ background: '#f8fafc' }}>
                        <UtensilsCrossed className="h-8 w-8" style={{ color: '#cbd5e1' }} />
                    </div>
                    <p className="font-semibold" style={{ color: '#374151' }}>Aucune catégorie</p>
                    <p className="text-sm mt-1 mb-5" style={{ color: '#94a3b8' }}>Créez votre première catégorie pour commencer</p>
                    <button onClick={() => setCategoryModal({ open: true, category: null })} className="btn-primary">
                        <Plus size={16} /> Ajouter une catégorie
                    </button>
                </div>
            ) : (
                <div className="space-y-3">
                    {categories.map((cat, catIdx) => {
                        const catDishes = dishesInCategory(cat.id);
                        const isExpanded = expandedCategories.has(cat.id);
                        const isDragOver = dragOverCatIdx === catIdx && dragCatIdx !== catIdx;
                        return (
                            <div key={cat.id} className="rounded-2xl overflow-hidden transition-all duration-150"
                                style={{
                                    background: 'white',
                                    border: `1px solid ${isDragOver ? '#f97316' : '#f1f5f9'}`,
                                    boxShadow: isDragOver ? '0 0 0 3px rgba(249,115,22,0.15)' : '0 1px 3px rgba(0,0,0,0.04)',
                                    opacity: dragCatIdx === catIdx ? 0.5 : 1,
                                }}
                                draggable
                                onDragStart={() => setDragCatIdx(catIdx)}
                                onDragOver={e => { e.preventDefault(); setDragOverCatIdx(catIdx); }}
                                onDragLeave={() => setDragOverCatIdx(null)}
                                onDrop={() => handleCatDrop(catIdx)}
                                onDragEnd={() => { setDragCatIdx(null); setDragOverCatIdx(null); }}>

                                {/* Category header */}
                                <div className="flex items-center gap-3 px-4 py-3.5"
                                    style={{ borderBottom: isExpanded ? '1px solid #f8fafc' : 'none' }}>
                                    <GripVertical className="h-4 w-4 cursor-grab flex-shrink-0" style={{ color: '#cbd5e1' }} />
                                    <button onClick={() => toggleCategory(cat.id)} className="flex-shrink-0"
                                        style={{ color: '#94a3b8' }}>
                                        {isExpanded ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
                                    </button>
                                    {cat.image_url && (
                                        <img src={buildImageUrl(cat.image_url)} alt={cat.nom}
                                            className="w-9 h-9 rounded-xl object-cover flex-shrink-0"
                                            style={{ border: '1px solid #f1f5f9' }} />
                                    )}
                                    <div className="flex-1 min-w-0" onClick={() => toggleCategory(cat.id)} style={{ cursor: 'pointer' }}>
                                        <p className="font-semibold text-sm" style={{ color: '#0f172a' }}>{cat.nom}</p>
                                        {cat.description && <p className="text-xs truncate" style={{ color: '#94a3b8' }}>{cat.description}</p>}
                                    </div>
                                    <span className="text-xs px-2 py-1 rounded-lg flex-shrink-0 font-medium"
                                        style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #f1f5f9' }}>
                                        {catDishes.length} plat{catDishes.length !== 1 ? 's' : ''}
                                    </span>
                                    <div className="flex items-center gap-1 flex-shrink-0">
                                        <button onClick={() => setDishModal({ open: true, dish: null, categoryId: cat.id })}
                                            className="p-1.5 rounded-lg transition-colors"
                                            style={{ color: '#f97316' }}
                                            onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fff7ed'; }}
                                            onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}>
                                            <Plus size={15} />
                                        </button>
                                        <button onClick={() => setCategoryModal({ open: true, category: cat })}
                                            className="p-1.5 rounded-lg transition-colors"
                                            style={{ color: '#94a3b8' }}
                                            onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#eff6ff'; (e.currentTarget as HTMLButtonElement).style.color = '#2563eb'; }}
                                            onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                                            <Pencil size={14} />
                                        </button>
                                        <button onClick={() => handleDeleteCategory(cat)}
                                            className="p-1.5 rounded-lg transition-colors"
                                            style={{ color: '#94a3b8' }}
                                            onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fef2f2'; (e.currentTarget as HTMLButtonElement).style.color = '#dc2626'; }}
                                            onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                                            <Trash2 size={14} />
                                        </button>
                                    </div>
                                </div>

                                {/* Dishes */}
                                {isExpanded && (
                                    <div>
                                        {catDishes.length === 0 ? (
                                            <p className="text-sm text-center py-5" style={{ color: '#94a3b8' }}>
                                                Aucun plat —{' '}
                                                <button className="font-medium" style={{ color: '#f97316' }}
                                                    onClick={() => setDishModal({ open: true, dish: null, categoryId: cat.id })}>
                                                    Ajouter
                                                </button>
                                            </p>
                                        ) : catDishes.map((dish, dIdx) => {
                                            const isDishOver = dragOverDishId === dish.id && dragDishId !== dish.id;
                                            return (
                                                <div key={dish.id}
                                                    className="flex items-center gap-3 px-4 py-3 transition-colors"
                                                    style={{
                                                        borderTop: dIdx === 0 ? 'none' : '1px solid #f8fafc',
                                                        background: isDishOver ? '#fff7ed' : 'white',
                                                        opacity: dragDishId === dish.id ? 0.4 : (!dish.disponibilite ? 0.6 : 1),
                                                    }}
                                                    draggable
                                                    onDragStart={() => setDragDishId(dish.id)}
                                                    onDragOver={e => { e.preventDefault(); setDragOverDishId(dish.id); }}
                                                    onDragLeave={() => setDragOverDishId(null)}
                                                    onDrop={() => { if (dragDishId !== null) handleDishDrop(dragDishId, dish.id, cat.id); }}
                                                    onDragEnd={() => { setDragDishId(null); setDragOverDishId(null); }}>

                                                    <GripVertical className="h-4 w-4 cursor-grab flex-shrink-0"
                                                        style={{ color: '#cbd5e1' }} />

                                                    {dish.image_url ? (
                                                        <img src={buildImageUrl(dish.image_url)} alt={dish.nom}
                                                            className="w-12 h-12 rounded-xl object-cover flex-shrink-0"
                                                            style={{ border: '1px solid #f1f5f9' }} />
                                                    ) : (
                                                        <div className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0"
                                                            style={{ background: '#f8fafc' }}>
                                                            <UtensilsCrossed className="h-5 w-5" style={{ color: '#cbd5e1' }} />
                                                        </div>
                                                    )}

                                                    <div className="flex-1 min-w-0">
                                                        <div className="flex items-center gap-2">
                                                            <p className="font-semibold text-sm truncate" style={{ color: '#0f172a' }}>{dish.nom}</p>
                                                            {dish.is_plat_du_jour && (
                                                                <span className="text-[10px] px-1.5 py-0.5 rounded-md font-semibold flex-shrink-0"
                                                                    style={{ background: '#fefce8', color: '#a16207', border: '1px solid #fde68a' }}>
                                                                    ★ Plat du jour
                                                                </span>
                                                            )}
                                                        </div>
                                                        <p className="text-sm font-bold" style={{ color: '#f97316' }}>
                                                            {dish.prix?.toLocaleString()} FCFA
                                                        </p>
                                                        {dish.description && (
                                                            <p className="text-xs truncate" style={{ color: '#94a3b8' }}>{dish.description}</p>
                                                        )}
                                                    </div>

                                                    <div className="flex items-center gap-0.5 flex-shrink-0">
                                                        <button onClick={() => handleToggleDishAvailability(dish)}
                                                            className="p-1.5 rounded-lg transition-colors"
                                                            title={dish.disponibilite ? 'Marquer indisponible' : 'Marquer disponible'}
                                                            style={{ color: dish.disponibilite ? '#16a34a' : '#cbd5e1' }}
                                                            onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = dish.disponibilite ? '#f0fdf4' : '#f8fafc'; }}
                                                            onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}>
                                                            {dish.disponibilite ? <ToggleRight size={20} /> : <ToggleLeft size={20} />}
                                                        </button>
                                                        <button onClick={() => handleTogglePlatDuJour(dish)}
                                                            className="p-1.5 rounded-lg transition-colors"
                                                            title="Plat du jour"
                                                            style={{ color: dish.is_plat_du_jour ? '#ca8a04' : '#cbd5e1' }}
                                                            onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#fefce8'; }}
                                                            onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}>
                                                            <Star size={14} />
                                                        </button>
                                                        <button onClick={() => setDishModal({ open: true, dish, categoryId: dish.category_id })}
                                                            className="p-1.5 rounded-lg transition-colors"
                                                            style={{ color: '#94a3b8' }}
                                                            onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#eff6ff'; (e.currentTarget as HTMLButtonElement).style.color = '#2563eb'; }}
                                                            onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; (e.currentTarget as HTMLButtonElement).style.color = '#94a3b8'; }}>
                                                            <Pencil size={14} />
                                                        </button>
                                                        <button onClick={() => handleDeleteDish(dish)}
                                                            className="p-1.5 rounded-lg transition-colors"
                                                            style={{ color: '#94a3b8' }}
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
