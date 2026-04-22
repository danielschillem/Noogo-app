import { useState, useEffect } from 'react';

/**
 * Delays updating the returned value until `delay` ms after the last change.
 * Useful for search inputs to avoid firing on every keystroke.
 */
export function useDebounce<T>(value: T, delay = 300): T {
    const [debouncedValue, setDebouncedValue] = useState<T>(value);

    useEffect(() => {
        const id = setTimeout(() => setDebouncedValue(value), delay);
        return () => clearTimeout(id);
    }, [value, delay]);

    return debouncedValue;
}
