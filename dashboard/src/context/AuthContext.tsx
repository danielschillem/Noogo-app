import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react';
import type { AuthState, MyRestaurant } from '../types';
import { authApi, myRestaurantsApi } from '../services/api';
import { useLocalStorage } from '../hooks/useLocalStorage';

interface AuthContextType extends AuthState {
  isSuperAdmin: boolean;
  isRestaurantAdmin: boolean;
  lockedRestaurantId: number | null;
  /** Tous les restaurants accessibles (owned + staff). Vide pour les admins. */
  myRestaurants: MyRestaurant[];
  /** Restaurant actuellement sélectionné dans les pages globales (persisté). */
  selectedRestaurantId: number | null;
  setSelectedRestaurantId: (id: number | null) => void;
  getRestaurantAccess: (restaurantId?: number | null) => MyRestaurant | null;
  hasRestaurantPermission: (permission: string, restaurantId?: number | null) => boolean;
  isOwnerOrManager: (restaurantId?: number | null) => boolean;
  /** Recharge la liste des restaurants (utile après création/suppression). */
  refreshMyRestaurants: () => Promise<void>;
  login: (email: string, password: string) => Promise<void>;
  loginForRestaurant: (email: string, password: string, restaurantId: number) => Promise<void>;
  logout: () => Promise<void>;
  register: (data: { name: string; email: string; password: string; password_confirmation: string }) => Promise<void>;
  updateProfile: (data: { name?: string; email?: string }) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

function isSuperAdminUser(user: { is_admin?: boolean; role?: string | null } | null | undefined): boolean {
  return !!user?.is_admin && user?.role === 'super_admin';
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({
    user: null,
    token: sessionStorage.getItem('auth_token') ?? localStorage.getItem('auth_token'),
    isAuthenticated: false,
    isLoading: true,
  });
  const [lockedRestaurantId, setLockedRestaurantId, removeLockedRestaurantId] = useLocalStorage<number | null>('locked_restaurant_id', null);
  const [myRestaurants, setMyRestaurants] = useState<MyRestaurant[]>([]);
  const [selectedRestaurantId, setSelectedRestaurantIdRaw, removeSelectedRestaurantId] = useLocalStorage<number | null>('selected_restaurant_id', null);
  const isSuperAdmin = isSuperAdminUser(state.user);
  const isRestaurantAdmin = !!state.user?.is_admin && state.user?.role === 'admin';

  // Wrap setter: when explicitly choosing a restaurant, persist it
  const setSelectedRestaurantId = useCallback((id: number | null) => {
    if (id === null) removeSelectedRestaurantId();
    else setSelectedRestaurantIdRaw(id);
  }, [setSelectedRestaurantIdRaw, removeSelectedRestaurantId]);

  const refreshMyRestaurants = useCallback(async () => {
    try {
      const res = await myRestaurantsApi.get();
      const list: MyRestaurant[] = res.data.data ?? [];
      setMyRestaurants(list);
      // Auto-select first if nothing persisted or persisted id no longer accessible
      setSelectedRestaurantIdRaw(prev => {
        const ids = list.map(r => r.id);
        if (prev && ids.includes(prev)) return prev;
        return list[0]?.id ?? null;
      });
    } catch { /* silently ignore */ }
  }, [setSelectedRestaurantIdRaw]);

  useEffect(() => {
    const initAuth = async () => {
      const token = sessionStorage.getItem('auth_token') ?? localStorage.getItem('auth_token');
      const storedUser = sessionStorage.getItem('user') ?? localStorage.getItem('user');

      if (token && storedUser) {
        try {
          const response = await authApi.me();
          const user = response.data.data;
          setState({
            user,
            token,
            isAuthenticated: true,
            isLoading: false,
          });
          // Charger les restaurants pour tous les acteurs restaurant (admin resto + staff).
          if (!isSuperAdminUser(user)) refreshMyRestaurants();
        } catch {
          sessionStorage.removeItem('auth_token');
          sessionStorage.removeItem('user');
          localStorage.removeItem('auth_token');
          localStorage.removeItem('user');
          setState({
            user: null,
            token: null,
            isAuthenticated: false,
            isLoading: false,
          });
        }
      } else {
        setState(prev => ({ ...prev, isLoading: false }));
      }
    };

    initAuth();
  }, [refreshMyRestaurants]);

  const login = async (email: string, password: string) => {
    const response = await authApi.login(email, password);
    const { user, token } = response.data.data;

    sessionStorage.setItem('auth_token', token);
    sessionStorage.setItem('user', JSON.stringify(user));
    // Login global : aucun restaurant verrouillé
    removeLockedRestaurantId();
    setLockedRestaurantId(null);

    setState({
      user,
      token,
      isAuthenticated: true,
      isLoading: false,
    });

    if (!isSuperAdminUser(user)) refreshMyRestaurants();
  };

  // Login depuis la page d'un restaurant (/r/:id/login)
  // Vérifie que l'utilisateur a bien accès à ce restaurant.
  // Lance une erreur si l'accès est refusé (ex: staff d'un autre resto).
  const loginForRestaurant = async (email: string, password: string, restaurantId: number) => {
    const response = await authApi.login(email, password);
    const { user, token } = response.data.data;

    // Super admin plateforme: pas de scope restaurant
    if (isSuperAdminUser(user)) {
      sessionStorage.setItem('auth_token', token);
      sessionStorage.setItem('user', JSON.stringify(user));
      removeLockedRestaurantId();
      setLockedRestaurantId(null);
      setState({ user, token, isAuthenticated: true, isLoading: false });
      return;
    }

    // Tous les acteurs restaurant (admin resto + staff):
    // vérifier qu'ils ont accès au restaurant sélectionné.
    // On doit d'abord stocker le token pour que l'API /auth/my-restaurants fonctionne
    sessionStorage.setItem('auth_token', token);
    try {
      const myRestosResp = await myRestaurantsApi.get();
      const myRestos: { id: number }[] = myRestosResp.data.data ?? [];
      const hasAccess = myRestos.some(r => r.id === restaurantId);

      if (!hasAccess) {
        // Pas accès à ce restaurant → déconnexion immédiate
        sessionStorage.removeItem('auth_token');
        sessionStorage.removeItem('user');
        localStorage.removeItem('auth_token');
        localStorage.removeItem('user');
        throw new Error('Vous n\'avez pas accès à ce restaurant.');
      }

      sessionStorage.setItem('user', JSON.stringify(user));

      // Admin restaurant: multi-restaurants (pas verrouillé), mais on mémorise le resto choisi.
      if (user.is_admin && user.role === 'admin') {
        removeLockedRestaurantId();
        setLockedRestaurantId(null);
        setSelectedRestaurantIdRaw(restaurantId);
      } else {
        // Staff/cashier/waiter: session verrouillée sur un seul restaurant.
        setLockedRestaurantId(restaurantId);
      }

      setMyRestaurants(myRestos as MyRestaurant[]);
      setState({ user, token, isAuthenticated: true, isLoading: false });
    } catch (err: unknown) {
      // Nettoyage si erreur API
      sessionStorage.removeItem('auth_token');
      sessionStorage.removeItem('user');
      localStorage.removeItem('auth_token');
      localStorage.removeItem('user');
      throw err;
    }
  };

  const logout = async () => {
    try {
      await authApi.logout();
    } catch {
      // Ignore errors
    }

    sessionStorage.removeItem('auth_token');
    sessionStorage.removeItem('user');
    localStorage.removeItem('auth_token');
    localStorage.removeItem('user');
    removeLockedRestaurantId();
    setLockedRestaurantId(null);
    removeSelectedRestaurantId();
    setMyRestaurants([]);

    setState({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,
    });
  };

  const register = async (data: { name: string; email: string; password: string; password_confirmation: string }) => {
    const response = await authApi.register(data);
    const { user, token } = response.data.data;

    sessionStorage.setItem('auth_token', token);
    sessionStorage.setItem('user', JSON.stringify(user));

    setState({
      user,
      token,
      isAuthenticated: true,
      isLoading: false,
    });
  };

  const updateProfile = async (data: { name?: string; email?: string }) => {
    const response = await authApi.updateUser(data);
    const user = response.data.user;
    sessionStorage.setItem('user', JSON.stringify(user));
    localStorage.removeItem('user'); // migrer l'ancienne clé si présente
    setState(prev => ({ ...prev, user }));
  };

  const getRestaurantAccess = useCallback((restaurantId?: number | null): MyRestaurant | null => {
    const targetId = restaurantId ?? lockedRestaurantId ?? selectedRestaurantId ?? myRestaurants[0]?.id ?? null;
    if (!targetId) return null;
    return myRestaurants.find(r => r.id === targetId) ?? null;
  }, [lockedRestaurantId, selectedRestaurantId, myRestaurants]);

  const isOwnerOrManager = useCallback((restaurantId?: number | null): boolean => {
    if (isSuperAdmin || isRestaurantAdmin) return true;
    const access = getRestaurantAccess(restaurantId);
    return access?.role === 'owner' || access?.role === 'manager';
  }, [isSuperAdmin, isRestaurantAdmin, getRestaurantAccess]);

  const hasRestaurantPermission = useCallback((permission: string, restaurantId?: number | null): boolean => {
    if (isSuperAdmin || isRestaurantAdmin) return true;
    if (isOwnerOrManager(restaurantId)) return true;
    const access = getRestaurantAccess(restaurantId);
    return access?.permissions?.includes(permission) ?? false;
  }, [isSuperAdmin, isRestaurantAdmin, isOwnerOrManager, getRestaurantAccess]);

  return (
    <AuthContext.Provider value={{
      ...state,
      isSuperAdmin,
      isRestaurantAdmin,
      lockedRestaurantId,
      myRestaurants,
      selectedRestaurantId,
      setSelectedRestaurantId,
      getRestaurantAccess,
      hasRestaurantPermission,
      isOwnerOrManager,
      refreshMyRestaurants,
      login,
      loginForRestaurant,
      logout,
      register,
      updateProfile,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
