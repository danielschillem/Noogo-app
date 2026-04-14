import { useEffect, useState } from 'react';
import {
    Plus,
    Pencil,
    Trash2,
    ChevronDown,
    ChevronRight,
    ToggleLeft,
    ToggleRight,
    Star,
    UtensilsCrossed,
    X,
    GripVertical,
} from 'lucide-react';
import { categoriesApi, dishesApi, restaurantsApi } from '../../services/api';
import type { Category, Dish, Restaurant } from '../../types';

// ─── Helpers ───────────────────────────────────────────────────────────────

function buildImageUrl(path?: string | null): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = (import.meta.env.VITE_IMAGE_BASE_URL || '').replace(/\/$/, '');
    const clean = path.replace(/^\//, '');
    return `${base}/storage/${clean}`;
}

// ─── Category Form Modal ────────────────────────────────────────────────────

function CategoryModal({
    restaurantId,
    category,
    onClose,
    onSaved,
}: {
    restaurantId: number;
    category: Category | null;
    onClose: () => void;
    onSaved: () => void;
}) {
    const [nom, setNom] = useState(category?.nom ?? '');
    const [description, setDescription] = useState(category?.description ?? '');
    const [image, setImage] = useState<File | null>(null);
    const [isSaving, setIsSaving] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!nom.trim()) { setError('Le nom est requis'); return; }
        setIsSaving(true);
        setError('');
        try {
            const fd = new FormData();
            fd.append('nom', nom.trim());
            if (description) fd.append('description', description);
            if (image) fd.append('image', image);
            if (category) {
                await categoriesApi.update(restaurantId, category.id, fd);
            } else {
                await categoriesApi.create(restaurantId, fd);
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
            <div className="bg-white rounded-xl w-full max-w-md shadow-xl">
                <div className="flex items-center justify-between p-6 border-b">
                    <h2 className="text-lg font-semibold">{category ? 'Modifier la catégorie' : 'Nouvelle catégorie'}</h2>
                    <button onClick={onClose}><X className="h-5 w-5 text-gray-400" /></button>
                </div>
                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {error && <p className="text-sm text-red-600 bg-red-50 px-3 py-2 rounded-lg">{error}</p>}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Nom *</label>
                        <input
                            value={nom}
                            onChange={e => setNom(e.target.value)}
                            className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                            placeholder="Ex: Entrées"
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                        <textarea
                            value={description}
                            onChange={e => setDescription(e.target.value)}
                            rows={2}
                            className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent resize-none"
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Image</label>
                        <input
                            type="file"
                            accept="image/*"
                            onChange={e => setImage(e.target.files?.[0] ?? null)}
                            className="w-full text-sm text-gray-600"
                        />
                    </div>
                    <div className="flex gap-3 pt-2">
                        <button type="button" onClick={onClose} className="flex-1 px-4 py-2 border border-gray-200 rounded-lg text-gray-600 hover:bg-gray-50">Annuler</button>
                        <button
                            type="submit"
                            disabled={isSaving}
                            className="flex-1 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 disabled:opacity-50"
                        >
                            {isSaving ? 'Sauvegarde...' : 'Sauvegarder'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}

// ─── Dish Form Modal ────────────────────────────────────────────────────────

function DishModal({
    restaurantId,
    categories,
    dish,
    defaultCategoryId,
    onClose,
    onSaved,
}: {
    restaurantId: number;
    categories: Category[];
    dish: Dish | null;
    defaultCategoryId?: number;
    onClose: () => void;
    onSaved: () => void;
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
        setIsSaving(true);
        setError('');
        try {
            const fd = new FormData();
            fd.append('nom', nom.trim());
            fd.append('prix', prix);
            fd.append('category_id', categoryId.toString());
            fd.append('temps_preparation', tempsPrep || '15');
            if (description) fd.append('description', description);
            if (image) fd.append('image', image);
            if (dish) {
                await dishesApi.update(restaurantId, dish.id, fd);
            } else {
                await dishesApi.create(restaurantId, fd);
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
                    <h2 className="text-lg font-semibold">{dish ? 'Modifier le plat' : 'Nouveau plat'}</h2>
                    <button onClick={onClose}><X className="h-5 w-5 text-gray-400" /></button>
                </div>
                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {error && <p className="text-sm text-red-600 bg-red-50 px-3 py-2 rounded-lg">{error}</p>}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Nom *</label>
                        <input value={nom} onChange={e => setNom(e.target.value)}
                            className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500" placeholder="Ex: Riz gras" />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Prix (FCFA) *</label>
                            <input type="number" value={prix} onChange={e => setPrix(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500" placeholder="1500" min="0" />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Temps préparation (min)</label>
                            <input type="number" value={tempsPrep} onChange={e => setTempsPrep(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500" placeholder="15" min="1" />
                        </div>
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Catégorie *</label>
                        <select value={categoryId} onChange={e => setCategoryId(Number(e.target.value))}
                            className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500">
                            {categories.map(c => <option key={c.id} value={c.id}>{c.nom}</option>)}
                        </select>
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                        <textarea value={description} onChange={e => setDescription(e.target.value)}
                            rows={3} className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-orange-500 resize-none" />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Image</label>
                        <input type="file" accept="image/*" onChange={e => setImage(e.target.files?.[0] ?? null)} className="w-full text-sm text-gray-600" />
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

    // Drag-and-drop state
    const [dragCatIdx, setDragCatIdx] = useState<number | null>(null);
    const [dragOverCatIdx, setDragOverCatIdx] = useState<number | null>(null);
    const [dragDishId, setDragDishId] = useState<number | null>(null);
    const [dragOverDishId, setDragOverDishId] = useState<number | null>(null);

    // Load restaurants
    useEffect(() => {
        restaurantsApi.getAll().then(r => {
            const list: Restaurant[] = r.data.data.data || r.data.data;
            setRestaurants(list);
            if (list.length > 0) setSelectedRestaurantId(list[0].id);
        }).catch(console.error);
    }, []);

    // Load menu when restaurant changes
    useEffect(() => {
        if (!selectedRestaurantId) return;
        setIsLoading(true);
        Promise.all([
            categoriesApi.getAll(selectedRestaurantId),
            dishesApi.getAll(selectedRestaurantId),
        ]).then(([catRes, dishRes]) => {
            const cats: Category[] = catRes.data.data || catRes.data;
            const dis: Dish[] = dishRes.data.data || dishRes.data;
            setCategories(cats);
            setDishes(dis);
            setExpandedCategories(new Set(cats.map(c => c.id)));
        }).catch(console.error)
            .finally(() => setIsLoading(false));
    }, [selectedRestaurantId]);

    const reload = () => {
        if (!selectedRestaurantId) return;
        Promise.all([
            categoriesApi.getAll(selectedRestaurantId),
            dishesApi.getAll(selectedRestaurantId),
        ]).then(([catRes, dishRes]) => {
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

    const dishesInCategory = (categoryId: number) =>
        dishes.filter(d => d.category_id === categoryId);

    // ── Drag-and-drop handlers ───────────────────────────────────────────────
    const handleCatDrop = (overIdx: number) => {
        if (dragCatIdx === null || dragCatIdx === overIdx) {
            setDragCatIdx(null);
            setDragOverCatIdx(null);
            return;
        }
        const reordered = [...categories];
        const [item] = reordered.splice(dragCatIdx, 1);
        reordered.splice(overIdx, 0, item);
        setCategories(reordered);
        setDragCatIdx(null);
        setDragOverCatIdx(null);
        if (selectedRestaurantId) {
            categoriesApi
                .reorder(selectedRestaurantId, reordered.map((c, i) => ({ id: c.id, ordre: i })))
                .catch(console.error);
        }
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
        setDragDishId(null);
        setDragOverDishId(null);
        if (selectedRestaurantId) {
            dishesApi
                .reorder(selectedRestaurantId, reordered.map((d, i) => ({ id: d.id, ordre: i })))
                .catch(console.error);
        }
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Menu</h1>
                    <p className="text-gray-600">Gérez les catégories et les plats</p>
                </div>
                <div className="flex items-center gap-3">
                    {/* Restaurant selector */}
                    <select
                        value={selectedRestaurantId ?? ''}
                        onChange={e => setSelectedRestaurantId(Number(e.target.value))}
                        className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-orange-500"
                    >
                        {restaurants.map(r => <option key={r.id} value={r.id}>{r.nom}</option>)}
                    </select>
                    <button
                        onClick={() => setCategoryModal({ open: true, category: null })}
                        className="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 text-sm"
                    >
                        <Plus className="h-4 w-4" /> Catégorie
                    </button>
                </div>
            </div>

            {isLoading ? (
                <div className="flex justify-center py-16">
                    <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-orange-500" />
                </div>
            ) : categories.length === 0 ? (
                <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
                    <UtensilsCrossed className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">Aucune catégorie</h3>
                    <p className="text-gray-500 mb-4">Créez votre première catégorie pour commencer</p>
                    <button
                        onClick={() => setCategoryModal({ open: true, category: null })}
                        className="inline-flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600"
                    >
                        <Plus className="h-4 w-4" /> Ajouter une catégorie
                    </button>
                </div>
            ) : (
                <div className="space-y-4">
                    {categories.map((cat, catIdx) => {
                        const catDishes = dishesInCategory(cat.id);
                        const isExpanded = expandedCategories.has(cat.id);
                        return (
                            <div
                                key={cat.id}
                                className={`bg-white rounded-xl border overflow-hidden transition-all duration-150 ${dragOverCatIdx === catIdx && dragCatIdx !== catIdx
                                        ? 'border-orange-400 shadow-md'
                                        : 'border-gray-200'
                                    }`}
                                draggable
                                onDragStart={() => setDragCatIdx(catIdx)}
                                onDragOver={e => { e.preventDefault(); setDragOverCatIdx(catIdx); }}
                                onDragLeave={() => setDragOverCatIdx(null)}
                                onDrop={() => handleCatDrop(catIdx)}
                                onDragEnd={() => { setDragCatIdx(null); setDragOverCatIdx(null); }}
                            >
                                {/* Category header */}
                                <div className="flex items-center gap-3 p-4">
                                    <span
                                        className="cursor-grab text-gray-300 hover:text-gray-500 flex-shrink-0"
                                        title="Glisser pour réorganiser"
                                        onMouseDown={e => e.stopPropagation()}
                                    >
                                        <GripVertical className="h-5 w-5" />
                                    </span>
                                    <button onClick={() => toggleCategory(cat.id)} className="text-gray-400">
                                        {isExpanded ? <ChevronDown className="h-5 w-5" /> : <ChevronRight className="h-5 w-5" />}
                                    </button>
                                    {cat.image_url && (
                                        <img src={buildImageUrl(cat.image_url)} alt={cat.nom}
                                            className="w-10 h-10 rounded-lg object-cover border border-gray-100" />
                                    )}
                                    <div className="flex-1 min-w-0">
                                        <h3 className="font-semibold text-gray-900">{cat.nom}</h3>
                                        {cat.description && <p className="text-xs text-gray-500 truncate">{cat.description}</p>}
                                    </div>
                                    <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-full">
                                        {catDishes.length} plat{catDishes.length !== 1 ? 's' : ''}
                                    </span>
                                    <div className="flex items-center gap-1">
                                        <button
                                            onClick={() => setDishModal({ open: true, dish: null, categoryId: cat.id })}
                                            title="Ajouter un plat"
                                            className="p-2 text-orange-500 hover:bg-orange-50 rounded-lg"
                                        >
                                            <Plus className="h-4 w-4" />
                                        </button>
                                        <button
                                            onClick={() => setCategoryModal({ open: true, category: cat })}
                                            title="Modifier la catégorie"
                                            className="p-2 text-gray-400 hover:bg-gray-50 rounded-lg"
                                        >
                                            <Pencil className="h-4 w-4" />
                                        </button>
                                        <button
                                            onClick={() => handleDeleteCategory(cat)}
                                            title="Supprimer la catégorie"
                                            className="p-2 text-red-400 hover:bg-red-50 rounded-lg"
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </button>
                                    </div>
                                </div>

                                {/* Dishes list */}
                                {isExpanded && (
                                    <div className="border-t border-gray-100 divide-y divide-gray-50">
                                        {catDishes.length === 0 ? (
                                            <p className="text-sm text-gray-400 text-center py-4">
                                                Aucun plat — <button
                                                    onClick={() => setDishModal({ open: true, dish: null, categoryId: cat.id })}
                                                    className="text-orange-500 hover:underline"
                                                >Ajouter</button>
                                            </p>
                                        ) : catDishes.map(dish => (
                                            <div
                                                key={dish.id}
                                                className={`flex items-center gap-3 px-4 py-3 transition-colors duration-100 ${dragOverDishId === dish.id && dragDishId !== dish.id
                                                        ? 'bg-orange-50'
                                                        : ''
                                                    }`}
                                                draggable
                                                onDragStart={() => setDragDishId(dish.id)}
                                                onDragOver={e => { e.preventDefault(); setDragOverDishId(dish.id); }}
                                                onDragLeave={() => setDragOverDishId(null)}
                                                onDrop={() => { if (dragDishId !== null) handleDishDrop(dragDishId, dish.id, cat.id); }}
                                                onDragEnd={() => { setDragDishId(null); setDragOverDishId(null); }}
                                            >
                                                <span
                                                    className="cursor-grab text-gray-300 hover:text-gray-500 flex-shrink-0"
                                                    title="Glisser pour réorganiser"
                                                >
                                                    <GripVertical className="h-4 w-4" />
                                                </span>
                                                {dish.image_url ? (
                                                    <img src={buildImageUrl(dish.image_url)} alt={dish.nom}
                                                        className="w-12 h-12 rounded-lg object-cover border border-gray-100 flex-shrink-0" />
                                                ) : (
                                                    <div className="w-12 h-12 rounded-lg bg-gray-100 flex items-center justify-center flex-shrink-0">
                                                        <UtensilsCrossed className="h-5 w-5 text-gray-300" />
                                                    </div>
                                                )}
                                                <div className="flex-1 min-w-0">
                                                    <div className="flex items-center gap-2">
                                                        <p className="font-medium text-gray-900 text-sm truncate">{dish.nom}</p>
                                                        {dish.is_plat_du_jour && (
                                                            <span className="text-xs bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded-full flex-shrink-0">
                                                                Plat du jour
                                                            </span>
                                                        )}
                                                    </div>
                                                    <p className="text-sm font-semibold text-orange-500">{dish.prix?.toLocaleString()} FCFA</p>
                                                    {dish.description && (
                                                        <p className="text-xs text-gray-400 truncate">{dish.description}</p>
                                                    )}
                                                </div>
                                                <div className="flex items-center gap-1 flex-shrink-0">
                                                    {/* Disponibilité */}
                                                    <button
                                                        onClick={() => handleToggleDishAvailability(dish)}
                                                        title={dish.disponibilite ? 'Marquer indisponible' : 'Marquer disponible'}
                                                        className={`p-2 rounded-lg ${dish.disponibilite ? 'text-green-500 hover:bg-green-50' : 'text-gray-300 hover:bg-gray-50'}`}
                                                    >
                                                        {dish.disponibilite ? <ToggleRight className="h-5 w-5" /> : <ToggleLeft className="h-5 w-5" />}
                                                    </button>
                                                    {/* Plat du jour */}
                                                    <button
                                                        onClick={() => handleTogglePlatDuJour(dish)}
                                                        title="Plat du jour"
                                                        className={`p-2 rounded-lg ${dish.is_plat_du_jour ? 'text-yellow-500 hover:bg-yellow-50' : 'text-gray-300 hover:bg-gray-50'}`}
                                                    >
                                                        <Star className="h-4 w-4" />
                                                    </button>
                                                    <button onClick={() => setDishModal({ open: true, dish, categoryId: dish.category_id })}
                                                        className="p-2 text-gray-400 hover:bg-gray-50 rounded-lg">
                                                        <Pencil className="h-4 w-4" />
                                                    </button>
                                                    <button onClick={() => handleDeleteDish(dish)}
                                                        className="p-2 text-red-400 hover:bg-red-50 rounded-lg">
                                                        <Trash2 className="h-4 w-4" />
                                                    </button>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}

            {/* Modals */}
            {categoryModal.open && selectedRestaurantId && (
                <CategoryModal
                    restaurantId={selectedRestaurantId}
                    category={categoryModal.category}
                    onClose={() => setCategoryModal({ open: false, category: null })}
                    onSaved={reload}
                />
            )}
            {dishModal.open && selectedRestaurantId && (
                <DishModal
                    restaurantId={selectedRestaurantId}
                    categories={categories}
                    dish={dishModal.dish}
                    defaultCategoryId={dishModal.categoryId}
                    onClose={() => setDishModal({ open: false, dish: null })}
                    onSaved={reload}
                />
            )}
        </div>
    );
}
