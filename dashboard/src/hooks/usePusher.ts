import { useEffect, useRef } from 'react';
import Pusher, { type Channel } from 'pusher-js';

const PUSHER_KEY = import.meta.env.VITE_PUSHER_KEY ?? '';
const PUSHER_CLUSTER = import.meta.env.VITE_PUSHER_CLUSTER ?? 'eu';

let pusherInstance: Pusher | null = null;

function getPusher(): Pusher | null {
    if (!PUSHER_KEY) return null;
    if (!pusherInstance) {
        pusherInstance = new Pusher(PUSHER_KEY, {
            cluster: PUSHER_CLUSTER,
        });
    }
    return pusherInstance;
}

type PusherEventCallback = (data: unknown) => void;

/**
 * Hook Pusher (D11) — souscrit à un canal public et écoute des événements.
 *
 * @param channelName - ex. "restaurant.42"
 * @param events      - map event → callback
 *
 * USAGE:
 *   usePusher(`restaurant.${restaurantId}`, {
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
