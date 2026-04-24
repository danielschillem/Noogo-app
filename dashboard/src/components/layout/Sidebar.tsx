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
  Star,
  ClipboardList,
} from 'lucide-react';
import { useMemo, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { usePendingCount } from '../../hooks/useQueries';
import type { MyRestaurant } from '../../types';

const SUPER_ADMIN_NAV = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Restaurants', href: '/restaurants', icon: Store },
  { name: 'Plateforme', href: '/admin', icon: ShieldCheck },
];

const RESTAURANT_ADMIN_NAV = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Restaurants', href: '/restaurants', icon: Store },
  { name: 'Commandes', href: '/orders', icon: ShoppingBag },
  { name: 'Menu', href: '/menu', icon: UtensilsCrossed },
  { name: 'Commandes orales', href: '/oral-notes', icon: ClipboardList },
  { name: 'Promotions', href: '/promotions', icon: Tag },
  { name: 'Avis clients', href: '/ratings', icon: Star },
];

export default function Sidebar({ restaurantId }: { restaurantId?: number }) {
  const location = useLocation();
  const navigate = useNavigate();
  const {
    user,
    logout,
    myRestaurants,
    selectedRestaurantId,
    setSelectedRestaurantId,
    hasRestaurantPermission,
    isOwnerOrManager,
  } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [showUserMenu, setShowUserMenu] = useState(false);
  const { data: pendingCount = 0 } = usePendingCount();
  const [showAll, setShowAll] = useState(false);

  const uniqueRestaurants = useMemo(() => {
    const seen = new Map<number, MyRestaurant>();
    for (const r of myRestaurants) if (!seen.has(r.id)) seen.set(r.id, r);
    return Array.from(seen.values()).sort((a, b) => a.nom.localeCompare(b.nom));
  }, [myRestaurants]);

  const MAX_VISIBLE = 4;
  const visible = showAll ? uniqueRestaurants : uniqueRestaurants.slice(0, MAX_VISIBLE);
  const hiddenCount = uniqueRestaurants.length - MAX_VISIBLE;

  // Mode verrouillé : navigation limitée à ce restaurant
  const isLocked = !!restaurantId;

  const isSuperAdmin = !!user?.is_admin && user?.role === 'super_admin';
  const isRestaurantAdmin = !!user?.is_admin && user?.role === 'admin';
  const ctxRestaurantId = restaurantId ?? selectedRestaurantId ?? uniqueRestaurants[0]?.id ?? null;
  const canManageOrders = hasRestaurantPermission('manage_orders', ctxRestaurantId);
  const canManageMenu = hasRestaurantPermission('manage_menu', ctxRestaurantId);
  const canViewStats = hasRestaurantPermission('view_stats', ctxRestaurantId);
  const canKitchen = hasRestaurantPermission('kitchen_display', ctxRestaurantId);
  const canManageStaff = hasRestaurantPermission('manage_staff', ctxRestaurantId) || isOwnerOrManager(ctxRestaurantId);

  const staffNav = [
    canManageOrders ? { name: 'Commandes', href: '/orders', icon: ShoppingBag } : null,
    canManageMenu ? { name: 'Menu', href: '/menu', icon: UtensilsCrossed } : null,
    canManageOrders ? { name: 'Commandes orales', href: '/oral-notes', icon: ClipboardList } : null,
    canViewStats ? { name: 'Promotions', href: '/promotions', icon: Tag } : null,
    canViewStats ? { name: 'Avis clients', href: '/ratings', icon: Star } : null,
  ].filter(Boolean) as { name: string; href: string; icon: typeof ShoppingBag }[];

  const lockedScopedNav = restaurantId ? [
    canManageOrders ? { name: 'Commandes', href: `/r/${restaurantId}/orders`, icon: ShoppingBag } : null,
    canKitchen ? { name: 'Cuisine', href: `/r/${restaurantId}/kitchen`, icon: UtensilsCrossed } : null,
    canManageMenu ? { name: 'Menu', href: `/r/${restaurantId}/menu`, icon: Tag } : null,
    canManageOrders ? { name: 'Commandes orales', href: `/r/${restaurantId}/oral-notes`, icon: ClipboardList } : null,
  ].filter(Boolean) as { name: string; href: string; icon: typeof ShoppingBag }[] : [];

  const navigation = isLocked
    ? lockedScopedNav
    : isSuperAdmin
      ? SUPER_ADMIN_NAV
      : isRestaurantAdmin
        ? RESTAURANT_ADMIN_NAV
      : staffNav;

  const handleLogout = async () => { await logout(); navigate('/login'); };

  /* Status dot color */
  const dotColor = (r: MyRestaurant) =>
    !r.is_active ? '#475569' : r.is_open !== false ? '#22c55e' : '#f59e0b';

  /* Sidebar inner */
  const SidebarContent = () => (
    <div className="flex flex-col h-full">

      {/* Logo */}
      <div className="flex items-center justify-center px-5 py-5 border-b shrink-0" style={{ borderColor: '#eef2f7' }}>
        <div className="flex flex-col items-center gap-2.5">
          <div className="w-11 h-11 rounded-2xl flex items-center justify-center shadow-sm" style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)' }}>
            <img src="/noogo-icon.png" alt="Noogo" className="w-6.5 h-6.5" />
          </div>
          <div className="text-center">
            <p className="font-extrabold text-sm tracking-wide" style={{ color: '#0f172a' }}>NOOGO</p>
            <p className="text-[10px] font-semibold uppercase tracking-widest mt-0.5" style={{ color: '#f97316' }}>
              {isSuperAdmin ? 'Super Admin' : isRestaurantAdmin ? 'Admin restaurant' : isLocked ? 'Espace restaurant' : 'Tableau de bord'}
            </p>
          </div>
        </div>
      </div>

      {/* â”€â”€ Nav â”€â”€ */}
      <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto sidebar-scroll">

        {/* Mes restaurants (non-admin, non-verrouillé) */}
        {!isSuperAdmin && !isLocked && uniqueRestaurants.length > 0 && (
          <div className="mb-3">
            <div className="flex items-center justify-between px-3 mb-1.5">
              <span className="text-[10px] font-semibold uppercase tracking-widest" style={{ color: '#94a3b8' }}>
                Mes restaurants
              </span>
              <span className="text-[10px] px-1.5 py-0.5 rounded-full font-semibold"
                style={{ background: '#fff7ed', color: '#f97316', border: '1px solid #fed7aa' }}>
                {uniqueRestaurants.length}
              </span>
            </div>

            {visible.map(r => {
              const href = `/restaurants/${r.id}`;
              const isActive = location.pathname.startsWith(href);
              return (
                <Link key={r.id} to={href} onClick={() => { setSelectedRestaurantId(r.id); setIsOpen(false); }}
                  className={`nav-item${isActive || r.id === selectedRestaurantId ? ' active' : ''}`}>
                  <div className="relative shrink-0">
                    <Store className="h-4 w-4" />
                    <span className="absolute -bottom-0.5 -right-0.5 w-2 h-2 rounded-full border border-white"
                      style={{ background: dotColor(r) }} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="truncate text-sm">{r.nom}</p>
                    <p className="text-[11px] truncate" style={{ color: '#94a3b8' }}>
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

            {canManageStaff && (
              <Link to="/restaurants" onClick={() => setIsOpen(false)}
                className="nav-item text-xs mt-0.5"
                style={{ color: '#f97316' }}>
                <Users className="h-3.5 w-3.5" />
                Gérer le personnel
              </Link>
            )}

            <div className="mx-3 my-3 border-t" style={{ borderColor: '#eef2f7' }} />
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

      {/* User footer */}
      <div className="px-3 pb-4 shrink-0 border-t" style={{ borderColor: '#eef2f7' }}>
        <div className="relative mt-3">
          <button onClick={() => setShowUserMenu(v => !v)}
            className="flex items-center gap-3 w-full p-2.5 rounded-xl transition-colors"
            style={{ background: showUserMenu ? '#f8fafc' : 'transparent' }}
            onMouseEnter={e => { if (!showUserMenu) (e.currentTarget as HTMLButtonElement).style.background = '#f8fafc'; }}
            onMouseLeave={e => { if (!showUserMenu) (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}>
            {/* Avatar */}
            <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0 font-bold text-sm"
              style={{ background: 'linear-gradient(135deg,#f97316,#ea580c)', color: 'white' }}>
              {user?.name?.charAt(0).toUpperCase()}
            </div>
            <div className="flex-1 text-left min-w-0">
              <p className="text-sm font-semibold truncate" style={{ color: '#0f172a' }}>
                {user?.name}
              </p>
              <p className="text-[11px] truncate" style={{ color: '#94a3b8' }}>{user?.email}</p>
            </div>
            <ChevronDown className={`h-4 w-4 transition-transform shrink-0 ${showUserMenu ? 'rotate-180' : ''}`}
              style={{ color: '#94a3b8' }} />
          </button>

          {showUserMenu && (
            <div className="absolute bottom-full left-0 right-0 mb-2 rounded-xl shadow-2xl py-1 animate-fadeIn"
              style={{ background: 'white', border: '1px solid #e2e8f0' }}>
              <Link to="/profile" onClick={() => setShowUserMenu(false)}
                className="flex items-center gap-2.5 px-4 py-2.5 text-sm transition-colors"
                style={{ color: '#334155' }}
                onMouseEnter={e => (e.currentTarget as HTMLAnchorElement).style.background = '#f8fafc'}
                onMouseLeave={e => (e.currentTarget as HTMLAnchorElement).style.background = 'transparent'}>
                <User className="h-4 w-4" style={{ color: '#94a3b8' }} />
                Mon profil
              </Link>
              <div className="mx-3 my-1 border-t" style={{ borderColor: '#eef2f7' }} />
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
        style={{ background: 'white', color: '#0f172a', border: '1px solid #e2e8f0' }}
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
          background: 'white',
          borderRight: '1px solid #eef2f7',
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

