import { Link, useLocation, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Store,
  UtensilsCrossed,
  ShoppingBag,
  Tag,
  Menu,
  X,
  LogOut,
  ChevronDown,
  ChevronRight,
  User,
  Users,
} from 'lucide-react';
import { useEffect, useMemo, useRef, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { dashboardApi, myRestaurantsApi } from '../../services/api';
import type { MyRestaurant } from '../../types';

const ADMIN_NAV = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Restaurants', href: '/restaurants', icon: Store },
  { name: 'Commandes', href: '/orders', icon: ShoppingBag },
  { name: 'Menu', href: '/menu', icon: UtensilsCrossed },
  { name: 'Promotions', href: '/promotions', icon: Tag },
];

export default function Sidebar() {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [pendingCount, setPendingCount] = useState(0);
  const [myRestaurants, setMyRestaurants] = useState<MyRestaurant[]>([]);
  const [showAll, setShowAll] = useState(false);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const uniqueRestaurants = useMemo(() => {
    const seen = new Map<number, MyRestaurant>();
    for (const r of myRestaurants) if (!seen.has(r.id)) seen.set(r.id, r);
    return Array.from(seen.values()).sort((a, b) => a.nom.localeCompare(b.nom));
  }, [myRestaurants]);

  const MAX_VISIBLE = 4;
  const visible = showAll ? uniqueRestaurants : uniqueRestaurants.slice(0, MAX_VISIBLE);
  const hiddenCount = uniqueRestaurants.length - MAX_VISIBLE;

  useEffect(() => {
    if (user && !user.is_admin)
      myRestaurantsApi.get().then(r => setMyRestaurants(r.data.data ?? [])).catch(() => { });
  }, [user]);

  const navigation = user?.is_admin
    ? ADMIN_NAV
    : [
      { name: 'Commandes', href: '/orders', icon: ShoppingBag },
      { name: 'Menu', href: '/menu', icon: UtensilsCrossed },
      { name: 'Promotions', href: '/promotions', icon: Tag },
    ];

  useEffect(() => {
    const fetch = () =>
      dashboardApi.getStats()
        .then(r => setPendingCount(r.data?.data?.today?.pending_orders ?? 0))
        .catch(() => { });
    fetch();
    intervalRef.current = setInterval(fetch, 30_000);
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, []);

  const handleLogout = async () => { await logout(); navigate('/login'); };

  /* ── Status dot color ── */
  const dotColor = (r: MyRestaurant) =>
    !r.is_active ? '#475569' : r.is_open !== false ? '#22c55e' : '#f59e0b';

  /* ── Sidebar inner ── */
  const SidebarContent = () => (
    <div className="flex flex-col h-full">

      {/* ── Logo ── */}
      <div className="flex items-center gap-3 px-5 h-16 border-b shrink-0"
        style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
        <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
          style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
          <span className="text-white font-black text-lg leading-none">N</span>
        </div>
        <div>
          <p className="text-white font-bold text-base leading-tight">Noogo</p>
          <p className="text-xs leading-tight" style={{ color: '#64748b' }}>
            {user?.is_admin ? 'Super Admin' : 'Tableau de bord'}
          </p>
        </div>
      </div>

      {/* ── Nav ── */}
      <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto sidebar-scroll">

        {/* Mes restaurants (non-admin) */}
        {!user?.is_admin && uniqueRestaurants.length > 0 && (
          <div className="mb-3">
            <div className="flex items-center justify-between px-3 mb-1.5">
              <span className="text-[10px] font-semibold uppercase tracking-widest"
                style={{ color: '#475569' }}>
                Mes restaurants
              </span>
              <span className="text-[10px] px-1.5 py-0.5 rounded-full font-semibold"
                style={{ background: 'rgba(255,255,255,0.07)', color: '#94a3b8' }}>
                {uniqueRestaurants.length}
              </span>
            </div>

            {visible.map(r => {
              const href = `/restaurants/${r.id}`;
              const isActive = location.pathname.startsWith(href);
              return (
                <Link key={r.id} to={href} onClick={() => setIsOpen(false)}
                  className={`nav-item${isActive ? ' active' : ''}`}>
                  <div className="relative shrink-0">
                    <Store className="h-4 w-4" />
                    <span className="absolute -bottom-0.5 -right-0.5 w-2 h-2 rounded-full border border-[#0f172a]"
                      style={{ background: dotColor(r) }} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="truncate text-sm">{r.nom}</p>
                    <p className="text-[11px] truncate" style={{ color: '#475569' }}>
                      {r.role_label}
                      {r.is_active === false && <span style={{ color: '#ef4444' }}> · Inactif</span>}
                    </p>
                  </div>
                  {isActive && <ChevronRight className="h-3.5 w-3.5 shrink-0" style={{ color: '#f97316' }} />}
                </Link>
              );
            })}

            {uniqueRestaurants.length > MAX_VISIBLE && (
              <button onClick={() => setShowAll(v => !v)}
                className="nav-item w-full text-xs gap-2">
                <ChevronDown className={`h-3.5 w-3.5 transition-transform ${showAll ? 'rotate-180' : ''}`} />
                {showAll ? 'Réduire' : `+${hiddenCount} restaurant${hiddenCount > 1 ? 's' : ''}`}
              </button>
            )}

            {uniqueRestaurants.some(r => ['owner', 'manager'].includes(r.role)) && (
              <Link to="/restaurants" onClick={() => setIsOpen(false)}
                className="nav-item text-xs mt-0.5"
                style={{ color: '#f97316' }}>
                <Users className="h-3.5 w-3.5" />
                Gérer le personnel
              </Link>
            )}

            <div className="mx-3 my-3 border-t" style={{ borderColor: 'rgba(255,255,255,0.06)' }} />
          </div>
        )}

        {/* Main nav */}
        {navigation.map(item => {
          const isActive = location.pathname === item.href ||
            (item.href !== '/' && location.pathname.startsWith(item.href));
          const showBadge = item.href === '/orders' && pendingCount > 0;
          return (
            <Link key={item.name} to={item.href} onClick={() => setIsOpen(false)}
              className={`nav-item${isActive ? ' active' : ''}`}>
              <item.icon className="h-4.5 w-4.5 shrink-0" style={{ width: 18, height: 18 }} />
              <span className="flex-1">{item.name}</span>
              {showBadge && (
                <span className="badge-pulse inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full text-[10px] font-bold"
                  style={{ background: '#ef4444', color: 'white' }}>
                  {pendingCount > 99 ? '99+' : pendingCount}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      {/* ── User footer ── */}
      <div className="px-3 pb-4 shrink-0 border-t" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
        <div className="relative mt-3">
          <button onClick={() => setShowUserMenu(v => !v)}
            className="flex items-center gap-3 w-full p-2.5 rounded-xl transition-colors"
            style={{ background: showUserMenu ? 'rgba(255,255,255,0.08)' : 'transparent' }}
            onMouseEnter={e => { if (!showUserMenu) (e.currentTarget as HTMLButtonElement).style.background = 'rgba(255,255,255,0.05)'; }}
            onMouseLeave={e => { if (!showUserMenu) (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}>
            {/* Avatar */}
            <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0 font-bold text-sm"
              style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)', color: 'white' }}>
              {user?.name?.charAt(0).toUpperCase()}
            </div>
            <div className="flex-1 text-left min-w-0">
              <p className="text-sm font-semibold truncate" style={{ color: '#e2e8f0' }}>
                {user?.name}
              </p>
              <p className="text-[11px] truncate" style={{ color: '#475569' }}>{user?.email}</p>
            </div>
            <ChevronDown className={`h-4 w-4 transition-transform shrink-0 ${showUserMenu ? 'rotate-180' : ''}`}
              style={{ color: '#475569' }} />
          </button>

          {showUserMenu && (
            <div className="absolute bottom-full left-0 right-0 mb-2 rounded-xl shadow-2xl py-1 animate-fadeIn"
              style={{ background: '#1e293b', border: '1px solid rgba(255,255,255,0.08)' }}>
              <Link to="/profile" onClick={() => setShowUserMenu(false)}
                className="flex items-center gap-2.5 px-4 py-2.5 text-sm transition-colors"
                style={{ color: '#cbd5e1' }}
                onMouseEnter={e => (e.currentTarget as HTMLAnchorElement).style.background = 'rgba(255,255,255,0.06)'}
                onMouseLeave={e => (e.currentTarget as HTMLAnchorElement).style.background = 'transparent'}>
                <User className="h-4 w-4" style={{ color: '#64748b' }} />
                Mon profil
              </Link>
              <div className="mx-3 my-1 border-t" style={{ borderColor: 'rgba(255,255,255,0.06)' }} />
              <button onClick={handleLogout}
                className="flex items-center gap-2.5 w-full px-4 py-2.5 text-sm transition-colors"
                style={{ color: '#f87171' }}
                onMouseEnter={e => (e.currentTarget as HTMLButtonElement).style.background = 'rgba(239,68,68,0.08)'}
                onMouseLeave={e => (e.currentTarget as HTMLButtonElement).style.background = 'transparent'}>
                <LogOut className="h-4 w-4" />
                Déconnexion
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );

  return (
    <>
      {/* Mobile toggle */}
      <button
        className="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-xl shadow-lg"
        style={{ background: '#0f172a', color: 'white' }}
        onClick={() => setIsOpen(!isOpen)}>
        {isOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
      </button>

      {/* Overlay */}
      {isOpen && (
        <div className="lg:hidden fixed inset-0 z-40 bg-black/60 backdrop-blur-sm"
          onClick={() => setIsOpen(false)} />
      )}

      {/* Sidebar */}
      <aside
        style={{
          width: 260,
          background: '#0f172a',
          borderRight: '1px solid rgba(255,255,255,0.04)',
        }}
        className={`
          fixed inset-y-0 left-0 z-40
          transform transition-transform duration-300 ease-in-out
          lg:translate-x-0
          ${isOpen ? 'translate-x-0' : '-translate-x-full'}
        `}>
        <SidebarContent />
      </aside>
    </>
  );
}

import { useEffect, useMemo, useRef, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { dashboardApi, myRestaurantsApi } from '../../services/api';
import type { MyRestaurant } from '../../types';

// Navigation para super admin
const ADMIN_NAV = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Restaurants', href: '/restaurants', icon: Store },
  { name: 'Commandes', href: '/orders', icon: ShoppingBag },
  { name: 'Menu', href: '/menu', icon: UtensilsCrossed },
  { name: 'Promotions', href: '/promotions', icon: Tag },
];

export default function Sidebar() {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [pendingOrdersCount, setPendingOrdersCount] = useState(0);
  const [myRestaurants, setMyRestaurants] = useState<MyRestaurant[]>([]);
  const [showAllRestaurants, setShowAllRestaurants] = useState(false);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Dédoublonner par id (sécurité côté client en cas de doublon API)
  const uniqueRestaurants = useMemo(() => {
    const seen = new Map<number, MyRestaurant>();
    for (const r of myRestaurants) {
      if (!seen.has(r.id)) seen.set(r.id, r);
    }
    return Array.from(seen.values()).sort((a, b) => a.nom.localeCompare(b.nom));
  }, [myRestaurants]);

  const MAX_VISIBLE = 4;
  const visibleRestaurants = showAllRestaurants
    ? uniqueRestaurants
    : uniqueRestaurants.slice(0, MAX_VISIBLE);
  const hiddenCount = uniqueRestaurants.length - MAX_VISIBLE;

  // Charger "mes restaurants" pour les non-admins
  useEffect(() => {
    if (user && !user.is_admin) {
      myRestaurantsApi.get()
        .then(res => setMyRestaurants(res.data.data ?? []))
        .catch(() => {/* silencieux */ });
    }
  }, [user]);

  // navigation dynamique selon le rôle
  const navigation = user?.is_admin
    ? ADMIN_NAV
    : [
      { name: 'Commandes', href: '/orders', icon: ShoppingBag },
      { name: 'Menu', href: '/menu', icon: UtensilsCrossed },
      { name: 'Promotions', href: '/promotions', icon: Tag },
    ];

  // Polling commandes en attente (toutes les 30s)
  useEffect(() => {
    const fetchPending = () => {
      dashboardApi.getStats()
        .then(res => {
          const count: number = res.data?.data?.today?.pending_orders ?? 0;
          setPendingOrdersCount(count);
        })
        .catch(() => { /* silencieux si non connecté */ });
    };
    fetchPending();
    intervalRef.current = setInterval(fetchPending, 30_000);
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, []);

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <>
      {/* Mobile menu button */}
      <button
        className="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-lg bg-white shadow-md"
        onClick={() => setIsOpen(!isOpen)}
      >
        {isOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
      </button>

      {/* Overlay */}
      {isOpen && (
        <div
          className="lg:hidden fixed inset-0 bg-black/50 z-40"
          onClick={() => setIsOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside className={`
        fixed inset-y-0 left-0 z-40 w-64 bg-white border-r border-gray-200 
        transform transition-transform duration-300 ease-in-out
        lg:translate-x-0 lg:static lg:inset-auto
        ${isOpen ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="flex items-center justify-center h-16 border-b border-gray-200">
            <Link to="/" className="flex items-center gap-2">
              <div className="w-8 h-8 bg-orange-500 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-lg">N</span>
              </div>
              <span className="text-xl font-bold text-gray-900">Noogo</span>
            </Link>
          </div>

          {/* Navigation */}
          <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
            {/* Mes Restaurants (non-admin) */}
            {!user?.is_admin && uniqueRestaurants.length > 0 && (
              <div className="mb-4">
                <div className="flex items-center justify-between px-4 mb-2">
                  <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">
                    Mes restaurants
                  </p>
                  <span className="text-xs text-gray-400 bg-gray-100 px-1.5 py-0.5 rounded-full">
                    {uniqueRestaurants.length}
                  </span>
                </div>

                {visibleRestaurants.map(r => {
                  const href = `/restaurants/${r.id}`;
                  const isActive = location.pathname.startsWith(href);
                  return (
                    <Link
                      key={r.id}
                      to={href}
                      onClick={() => setIsOpen(false)}
                      className={`flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium transition-colors duration-200 ${isActive ? 'bg-orange-50 text-orange-600' : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'}`}
                    >
                      {/* Indicateur statut : vert = actif+ouvert, jaune = actif+fermé, gris = inactif */}
                      <div className="relative flex-shrink-0">
                        <Store className={`h-4 w-4 ${isActive ? 'text-orange-500' : 'text-gray-400'}`} />
                        <Circle
                          className={`absolute -bottom-0.5 -right-0.5 h-2 w-2 fill-current ${!r.is_active ? 'text-gray-300' :
                            r.is_open !== false ? 'text-emerald-500' :
                              'text-amber-400'
                            }`}
                        />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="truncate leading-tight">{r.nom}</p>
                        <p className="text-xs text-gray-400 leading-tight">
                          {r.role_label}
                          {r.is_active === false && (
                            <span className="ml-1 text-red-400">· Inactif</span>
                          )}
                        </p>
                      </div>
                      {isActive && <ChevronRight className="h-3.5 w-3.5 text-orange-400 flex-shrink-0" />}
                    </Link>
                  );
                })}

                {/* Expand / Collapse si > MAX_VISIBLE */}
                {uniqueRestaurants.length > MAX_VISIBLE && (
                  <button
                    onClick={() => setShowAllRestaurants(v => !v)}
                    className="flex items-center gap-2 w-full px-4 py-1.5 text-xs text-gray-400 hover:text-gray-600 hover:bg-gray-50 rounded-lg transition-colors"
                  >
                    <ChevronDown className={`h-3.5 w-3.5 transition-transform ${showAllRestaurants ? 'rotate-180' : ''}`} />
                    {showAllRestaurants
                      ? 'Réduire'
                      : `Voir ${hiddenCount} restaurant${hiddenCount > 1 ? 's' : ''} de plus`}
                  </button>
                )}

                {uniqueRestaurants.some(r => ['owner', 'manager'].includes(r.role)) && (
                  <Link
                    to="/restaurants"
                    onClick={() => setIsOpen(false)}
                    className="flex items-center gap-2 px-4 py-2 rounded-lg text-xs text-orange-500 hover:bg-orange-50 transition-colors mt-1"
                  >
                    <Users className="h-3.5 w-3.5" /> Gérer le personnel
                  </Link>
                )}
                <div className="border-t border-gray-100 my-3" />
              </div>
            )}

            {navigation.map((item) => {
              const isActive = location.pathname === item.href ||
                (item.href !== '/' && location.pathname.startsWith(item.href));
              const showBadge = item.href === '/orders' && pendingOrdersCount > 0;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  onClick={() => setIsOpen(false)}
                  className={`
                    flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium
                    transition-colors duration-200
                    ${isActive
                      ? 'bg-orange-50 text-orange-600'
                      : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                    }
                  `}
                >
                  <item.icon className={`h-5 w-5 flex-shrink-0 ${isActive ? 'text-orange-500' : 'text-gray-400'}`} />
                  <span className="flex-1">{item.name}</span>
                  {showBadge && (
                    <span className="inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full bg-red-500 text-white text-xs font-bold">
                      {pendingOrdersCount > 99 ? '99+' : pendingOrdersCount}
                    </span>
                  )}
                </Link>
              );
            })}
          </nav>

          {/* User menu */}
          <div className="border-t border-gray-200 p-4">
            <div className="relative">
              <button
                onClick={() => setShowUserMenu(!showUserMenu)}
                className="flex items-center gap-3 w-full p-2 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center">
                  <span className="text-orange-600 font-semibold">
                    {user?.name?.charAt(0).toUpperCase()}
                  </span>
                </div>
                <div className="flex-1 text-left">
                  <p className="text-sm font-medium text-gray-900 truncate">{user?.name}</p>
                  <p className="text-xs text-gray-500 truncate">{user?.email}</p>
                </div>
                <ChevronDown className={`h-4 w-4 text-gray-400 transition-transform ${showUserMenu ? 'rotate-180' : ''}`} />
              </button>

              {showUserMenu && (
                <div className="absolute bottom-full left-0 right-0 mb-2 bg-white rounded-lg shadow-lg border border-gray-200 py-1">
                  <Link
                    to="/profile"
                    onClick={() => setShowUserMenu(false)}
                    className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                  >
                    <User className="h-4 w-4" />
                    Mon profil
                  </Link>
                  <button
                    onClick={handleLogout}
                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                  >
                    <LogOut className="h-4 w-4" />
                    Déconnexion
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </aside>
    </>
  );
}
