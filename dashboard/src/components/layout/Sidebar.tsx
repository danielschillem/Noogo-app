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
  ShieldCheck,
  Truck,
  Package,
  Star,
} from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { myRestaurantsApi } from '../../services/api';
import { usePendingCount } from '../../hooks/useQueries';
import type { MyRestaurant } from '../../types';

const ADMIN_NAV = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Restaurants', href: '/restaurants', icon: Store },
  { name: 'Commandes', href: '/orders', icon: ShoppingBag },
  { name: 'Menu', href: '/menu', icon: UtensilsCrossed },
  { name: 'Promotions', href: '/promotions', icon: Tag },
  { name: 'Avis clients', href: '/ratings', icon: Star },
  { name: 'Livreurs', href: '/drivers', icon: Truck },
  { name: 'Livraisons', href: '/deliveries', icon: Package },
  { name: 'Administration', href: '/admin', icon: ShieldCheck },
];

export default function Sidebar({ restaurantId }: { restaurantId?: number }) {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [showUserMenu, setShowUserMenu] = useState(false);
  const { data: pendingCount = 0 } = usePendingCount();
  const [myRestaurants, setMyRestaurants] = useState<MyRestaurant[]>([]);
  const [showAll, setShowAll] = useState(false);

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

  // Mode verrouillé : navigation limitée à ce restaurant
  const isLocked = !!restaurantId;
  const lockedNav = restaurantId ? [
    { name: 'Commandes', href: `/r/${restaurantId}/orders`, icon: ShoppingBag },
    { name: 'Cuisine', href: `/r/${restaurantId}/kitchen`, icon: UtensilsCrossed },
    { name: 'Menu', href: `/r/${restaurantId}/menu`, icon: Tag },
  ] : [];

  const navigation = isLocked
    ? lockedNav
    : user?.is_admin
      ? ADMIN_NAV
      : [
        { name: 'Commandes', href: '/orders', icon: ShoppingBag },
        { name: 'Menu', href: '/menu', icon: UtensilsCrossed },
        { name: 'Promotions', href: '/promotions', icon: Tag },
        { name: 'Avis clients', href: '/ratings', icon: Star },
      ];

  const handleLogout = async () => { await logout(); navigate('/login'); };

  /* â”€â”€ Status dot color â”€â”€ */
  const dotColor = (r: MyRestaurant) =>
    !r.is_active ? '#475569' : r.is_open !== false ? '#22c55e' : '#f59e0b';

  /* â”€â”€ Sidebar inner â”€â”€ */
  const SidebarContent = () => (
    <div className="flex flex-col h-full">

      {/* â”€â”€ Logo â”€â”€ */}
      <div className="flex items-center justify-center px-5 py-5 border-b shrink-0"
        style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
        <div className="flex flex-col items-center gap-2">
          <img src="/noogo-icon.png" alt="Noogo" className="w-10 h-10" />
          <div className="text-center">
            <p className="text-white font-bold text-sm tracking-wide">NOOGO</p>
            <p className="text-[10px] font-medium uppercase tracking-widest mt-0.5"
              style={{ color: '#f97316' }}>
              {user?.is_admin ? 'Super Admin' : isLocked ? 'Espace restaurant' : 'Tableau de bord'}
            </p>
          </div>
        </div>
      </div>

      {/* â”€â”€ Nav â”€â”€ */}
      <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto sidebar-scroll">

        {/* Mes restaurants (non-admin, non-verrouillé) */}
        {!user?.is_admin && !isLocked && uniqueRestaurants.length > 0 && (
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
                      {r.is_active === false && <span style={{ color: '#ef4444' }}> Â· Inactif</span>}
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

      {/* â”€â”€ User footer â”€â”€ */}
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

