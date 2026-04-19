import { useQuery } from '@tanstack/react-query';
import { restaurantsApi, dashboardApi } from '../services/api';
import type { Restaurant } from '../types';

/**
 * Shared hook for the restaurants list.
 * Uses React Query to deduplicate concurrent calls
 * (Sidebar, DashboardPage, NotificationContext all need this).
 * staleTime = 30s → only one real HTTP call per 30s window.
 */
export function useRestaurants(params?: Record<string, unknown>) {
  return useQuery<Restaurant[]>({
    queryKey: ['restaurants', params],
    queryFn: async () => {
      const res = await restaurantsApi.getAll(params);
      return res.data.data?.data ?? res.data.data ?? [];
    },
    staleTime: 30_000,
  });
}

/**
 * Shared hook for dashboard stats.
 * Prevents Sidebar + DashboardPage from double-fetching.
 */
export function useDashboardStats() {
  return useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const res = await dashboardApi.getStats();
      return res.data.data;
    },
    staleTime: 25_000,
    refetchInterval: 30_000,
  });
}

/**
 * Lightweight pending count for the sidebar badge.
 */
export function usePendingCount() {
  return useQuery({
    queryKey: ['pending-count'],
    queryFn: async () => {
      const res = await dashboardApi.getPendingCount();
      return res.data.data?.pending_orders ?? 0;
    },
    staleTime: 25_000,
    refetchInterval: 30_000,
  });
}
