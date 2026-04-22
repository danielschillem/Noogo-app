import { useState, useEffect, useCallback } from 'react';

/**
 * Persists state in localStorage with automatic JSON serialisation.
 * Falls back gracefully if localStorage is unavailable (SSR / private mode).
 */
export function useLocalStorage<T>(key: string, initialValue: T) {
    const readValue = useCallback((): T => {
        try {
            const item = window.localStorage.getItem(key);
            return item ? (JSON.parse(item) as T) : initialValue;
        } catch {
            return initialValue;
        }
    }, [key, initialValue]);

    const [storedValue, setStoredValue] = useState<T>(readValue);

    const setValue = useCallback((value: T | ((prev: T) => T)) => {
        try {
            const newValue = value instanceof Function ? value(storedValue) : value;
            window.localStorage.setItem(key, JSON.stringify(newValue));
            setStoredValue(newValue);
        } catch { /* ignore */ }
    }, [key, storedValue]);

    const removeValue = useCallback(() => {
        try {
            window.localStorage.removeItem(key);
            setStoredValue(initialValue);
        } catch { /* ignore */ }
    }, [key, initialValue]);

    // Sync across tabs
    useEffect(() => {
        const handler = (e: StorageEvent) => {
            if (e.key === key) setStoredValue(readValue());
        };
        window.addEventListener('storage', handler);
        return () => window.removeEventListener('storage', handler);
    }, [key, readValue]);

    return [storedValue, setValue, removeValue] as const;
}
