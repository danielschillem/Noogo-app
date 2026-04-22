import { useEffect, useRef } from 'react';
import Pusher, { type Channel } from 'pusher-js';

const PUSHER_KEY = import.meta.env.VITE_PUSHER_KEY ?? '';
const PUSHER_CLUSTER = import.meta.env.VITE_PUSHER_CLUSTER ?? 'eu';
const API_BASE = (import.meta.env.VITE_API_URL || 'https://noogo-e5ygx.ondigitalocean.app/api').replace(/\/api$/, '');

let pusherInstance: Pusher | null = null;

export function getPusher(): Pusher | null {
    if (!PUSHER_KEY) return null;
    if (!pusherInstance) {
        pusherInstance = new Pusher(PUSHER_KEY, {
            cluster: PUSHER_CLUSTER,
            // Autorisation des canaux privés : lit le token JWT à chaque tentative
            authorizer: (channel) => ({
                authorize: (socketId, callback) => {
                    const token = localStorage.getItem('auth_token') ?? '';
                    fetch(`${API_BASE}/broadcasting/auth`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            Authorization: `Bearer ${token}`,
                        },
                        body: JSON.stringify({
                            socket_id: socketId,
                            channel_name: channel.name,
                        }),
                    })
                        .then(r => r.json())
                        .then((data: unknown) => callback(null, data as Parameters<typeof callback>[1]))
                        .catch(err => callback(new Error(String(err)), null));
                },
            }),
        });
    }
    return pusherInstance;
}

type PusherEventCallback = (data: unknown) => void;

/**
 * Hook Pusher (D11) — souscrit à un canal (public ou privé) et écoute des événements.
 *
 * @param channelName - ex. "private-restaurant.42" ou "delivery.123"
 * @param events      - map event → callback
 *
 * USAGE:
 *   usePusher(`private-restaurant.${restaurantId}`, {
 *     'order.created': (data) => setOrders(prev => [data, ...prev]),
 *     'order.updated': (data) => setOrders(prev => prev.map(o => o.id === data.id ? data : o)),
 *   });
 */
export function usePusher(
    channelName: string | null | undefined,
    events: Record<string, PusherEventCallback>,
) {
    const channelRef = useRef<Channel | null>(null);
    const eventsRef = useRef(events);
    eventsRef.current = events;

    useEffect(() => {
        if (!channelName) return;

        const pusher = getPusher();
        if (!pusher) return; // VITE_PUSHER_KEY absent → polling seul

        const channel = pusher.subscribe(channelName);
        channelRef.current = channel;

        for (const eventName of Object.keys(eventsRef.current)) {
            channel.bind(eventName, (data: unknown) => {
                eventsRef.current[eventName]?.(data);
            });
        }

        return () => {
            for (const eventName of Object.keys(eventsRef.current)) {
                channel.unbind(eventName);
            }
            pusher.unsubscribe(channelName);
            channelRef.current = null;
        };
    }, [channelName]);
}
