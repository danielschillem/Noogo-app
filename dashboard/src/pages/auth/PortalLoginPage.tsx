import { useState, useEffect, type CSSProperties } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { portalApi } from '../../services/api';
import {
    Store, Lock, Mail, Loader2, ChevronDown, Search, AlertTriangle,
} from 'lucide-react';

interface PortalRestaurant {
    id: number;
    nom: string;
    logo: string | null;
    adresse: string;
}

function buildLogoUrl(path?: string | null): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = (import.meta.env.VITE_IMAGE_BASE_URL || '').replace(/\/$/, '');
    return `${base}/storage/${path.replace(/^\//, '')}`;
}

export default function PortalLoginPage() {
    const navigate = useNavigate();
    const { login, loginForRestaurant, isAuthenticated, lockedRestaurantId } = useAuth();

    const [restaurants, setRestaurants] = useState<PortalRestaurant[]>([]);
    const [loadingList, setLoadingList] = useState(true);
    const [search, setSearch] = useState('');
    const [dropdownOpen, setDropdownOpen] = useState(false);
    const [selected, setSelected] = useState<PortalRestaurant | null>(null);

    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPw, setShowPw] = useState(false);
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);

    // Si déjà connecté et verrouillé → rediriger
    useEffect(() => {
        if (isAuthenticated && lockedRestaurantId) {
            navigate(`/r/${lockedRestaurantId}/orders`, { replace: true });
        }
    }, [isAuthenticated, lockedRestaurantId, navigate]);

    // Charger la liste des restaurants
    useEffect(() => {
        portalApi.listRestaurants()
            .then(r => setRestaurants(r.data.data ?? []))
            .catch(() => setRestaurants([]))
            .finally(() => setLoadingList(false));
    }, []);

    const filtered = restaurants.filter(r =>
        r.nom.toLowerCase().includes(search.toLowerCase()) ||
        r.adresse.toLowerCase().includes(search.toLowerCase()),
    );

    const handleSelect = (r: PortalRestaurant) => {
        setSelected(r);
        setDropdownOpen(false);
        setSearch('');
        setError('');
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);
        try {
            if (selected) {
                // Connexion admin restaurant
                await loginForRestaurant(email, password, selected.id);
                navigate(`/r/${selected.id}/orders`, { replace: true });
            } else {
                // Connexion super admin (sans restaurant)
                await login(email, password);
                navigate('/', { replace: true });
            }
        } catch (err: unknown) {
            const e = err as { message?: string; response?: { data?: { message?: string } }; code?: string };
            if (e.code === 'ECONNABORTED' || (!e.response && !e.message?.includes('accès'))) {
                setError('Le serveur met du temps à répondre. Réessayez dans quelques secondes.');
            } else {
                setError(e.message || e.response?.data?.message || 'Identifiants invalides.');
            }
        } finally {
            setIsLoading(false);
        }
    };

    const logoUrl = selected ? buildLogoUrl(selected.logo) : null;

    const pageBg: CSSProperties = {
        backgroundImage: "url('/portal-bg.jpg')",
        backgroundSize: 'cover',
        backgroundPosition: 'center',
        backgroundAttachment: 'fixed',
    };

    return (
        <div className="min-h-screen flex relative" style={pageBg}>
            {/* Lisibilité : bandeau sombre à gauche (desktop), voile clair sur mobile */}
            <div
                className="pointer-events-none absolute inset-0 z-0 hidden lg:block"
                style={{
                    background:
                        'linear-gradient(105deg, rgba(15,23,42,0.88) 0%, rgba(15,23,42,0.78) 46%, rgba(241,245,249,0.9) 46%, rgba(241,245,249,0.94) 100%)',
                }}
                aria-hidden
            />
            <div
                className="pointer-events-none absolute inset-0 z-0 lg:hidden"
                style={{ background: 'rgba(248,250,252,0.88)' }}
                aria-hidden
            />

            {/* Left panel */}
            <div
                className="hidden lg:flex lg:w-[48%] relative overflow-hidden flex-col justify-between p-12 z-10"
                style={{ background: 'transparent' }}
            >
                <div className="absolute top-0 left-0 w-96 h-96 rounded-full opacity-15 blur-3xl"
                    style={{ background: 'radial-gradient(circle,#f97316,transparent)', transform: 'translate(-30%,-30%)' }} />
                <div className="absolute bottom-0 right-0 w-80 h-80 rounded-full opacity-10 blur-3xl"
                    style={{ background: 'radial-gradient(circle,#8b5cf6,transparent)', transform: 'translate(30%,30%)' }} />

                <div className="relative flex items-center gap-3">
                    <img src="/noogo-logo.png" alt="Noogo" className="h-16 w-auto" />
                </div>

                <div className="relative space-y-6">
                    <div className="flex items-center gap-4">
                        {logoUrl ? (
                            <img src={logoUrl} alt={selected!.nom}
                                className="w-16 h-16 rounded-2xl object-cover border-2"
                                style={{ borderColor: 'rgba(255,255,255,0.15)' }} />
                        ) : (
                            <div className="w-16 h-16 rounded-2xl flex items-center justify-center"
                                style={{ background: 'rgba(249,115,22,0.15)', border: '2px solid rgba(249,115,22,0.25)' }}>
                                <Store className="h-8 w-8" style={{ color: '#f97316' }} />
                            </div>
                        )}
                        <div>
                            <p className="text-xs font-semibold uppercase tracking-widest mb-1" style={{ color: '#f97316' }}>
                                Espace restaurant
                            </p>
                            <h2 className="text-2xl font-black text-white leading-tight">
                                {selected ? selected.nom : 'Sélectionnez votre restaurant'}
                            </h2>
                        </div>
                    </div>
                    {selected && (
                        <p className="text-sm leading-relaxed" style={{ color: '#94a3b8' }}>
                            {selected.adresse}
                        </p>
                    )}
                    <p className="text-sm leading-relaxed" style={{ color: '#475569' }}>
                        Connectez-vous avec vos identifiants pour accéder à votre espace de gestion.
                    </p>
                </div>
            </div>

            {/* Right panel — form */}
            <div className="flex-1 flex items-center justify-center p-6 lg:p-12 relative z-10">
                <div
                    className="w-full max-w-md space-y-6 rounded-2xl p-6 sm:p-8 shadow-xl border"
                    style={{
                        background: 'rgba(255,255,255,0.92)',
                        borderColor: 'rgba(226,232,240,0.9)',
                        backdropFilter: 'blur(10px)',
                    }}
                >

                    {/* Mobile logo */}
                    <div className="lg:hidden flex justify-center mb-2">
                        <img src="/noogo-logo.png" alt="Noogo" className="h-12 w-auto" />
                    </div>

                    <div>
                        <h1 className="text-2xl font-black" style={{ color: '#0f172a' }}>Espace Restaurant</h1>
                        <p className="mt-1 text-sm" style={{ color: '#64748b' }}>
                            Sélectionnez votre restaurant puis connectez-vous.
                        </p>
                    </div>

                    {error && (
                        <div className="flex items-start gap-3 p-3 rounded-xl text-sm"
                            style={{ background: '#fef2f2', border: '1px solid #fecaca', color: '#dc2626' }}>
                            <AlertTriangle className="h-4 w-4 mt-0.5 shrink-0" />
                            <span>{error}</span>
                        </div>
                    )}

                    <form onSubmit={handleSubmit} className="space-y-4">

                        {/* Restaurant selector */}
                        <div className="relative">
                            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5"
                                style={{ color: '#64748b' }}>
                                Restaurant
                            </label>
                            <button
                                type="button"
                                onClick={() => setDropdownOpen(o => !o)}
                                className="w-full flex items-center gap-3 px-4 py-3 rounded-xl border text-left transition-all"
                                style={{
                                    background: '#fff',
                                    border: dropdownOpen ? '2px solid #f97316' : '1.5px solid #e2e8f0',
                                    color: selected ? '#0f172a' : '#94a3b8',
                                    boxShadow: dropdownOpen ? '0 0 0 3px rgba(249,115,22,0.1)' : 'none',
                                }}
                            >
                                {selected?.logo ? (
                                    <img src={buildLogoUrl(selected.logo)} alt="" className="w-7 h-7 rounded-lg object-cover shrink-0" />
                                ) : (
                                    <div className="w-7 h-7 rounded-lg flex items-center justify-center shrink-0"
                                        style={{ background: '#fff7ed' }}>
                                        <Store className="h-4 w-4" style={{ color: '#f97316' }} />
                                    </div>
                                )}
                                <span className="flex-1 text-sm font-medium truncate">
                                    {selected ? selected.nom : 'Choisir un restaurant…'}
                                </span>
                                <ChevronDown
                                    className="h-4 w-4 shrink-0 transition-transform"
                                    style={{ color: '#94a3b8', transform: dropdownOpen ? 'rotate(180deg)' : 'none' }}
                                />
                            </button>

                            {/* Dropdown */}
                            {dropdownOpen && (
                                <div
                                    className="absolute z-50 w-full mt-1 rounded-xl border overflow-hidden"
                                    style={{ background: '#fff', border: '1.5px solid #e2e8f0', boxShadow: '0 10px 40px rgba(0,0,0,0.12)' }}
                                >
                                    {/* Search */}
                                    <div className="p-2 border-b" style={{ borderColor: '#f1f5f9' }}>
                                        <div className="relative">
                                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5" style={{ color: '#94a3b8' }} />
                                            <input
                                                type="text"
                                                value={search}
                                                onChange={e => setSearch(e.target.value)}
                                                placeholder="Rechercher…"
                                                className="w-full pl-8 pr-3 py-1.5 text-sm rounded-lg outline-none"
                                                style={{ background: '#f8fafc', border: '1px solid #e2e8f0', color: '#0f172a' }}
                                                autoFocus
                                            />
                                        </div>
                                    </div>

                                    {/* List */}
                                    <div className="max-h-52 overflow-y-auto">
                                        {loadingList ? (
                                            <div className="flex items-center justify-center py-6">
                                                <Loader2 className="h-5 w-5 animate-spin" style={{ color: '#f97316' }} />
                                            </div>
                                        ) : filtered.length === 0 ? (
                                            <p className="text-sm text-center py-4" style={{ color: '#94a3b8' }}>
                                                Aucun restaurant trouvé
                                            </p>
                                        ) : (
                                            filtered.map(r => (
                                                <button
                                                    key={r.id}
                                                    type="button"
                                                    onClick={() => handleSelect(r)}
                                                    className="w-full flex items-center gap-3 px-3 py-2.5 text-left transition-colors"
                                                    style={{
                                                        background: selected?.id === r.id ? '#fff7ed' : 'transparent',
                                                    }}
                                                    onMouseEnter={e => { if (selected?.id !== r.id) (e.currentTarget as HTMLButtonElement).style.background = '#f8fafc'; }}
                                                    onMouseLeave={e => { if (selected?.id !== r.id) (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}
                                                >
                                                    {r.logo ? (
                                                        <img src={buildLogoUrl(r.logo)} alt="" className="w-8 h-8 rounded-lg object-cover shrink-0" />
                                                    ) : (
                                                        <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                                                            style={{ background: '#fff7ed' }}>
                                                            <Store className="h-4 w-4" style={{ color: '#f97316' }} />
                                                        </div>
                                                    )}
                                                    <div className="min-w-0">
                                                        <p className="text-sm font-semibold truncate" style={{ color: '#0f172a' }}>{r.nom}</p>
                                                        <p className="text-xs truncate" style={{ color: '#94a3b8' }}>{r.adresse}</p>
                                                    </div>
                                                    {selected?.id === r.id && (
                                                        <div className="ml-auto w-2 h-2 rounded-full shrink-0" style={{ background: '#f97316' }} />
                                                    )}
                                                </button>
                                            ))
                                        )}
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* Email */}
                        <div>
                            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: '#64748b' }}>
                                Email
                            </label>
                            <div className="relative">
                                <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: '#94a3b8' }} />
                                <input
                                    type="email"
                                    value={email}
                                    onChange={e => setEmail(e.target.value)}
                                    required
                                    placeholder="admin@restaurant.com"
                                    className="w-full pl-10 pr-4 py-3 rounded-xl text-sm outline-none transition-all"
                                    style={{ background: '#fff', border: '1.5px solid #e2e8f0', color: '#0f172a' }}
                                    onFocus={e => (e.target.style.border = '2px solid #f97316')}
                                    onBlur={e => (e.target.style.border = '1.5px solid #e2e8f0')}
                                />
                            </div>
                        </div>

                        {/* Password */}
                        <div>
                            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: '#64748b' }}>
                                Mot de passe
                            </label>
                            <div className="relative">
                                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: '#94a3b8' }} />
                                <input
                                    type={showPw ? 'text' : 'password'}
                                    value={password}
                                    onChange={e => setPassword(e.target.value)}
                                    required
                                    placeholder="••••••••"
                                    className="w-full pl-10 pr-12 py-3 rounded-xl text-sm outline-none transition-all"
                                    style={{ background: '#fff', border: '1.5px solid #e2e8f0', color: '#0f172a' }}
                                    onFocus={e => (e.target.style.border = '2px solid #f97316')}
                                    onBlur={e => (e.target.style.border = '1.5px solid #e2e8f0')}
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPw(p => !p)}
                                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-xs font-medium"
                                    style={{ color: '#94a3b8' }}
                                >
                                    {showPw ? 'Masquer' : 'Voir'}
                                </button>
                            </div>
                        </div>

                        {/* Submit */}
                        <button
                            type="submit"
                            disabled={isLoading || !selected}
                            className="w-full flex items-center justify-center gap-2 py-3.5 px-4 rounded-xl font-semibold text-sm transition-all"
                            style={{
                                background: isLoading ? '#cbd5e1' : '#f97316',
                                color: '#fff',
                                cursor: isLoading ? 'not-allowed' : 'pointer',
                            }}
                        >
                            {isLoading ? (
                                <><Loader2 className="h-4 w-4 animate-spin" /> Connexion…</>
                            ) : selected ? (
                                <>Accéder à mon espace</>
                            ) : (
                                <>Se connecter (super admin)</>
                            )}
                        </button>
                    </form>

                    <p className="text-center text-xs" style={{ color: '#94a3b8' }}>
                        Connexion directe super admin ?{' '}
                        <a href="/portal-admin" className="font-semibold" style={{ color: '#f97316' }}>
                            Connexion admin
                        </a>
                    </p>
                </div>
            </div>

            {/* Click outside to close dropdown */}
            {dropdownOpen && (
                <div className="fixed inset-0 z-40" onClick={() => setDropdownOpen(false)} />
            )}
        </div>
    );
}
