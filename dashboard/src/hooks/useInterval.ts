import { useEffect, useRef } from 'react';

/**
 * Runs a callback on a fixed interval, cleaning up automatically on unmount.
 * Pass `delay = null` to pause without changing the callback.
 */
export function useInterval(callback: () => void, delay: number | null) {
    const savedCallback = useRef(callback);

    // Always keep the ref pointing at the latest callback
    useEffect(() => {
        savedCallback.current = callback;
    }, [callback]);

    useEffect(() => {
        if (delay === null) return;
        const id = setInterval(() => savedCallback.current(), delay);
        return () => clearInterval(id);
    }, [delay]);
}
