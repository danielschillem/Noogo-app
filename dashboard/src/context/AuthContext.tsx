import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react';
import type { AuthState, MyRestaurant } from '../types';
import { authApi, myRestaurantsApi } from '../services/api';
import { useLocalStorage } from '../hooks/useLocalStorage';

interface AuthContextType extends AuthState {
  lockedRestaurantId: number | null;
  /** Tous les restaurants accessibles (owned + staff). Vide pour les admins. */
  myRestaurants: MyRestaurant[];
  /** Restaurant actuellement sélectionné dans les pages globales (persisté). */
  selectedRestaurantId: number | null;
  setSelectedRestaurantId: (id: number | null) => void;
  /** Recharge la liste des restaurants (utile après création/suppression). */
  refreshMyRestaurants: () => Promise<void>;
  login: (email: string, password: string) => Promise<void>;
  loginForRestaurant: (email: string, password: string, restaurantId: number) => Promise<void>;
  logout: () => Promise<void>;
  register: (data: { name: string; email: string; password: string; password_confirmation: string }) => Promise<void>;
  updateProfile: (data: { name?: string; email?: string }) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

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
          // Charger les restaurants accessibles dès que l'auth est confirmée
          if (!user.is_admin) refreshMyRestaurants();
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

    if (!user.is_admin) refreshMyRestaurants();
  };

  // Login depuis la page d'un restaurant (/r/:id/login)
  // Vérifie que l'utilisateur a bien accès à ce restaurant.
  // Lance une erreur si l'accès est refusé (ex: staff d'un autre resto).
  const loginForRestaurant = async (email: string, password: string, restaurantId: number) => {
    const response = await authApi.login(email, password);
    const { user, token } = response.data.data;

    // Les super admins et admins globaux n'ont pas besoin de vérification
    if (user.is_admin) {
      sessionStorage.setItem('auth_token', token);
      sessionStorage.setItem('user', JSON.stringify(user));
      removeLockedRestaurantId();
    }

    // Pour les non-admins : vérifier qu'ils ont accès à ce restaurant
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
      setLockedRestaurantId(restaurantId);
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

  return (
    <AuthContext.Provider value={{
      ...state,
      lockedRestaurantId,
      myRestaurants,
      selectedRestaurantId,
      setSelectedRestaurantId,
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
