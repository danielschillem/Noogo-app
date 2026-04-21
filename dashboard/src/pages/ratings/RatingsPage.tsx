import { useCallback, useEffect, useState } from 'react';
import {
    Star,
    RefreshCw,
    Store,
    MessageSquare,
    User,
    TrendingUp,
} from 'lucide-react';
import { ratingsApi, restaurantsApi } from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import type { Rating, Restaurant } from '../../types';

export default function RatingsPage() {
    useAuth();
    const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
    const [selectedRestaurantId, setSelectedRestaurantId] = useState<string>('');
    const [ratings, setRatings] = useState<Rating[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [page, setPage] = useState(1);
    const [lastPage, setLastPage] = useState(1);

    useEffect(() => {
        restaurantsApi.getAll().then(res => {
            const list: Restaurant[] = res.data.data?.data ?? res.data.data ?? [];
            setRestaurants(list);
            if (list.length > 0) setSelectedRestaurantId(String(list[0].id));
        }).catch(() => { }).finally(() => setIsLoading(false));
    }, []);

    const fetchRatings = useCallback(async () => {
        if (!selectedRestaurantId) return;
        setIsLoading(true);
        try {
            const res = await ratingsApi.getAll(parseInt(selectedRestaurantId), { page, per_page: 20 });
            const data = res.data.data;
            if (data?.data) {
                setRatings(data.data);
                setLastPage(data.last_page ?? 1);
            } else {
                setRatings(Array.isArray(data) ? data : []);
            }
        } catch { setRatings([]); }
        finally { setIsLoading(false); }
    }, [selectedRestaurantId, page]);

    useEffect(() => { fetchRatings(); }, [fetchRatings]);

    const avgRating = ratings.length > 0
        ? (ratings.reduce((sum, r) => sum + r.note, 0) / ratings.length).toFixed(1)
        : '—';

    const distribution = [5, 4, 3, 2, 1].map(n => ({
        stars: n,
        count: ratings.filter(r => r.note === n).length,
        pct: ratings.length > 0 ? Math.round((ratings.filter(r => r.note === n).length / ratings.length) * 100) : 0,
    }));

    const stats = [
        { label: 'Note moyenne', value: avgRating, icon: Star, gradient: 'linear-gradient(135deg,#f59e0b,#d97706)', shadow: 'rgba(245,158,11,0.35)' },
        { label: 'Total avis', value: ratings.length, icon: MessageSquare, gradient: 'linear-gradient(135deg,#3b82f6,#1d4ed8)', shadow: 'rgba(59,130,246,0.35)' },
        { label: '5 étoiles', value: distribution[0].count, icon: TrendingUp, gradient: 'linear-gradient(135deg,#22c55e,#15803d)', shadow: 'rgba(34,197,94,0.35)' },
    ];

    if (isLoading && !selectedRestaurantId) {
        return (
            <div className="flex items-center justify-center h-64">
                <Star className="h-8 w-8 animate-pulse" style={{ color: '#f97316' }} />
                <span className="ml-3 text-sm font-medium" style={{ color: '#64748b' }}>Chargement…</span>
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-fadeIn">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold" style={{ color: '#0f172a' }}>Avis clients</h1>
                    <p className="text-sm mt-0.5" style={{ color: '#64748b' }}>Consultez les avis et notes de vos restaurants</p>
                </div>
                <div className="flex items-center gap-3">
                    {restaurants.length > 1 && (
                        <div className="flex items-center gap-2 px-3 py-2 rounded-xl"
                            style={{ background: 'white', border: '1px solid #e2e8f0' }}>
                            <Store className="h-4 w-4 flex-shrink-0" style={{ color: '#94a3b8' }} />
                            <select value={selectedRestaurantId} onChange={e => { setSelectedRestaurantId(e.target.value); setPage(1); }}
                                className="text-sm bg-transparent border-none outline-none" style={{ color: '#374151' }}>
                                {restaurants.map(r => <option key={r.id} value={r.id}>{r.nom}</option>)}
                            </select>
                        </div>
                    )}
                    <button onClick={fetchRatings} className="p-2.5 rounded-xl"
                        style={{ background: 'white', border: '1px solid #e2e8f0', color: '#64748b' }}>
                        <RefreshCw size={16} />
                    </button>
                </div>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                {stats.map(s => (
                    <div key={s.label} className="rounded-2xl p-5"
                        style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
                        <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-xl flex items-center justify-center"
                                style={{ background: s.gradient, boxShadow: `0 4px 12px ${s.shadow}` }}>
                                <s.icon size={16} className="text-white" />
                            </div>
                            <div>
                                <p className="text-2xl font-black" style={{ color: '#0f172a' }}>{s.value}</p>
                                <p className="text-xs font-semibold uppercase tracking-wide" style={{ color: '#94a3b8' }}>{s.label}</p>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* Distribution */}
            <div className="rounded-2xl p-5" style={{ background: 'white', border: '1px solid #f1f5f9' }}>
                <h3 className="text-sm font-semibold mb-4" style={{ color: '#0f172a' }}>Distribution des notes</h3>
                <div className="space-y-2">
                    {distribution.map(d => (
                        <div key={d.stars} className="flex items-center gap-3">
                            <div className="flex items-center gap-0.5 w-20">
                                {Array.from({ length: d.stars }).map((_, i) => (
                                    <Star key={i} size={12} fill="#f59e0b" stroke="#f59e0b" />
                                ))}
                                {Array.from({ length: 5 - d.stars }).map((_, i) => (
                                    <Star key={i} size={12} fill="none" stroke="#e2e8f0" />
                                ))}
                            </div>
                            <div className="flex-1 h-2.5 rounded-full overflow-hidden" style={{ background: '#f1f5f9' }}>
                                <div className="h-full rounded-full transition-all" style={{ width: `${d.pct}%`, background: '#f59e0b' }} />
                            </div>
                            <span className="text-xs font-medium w-10 text-right" style={{ color: '#64748b' }}>{d.count}</span>
                        </div>
                    ))}
                </div>
            </div>

            {/* Ratings list */}
            {isLoading ? (
                <div className="flex items-center justify-center h-32">
                    <Star className="h-6 w-6 animate-pulse" style={{ color: '#f97316' }} />
                </div>
            ) : ratings.length === 0 ? (
                <div className="text-center py-16 rounded-2xl" style={{ background: 'white', border: '1px solid #f1f5f9' }}>
                    <MessageSquare className="h-12 w-12 mx-auto mb-3" style={{ color: '#cbd5e1' }} />
                    <p className="font-medium" style={{ color: '#374151' }}>Aucun avis pour le moment</p>
                    <p className="text-sm mt-1" style={{ color: '#94a3b8' }}>Les avis clients apparaîtront ici</p>
                </div>
            ) : (
                <div className="space-y-3">
                    {ratings.map(rating => (
                        <div key={rating.id} className="rounded-2xl p-5 transition-shadow hover:shadow-md"
                            style={{ background: 'white', border: '1px solid #f1f5f9', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                            <div className="flex items-start justify-between gap-4">
                                <div className="flex items-start gap-3">
                                    <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
                                        style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                                        <User size={16} className="text-white" />
                                    </div>
                                    <div>
                                        <p className="font-semibold text-sm" style={{ color: '#0f172a' }}>
                                            {rating.user?.name ?? 'Client anonyme'}
                                        </p>
                                        <div className="flex items-center gap-1 mt-0.5">
                                            {Array.from({ length: 5 }).map((_, i) => (
                                                <Star key={i} size={14}
                                                    fill={i < rating.note ? '#f59e0b' : 'none'}
                                                    stroke={i < rating.note ? '#f59e0b' : '#e2e8f0'} />
                                            ))}
                                            <span className="text-xs ml-1 font-medium" style={{ color: '#64748b' }}>
                                                {rating.note}/5
                                            </span>
                                        </div>
                                        {rating.commentaire && (
                                            <p className="text-sm mt-2" style={{ color: '#475569' }}>
                                                {rating.commentaire}
                                            </p>
                                        )}
                                    </div>
                                </div>
                                <div className="text-right shrink-0">
                                    <p className="text-xs" style={{ color: '#94a3b8' }}>
                                        {new Date(rating.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })}
                                    </p>
                                    {rating.order && (
                                        <p className="text-xs mt-0.5" style={{ color: '#cbd5e1' }}>
                                            Cmd #{rating.order.id}
                                        </p>
                                    )}
                                </div>
                            </div>
                        </div>
                    ))}

                    {/* Pagination */}
                    {lastPage > 1 && (
                        <div className="flex items-center justify-center gap-2 pt-4">
                            <button disabled={page <= 1} onClick={() => setPage(p => p - 1)}
                                className="px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-40"
                                style={{ background: 'white', border: '1px solid #e2e8f0', color: '#374151' }}>
                                Précédent
                            </button>
                            <span className="text-sm" style={{ color: '#64748b' }}>
                                Page {page} / {lastPage}
                            </span>
                            <button disabled={page >= lastPage} onClick={() => setPage(p => p + 1)}
                                className="px-4 py-2 rounded-lg text-sm font-medium disabled:opacity-40"
                                style={{ background: 'white', border: '1px solid #e2e8f0', color: '#374151' }}>
                                Suivant
                            </button>
                        </div>
                    )}
                </div>
            )}
        </div>
    );
}
