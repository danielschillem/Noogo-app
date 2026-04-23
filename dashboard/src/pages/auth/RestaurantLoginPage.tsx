import { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { portalApi } from '../../services/api';
import { Mail, Lock, Loader2, Store, ArrowRight, AlertTriangle } from 'lucide-react';
import type { Restaurant } from '../../types';

export default function RestaurantLoginPage() {
    const { restaurantId } = useParams<{ restaurantId: string }>();
    const id = Number(restaurantId);
    const [restaurant, setRestaurant] = useState<Restaurant | null>(null);
    const [loadingResto, setLoadingResto] = useState(true);
    const [notFound, setNotFound] = useState(false);

    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPw, setShowPw] = useState(false);
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);

    const { loginForRestaurant, isAuthenticated, lockedRestaurantId } = useAuth();
    const navigate = useNavigate();

    // Charger les infos du restaurant (sans auth — endpoint public)
    useEffect(() => {
        if (!id || isNaN(id)) { setNotFound(true); setLoadingResto(false); return; }
        portalApi.getRestaurant(id)
            .then(r => { setRestaurant(r.data.data ?? r.data); setLoadingResto(false); })
            .catch(() => { setNotFound(true); setLoadingResto(false); });
    }, [id]);

    // Si déjà connecté et verrouillé sur ce restaurant → rediriger
    useEffect(() => {
        if (isAuthenticated && lockedRestaurantId === id) {
            navigate(`/r/${id}/orders`, { replace: true });
        }
    }, [isAuthenticated, lockedRestaurantId, id, navigate]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);
        try {
            await loginForRestaurant(email, password, id);
            navigate(`/r/${id}/orders`, { replace: true });
        } catch (err: unknown) {
            const e = err as { message?: string; response?: { data?: { message?: string } }; code?: string };
            if (e.code === 'ECONNABORTED' || (!e.response && !e.message?.includes('accès'))) {
                setError('Le serveur met du temps à répondre. Réessayez dans quelques secondes.');
            } else {
                setError(e.message || e.response?.data?.message || 'Identifiants invalides');
            }
        } finally {
            setIsLoading(false);
        }
    };

    if (loadingResto) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500" />
            </div>
        );
    }

    if (notFound || !restaurant) {
        return (
            <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 text-center p-6">
                <div className="w-16 h-16 rounded-2xl flex items-center justify-center mb-4"
                    style={{ background: '#fee2e2' }}>
                    <Store className="h-8 w-8" style={{ color: '#dc2626' }} />
                </div>
                <h1 className="text-xl font-bold mb-2" style={{ color: '#0f172a' }}>Restaurant introuvable</h1>
                <p className="text-sm" style={{ color: '#64748b' }}>
                    Ce lien n'est plus valide ou le restaurant n'existe pas.
                </p>
            </div>
        );
    }

    const logoUrl = restaurant.logo_url || restaurant.logo;

    return (
        <div className="min-h-screen flex" style={{ background: '#f1f5f9' }}>

            {/* Left panel — restaurant branding */}
            <div className="hidden lg:flex lg:w-[48%] relative overflow-hidden flex-col justify-between p-12"
                style={{ background: 'linear-gradient(145deg, #0f172a 0%, #1e1b4b 50%, #0f172a 100%)' }}>

                {/* Blobs décoratifs */}
                <div className="absolute top-0 left-0 w-96 h-96 rounded-full opacity-20 blur-3xl"
                    style={{ background: 'radial-gradient(circle,#f97316,transparent)', transform: 'translate(-30%,-30%)' }} />
                <div className="absolute bottom-0 right-0 w-80 h-80 rounded-full opacity-15 blur-3xl"
                    style={{ background: 'radial-gradient(circle,#8b5cf6,transparent)', transform: 'translate(30%,30%)' }} />

                {/* Logo Noogo */}
                <div className="flex items-center gap-3 relative">
                    <img src="/noogo-logo.png" alt="Noogo" className="h-16 w-auto" />
                </div>

                {/* Restaurant card */}
                <div className="relative space-y-6">
                    <div className="flex items-center gap-4">
                        {logoUrl ? (
                            <img src={logoUrl} alt={restaurant.nom}
                                className="w-16 h-16 rounded-2xl object-cover border-2"
                                style={{ borderColor: 'rgba(255,255,255,0.15)' }} />
                        ) : (
                            <div className="w-16 h-16 rounded-2xl flex items-center justify-center"
                                style={{ background: 'rgba(249,115,22,0.15)', border: '2px solid rgba(249,115,22,0.25)' }}>
                                <Store className="h-8 w-8" style={{ color: '#f97316' }} />
                            </div>
                        )}
                        <div>
                            <p className="text-xs font-semibold uppercase tracking-widest mb-1"
                                style={{ color: '#f97316' }}>Espace personnel</p>
                            <h2 className="text-2xl font-black text-white leading-tight">{restaurant.nom}</h2>
                        </div>
                    </div>
                    <p className="text-sm leading-relaxed" style={{ color: '#94a3b8' }}>
                        Connectez-vous avec vos identifiants pour accéder à l'espace de gestion de{' '}
                        <span className="font-semibold" style={{ color: '#e2e8f0' }}>{restaurant.nom}</span>.
                    </p>
                    <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold"
                        style={{
                            background: restaurant.is_active ? 'rgba(34,197,94,0.12)' : 'rgba(100,116,139,0.12)',
                            color: restaurant.is_active ? '#22c55e' : '#94a3b8',
                            border: `1px solid ${restaurant.is_active ? 'rgba(34,197,94,0.2)' : 'rgba(100,116,139,0.2)'}`,
                        }}>
                        <span className="w-1.5 h-1.5 rounded-full"
                            style={{ background: restaurant.is_active ? '#22c55e' : '#94a3b8' }} />
                        {restaurant.is_active ? 'Restaurant actif' : 'Restaurant inactif'}
                    </div>
                </div>

                <p className="text-xs relative" style={{ color: '#475569' }}>
                    © 2026 Noogo — Tous droits réservés
                </p>
            </div>

            {/* Right panel — form */}
            <div className="flex-1 flex items-center justify-center p-6">
                <div className="w-full max-w-sm animate-fadeIn">

                    {/* Mobile header */}
                    <div className="flex items-center gap-3 mb-8 lg:hidden">
                        {logoUrl ? (
                            <img src={logoUrl} alt={restaurant.nom}
                                className="w-10 h-10 rounded-xl object-cover" />
                        ) : (
                            <div className="w-10 h-10 rounded-xl flex items-center justify-center"
                                style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
                                <Store className="h-5 w-5 text-white" />
                            </div>
                        )}
                        <div>
                            <p className="text-xs font-semibold" style={{ color: '#f97316' }}>Noogo</p>
                            <p className="font-bold text-sm" style={{ color: '#0f172a' }}>{restaurant.nom}</p>
                        </div>
                    </div>

                    <div className="mb-8">
                        <h2 className="text-2xl font-bold mb-1.5" style={{ color: '#0f172a' }}>Connexion</h2>
                        <p className="text-sm" style={{ color: '#64748b' }}>
                            Accès réservé au personnel de{' '}
                            <span className="font-semibold" style={{ color: '#0f172a' }}>{restaurant.nom}</span>
                        </p>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-5">
                        {error && (
                            <div className="flex items-start gap-3 px-4 py-3 rounded-xl text-sm"
                                style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                                <AlertTriangle className="h-4 w-4 mt-0.5 flex-shrink-0" />
                                <span>{error}</span>
                            </div>
                        )}

                        {/* Email */}
                        <div>
                            <label className="block text-sm font-medium mb-1.5" style={{ color: '#374151' }}>
                                Adresse email
                            </label>
                            <div className="relative">
                                <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4"
                                    style={{ color: '#9ca3af' }} />
                                <input
                                    type="email" value={email} onChange={e => setEmail(e.target.value)}
                                    required placeholder="votre@email.com"
                                    className="w-full pl-10 pr-4 py-2.5 rounded-xl border text-sm transition-colors outline-none"
                                    style={{
                                        background: '#fff', borderColor: '#e5e7eb', color: '#0f172a',
                                        boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
                                    }}
                                    onFocus={e => { e.currentTarget.style.borderColor = '#f97316'; e.currentTarget.style.boxShadow = '0 0 0 3px rgba(249,115,22,0.1)'; }}
                                    onBlur={e => { e.currentTarget.style.borderColor = '#e5e7eb'; e.currentTarget.style.boxShadow = '0 1px 2px rgba(0,0,0,0.05)'; }}
                                />
                            </div>
                        </div>

                        {/* Password */}
                        <div>
                            <label className="block text-sm font-medium mb-1.5" style={{ color: '#374151' }}>
                                Mot de passe
                            </label>
                            <div className="relative">
                                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4"
                                    style={{ color: '#9ca3af' }} />
                                <input
                                    type={showPw ? 'text' : 'password'} value={password}
                                    onChange={e => setPassword(e.target.value)}
                                    required placeholder="••••••••"
                                    className="w-full pl-10 pr-12 py-2.5 rounded-xl border text-sm transition-colors outline-none"
                                    style={{
                                        background: '#fff', borderColor: '#e5e7eb', color: '#0f172a',
                                        boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
                                    }}
                                    onFocus={e => { e.currentTarget.style.borderColor = '#f97316'; e.currentTarget.style.boxShadow = '0 0 0 3px rgba(249,115,22,0.1)'; }}
                                    onBlur={e => { e.currentTarget.style.borderColor = '#e5e7eb'; e.currentTarget.style.boxShadow = '0 1px 2px rgba(0,0,0,0.05)'; }}
                                />
                                <button type="button" onClick={() => setShowPw(v => !v)}
                                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-xs font-medium"
                                    style={{ color: '#6b7280' }}>
                                    {showPw ? 'Masquer' : 'Afficher'}
                                </button>
                            </div>
                        </div>

                        <button
                            type="submit" disabled={isLoading}
                            className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-semibold transition-all"
                            style={{
                                background: isLoading ? '#fed7aa' : 'linear-gradient(135deg,#f97316,#ea580c)',
                                color: 'white',
                                boxShadow: isLoading ? 'none' : '0 4px 14px rgba(249,115,22,0.4)',
                            }}>
                            {isLoading ? (
                                <><Loader2 className="h-4 w-4 animate-spin" /> Connexion…</>
                            ) : (
                                <>Se connecter <ArrowRight className="h-4 w-4" /></>
                            )}
                        </button>
                    </form>

                    <p className="text-center text-xs mt-6" style={{ color: '#9ca3af' }}>
                        Accès restreint — personnel autorisé uniquement
                    </p>
                </div>
            </div>
        </div>
    );
}
