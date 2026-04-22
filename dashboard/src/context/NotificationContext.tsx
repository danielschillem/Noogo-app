import { createContext, useContext, useState, useCallback, useEffect, useRef, type ReactNode } from 'react';
import type { Channel } from 'pusher-js';
import { useAuth } from './AuthContext';
import { myRestaurantsApi, restaurantsApi } from '../services/api';
import { getPusher } from '../hooks/usePusher';

// ── Types ────────────────────────────────────────────────────────────────────

export interface AppNotification {
    id: string;
    type: 'order_created' | 'order_updated';
    restaurantId: number;
    restaurantName: string;
    orderId: number;
    orderStatus: string;
    customerName?: string;
    tableNumber?: string;
    amount: number;
    message: string;
    isRead: boolean;
    createdAt: Date;
}

interface NotificationContextType {
    notifications: AppNotification[];
    unreadCount: number;
    markAsRead: (id: string) => void;
    markAllAsRead: () => void;
    clearAll: () => void;
    toasts: AppNotification[];
    dismissToast: (id: string) => void;
}

interface OrderEventPayload {
    id: number;
    status: string;
    total_amount?: number;
    table_number?: string;
    customer_name?: string;
}

// ── Constants ────────────────────────────────────────────────────────────────

const MAX_NOTIFICATIONS = 50;
const TOAST_DURATION_MS = 6000;

const STATUS_LABELS: Record<string, string> = {
    pending: 'en attente',
    confirmed: 'confirmée',
    preparing: 'en préparation',
    ready: 'prête',
    delivered: 'livrée',
    completed: 'terminée',
    cancelled: 'annulée',
};

// ── Context ──────────────────────────────────────────────────────────────────

const NotificationContext = createContext<NotificationContextType | null>(null);

export function useNotifications() {
    const ctx = useContext(NotificationContext);
    if (!ctx) throw new Error('useNotifications must be used within NotificationProvider');
    return ctx;
}

// ── Provider ─────────────────────────────────────────────────────────────────

export function NotificationProvider({ children }: { children: ReactNode }) {
    const { user, isAuthenticated } = useAuth();
    const [notifications, setNotifications] = useState<AppNotification[]>([]);
    const [toasts, setToasts] = useState<AppNotification[]>([]);
    const channelsRef = useRef<Map<string, Channel>>(new Map());
    const toastTimersRef = useRef<Map<string, ReturnType<typeof setTimeout>>>(new Map());

    const dismissToast = useCallback((id: string) => {
        setToasts(prev => prev.filter(t => t.id !== id));
        const timer = toastTimersRef.current.get(id);
        if (timer) { clearTimeout(timer); toastTimersRef.current.delete(id); }
    }, []);

    const addNotification = useCallback((notif: AppNotification) => {
        setNotifications(prev => [notif, ...prev].slice(0, MAX_NOTIFICATIONS));
        setToasts(prev => [...prev, notif]);

        const timer = setTimeout(() => dismissToast(notif.id), TOAST_DURATION_MS);
        toastTimersRef.current.set(notif.id, timer);
    }, [dismissToast]);

    const markAsRead = useCallback((id: string) => {
        setNotifications(prev => prev.map(n => n.id === id ? { ...n, isRead: true } : n));
    }, []);

    const markAllAsRead = useCallback(() => {
        setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
    }, []);

    const clearAll = useCallback(() => {
        setNotifications([]);
    }, []);

    // ── Pusher subscription ──────────────────────────────────────────────────

    const subscribeToRestaurant = useCallback((restaurantId: number, restaurantName: string) => {
        const pusher = getPusher();
        if (!pusher) return;

        const channelName = `private-restaurant.${restaurantId}`;
        if (channelsRef.current.has(channelName)) return;

        const channel = pusher.subscribe(channelName);
        channelsRef.current.set(channelName, channel);

        const handleEvent = (type: AppNotification['type']) => (data: unknown) => {
            const payload = data as OrderEventPayload;
            const id = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
            const statusLabel = STATUS_LABELS[payload.status] ?? payload.status;

            const message = type === 'order_created'
                ? `Nouvelle commande #${payload.id}${payload.table_number ? ` · Table ${payload.table_number}` : ''}`
                : `Commande #${payload.id} ${statusLabel}`;

            addNotification({
                id,
                type,
                restaurantId,
                restaurantName,
                orderId: payload.id,
                orderStatus: payload.status,
                customerName: payload.customer_name,
                tableNumber: payload.table_number,
                amount: payload.total_amount ?? 0,
                message,
                isRead: false,
                createdAt: new Date(),
            });
        };

        channel.bind('order.created', handleEvent('order_created'));
        channel.bind('order.updated', handleEvent('order_updated'));
    }, [addNotification]);

    const unsubscribeAll = useCallback(() => {
        const pusher = getPusher();
        channelsRef.current.forEach((_, channelName) => {
            pusher?.unsubscribe(channelName);
        });
        channelsRef.current.clear();
    }, []);

    useEffect(() => {
        if (!isAuthenticated || !user) {
            unsubscribeAll();
            return;
        }

        const fetchAndSubscribe = async () => {
            try {
                if (user.is_admin) {
                    const res = await restaurantsApi.getAll({ per_page: 50 });
                    const list = res.data.data?.data ?? res.data.data ?? [];
                    for (const r of list) subscribeToRestaurant(r.id, r.nom);
                } else {
                    const res = await myRestaurantsApi.get();
                    const list = res.data.data ?? [];
                    for (const r of list) subscribeToRestaurant(r.id, r.nom);
                }
            } catch {
                // Silently ignore — Pusher is optional (falls back to polling)
            }
        };

        fetchAndSubscribe();
        return unsubscribeAll;
    }, [isAuthenticated, user, subscribeToRestaurant, unsubscribeAll]);

    // Cleanup timers on unmount
    useEffect(() => {
        return () => {
            toastTimersRef.current.forEach(timer => clearTimeout(timer));
        };
    }, []);

    const unreadCount = notifications.filter(n => !n.isRead).length;

    return (
        <NotificationContext.Provider value={{
            notifications, unreadCount,
            markAsRead, markAllAsRead, clearAll,
            toasts, dismissToast,
        }}>
            {children}
        </NotificationContext.Provider>
    );
}
