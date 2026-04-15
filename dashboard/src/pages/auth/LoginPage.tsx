import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { Mail, Lock, Loader2, ShoppingBag, TrendingUp, Star, ArrowRight } from 'lucide-react';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);
    try {
      await login(email, password);
      navigate('/');
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      setError(e.response?.data?.message || 'Identifiants invalides');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex" style={{ background: '#f1f5f9' }}>

      {/* â”€â”€ Left panel â€” branding (hidden on mobile) â”€â”€ */}
      <div className="hidden lg:flex lg:w-[52%] relative overflow-hidden"
        style={{ background: 'linear-gradient(145deg, #0f172a 0%, #1e1b4b 50%, #0f172a 100%)' }}>

        {/* Decorative blobs */}
        <div className="absolute top-0 left-0 w-96 h-96 rounded-full opacity-20 blur-3xl"
          style={{ background: 'radial-gradient(circle,#f97316,transparent)', transform: 'translate(-30%,-30%)' }} />
        <div className="absolute bottom-0 right-0 w-80 h-80 rounded-full opacity-15 blur-3xl"
          style={{ background: 'radial-gradient(circle,#8b5cf6,transparent)', transform: 'translate(30%,30%)' }} />
        <div className="absolute top-1/2 left-1/2 w-64 h-64 rounded-full opacity-10 blur-2xl"
          style={{ background: 'radial-gradient(circle,#3b82f6,transparent)', transform: 'translate(-50%,-50%)' }} />

        <div className="relative flex flex-col justify-between p-12 w-full">
          {/* Logo */}
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl flex items-center justify-center"
              style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
              <span className="text-white font-black text-xl">N</span>
            </div>
            <span className="text-white font-bold text-xl">Noogo</span>
          </div>

          {/* Center content */}
          <div className="space-y-8">
            <div>
              <h1 className="text-4xl font-black leading-tight mb-4" style={{ color: 'white' }}>
                GÃ©rez votre<br />
                <span style={{ background: 'linear-gradient(90deg,#f97316,#fb923c)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                  restaurant
                </span>{' '}
                avec style
              </h1>
              <p className="text-base leading-relaxed" style={{ color: '#94a3b8' }}>
                Commandes en temps rÃ©el, gestion du menu, rapports de revenus â€” tout ce dont vous avez besoin dans un seul tableau de bord.
              </p>
            </div>

            {/* Feature cards */}
            <div className="space-y-3">
              {[
                { icon: <ShoppingBag className="h-4 w-4" />, label: 'Commandes en temps rÃ©el', color: '#f97316', bg: 'rgba(249,115,22,0.12)' },
                { icon: <TrendingUp className="h-4 w-4" />, label: 'Rapports & analytics', color: '#10b981', bg: 'rgba(16,185,129,0.12)' },
                { icon: <Star className="h-4 w-4" />, label: 'Gestion des avis clients', color: '#8b5cf6', bg: 'rgba(139,92,246,0.12)' },
              ].map(f => (
                <div key={f.label} className="flex items-center gap-3 px-4 py-3 rounded-xl"
                  style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.06)' }}>
                  <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                    style={{ background: f.bg, color: f.color }}>
                    {f.icon}
                  </div>
                  <span className="text-sm font-medium" style={{ color: '#e2e8f0' }}>{f.label}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Footer */}
          <p className="text-xs" style={{ color: '#475569' }}>
            Â© 2026 Noogo â€” Tous droits rÃ©servÃ©s
          </p>
        </div>
      </div>

      {/* â”€â”€ Right panel â€” form â”€â”€ */}
      <div className="flex-1 flex items-center justify-center p-6">
        <div className="w-full max-w-sm animate-fadeIn">

          {/* Mobile logo */}
          <div className="flex items-center gap-2.5 mb-8 lg:hidden">
            <div className="w-9 h-9 rounded-xl flex items-center justify-center"
              style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
              <span className="text-white font-black text-lg">N</span>
            </div>
            <span className="font-bold text-xl" style={{ color: '#0f172a' }}>Noogo</span>
          </div>

          <div className="mb-8">
            <h2 className="text-2xl font-bold mb-1.5" style={{ color: '#0f172a' }}>Bon retour ðŸ‘‹</h2>
            <p className="text-sm" style={{ color: '#64748b' }}>
              Connectez-vous Ã  votre espace de gestion
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            {error && (
              <div className="flex items-start gap-3 px-4 py-3 rounded-xl text-sm"
                style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca' }}>
                <span className="mt-0.5">âš </span>
                <span>{error}</span>
              </div>
            )}

            {/* Email */}
            <div>
              <label className="block text-sm font-semibold mb-1.5" style={{ color: '#374151' }}>
                Adresse email
              </label>
              <div className="relative">
                <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: '#94a3b8' }} />
                <input
                  type="email"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  required
                  autoComplete="email"
                  placeholder="votre@email.com"
                  className="input-pro pl-10"
                />
              </div>
            </div>

            {/* Password */}
            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-sm font-semibold" style={{ color: '#374151' }}>
                  Mot de passe
                </label>
                <Link to="/forgot-password"
                  className="text-xs font-medium hover:underline"
                  style={{ color: '#f97316' }}>
                  OubliÃ© ?
                </Link>
              </div>
              <div className="relative">
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: '#94a3b8' }} />
                <input
                  type={showPw ? 'text' : 'password'}
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  required
                  autoComplete="current-password"
                  placeholder="â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢"
                  className="input-pro pl-10 pr-10"
                />
                <button type="button" onClick={() => setShowPw(v => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-medium"
                  style={{ color: '#94a3b8' }}>
                  {showPw ? 'Masquer' : 'Voir'}
                </button>
              </div>
            </div>

            {/* Submit */}
            <button type="submit" disabled={isLoading} className="btn-primary w-full py-3 text-sm mt-1">
              {isLoading
                ? <><Loader2 className="h-4 w-4 animate-spin" /> Connexionâ€¦</>
                : <> Se connecter <ArrowRight className="h-4 w-4" /></>
              }
            </button>
          </form>

          <p className="text-center text-sm mt-6" style={{ color: '#64748b' }}>
            Pas encore de compte ?{' '}
            <Link to="/register" className="font-semibold hover:underline" style={{ color: '#f97316' }}>
              CrÃ©er un compte
            </Link>
          </p>

          {/* Demo hint */}
          <div className="mt-6 px-4 py-3 rounded-xl text-center"
            style={{ background: '#f8fafc', border: '1px solid #e2e8f0' }}>
            <p className="text-xs" style={{ color: '#64748b' }}>
              <span className="font-semibold" style={{ color: '#374151' }}>DÃ©mo :</span>{' '}
              owner@noogo.com / password
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

