/**
 * useDrivers Hook
 *
 * Custom React hook for managing driver state and operations.
 *
 * Architecture:
 * - Manages local state (drivers, loading, error)
 * - Calls driverService methods (NOT API directly)
 * - Handles UI-specific concerns (loading states, pagination)
 */

import { useState, useEffect, useCallback } from 'react';
import { driverService } from '../services/driverService';
import type { Driver } from '../types';
import type { ApiResponse } from '../types/api';

interface UseDriversReturn {
  drivers: Driver[];
  loading: boolean;
  error: string | null;
  hasMore: boolean;
  loadDrivers: (append?: boolean) => Promise<void>;
  loadMore: () => void;
  refreshDrivers: () => Promise<void>;
}

/**
 * Custom hook for driver management
 */
export function useDrivers(): UseDriversReturn {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [offset, setOffset] = useState(0);
  const LIMIT = 20;

  const loadDrivers = useCallback(
    async (append = false) => {
      try {
        setLoading(true);
        setError(null);

        const currentOffset = append ? offset : 0;
        const result = await driverService.loadDrivers({
          limit: LIMIT,
          offset: currentOffset,
        });

        if (result.success && result.data) {
          const { drivers: newDrivers, hasNext } = result.data;

          setDrivers((prev) => (append ? [...prev, ...newDrivers] : newDrivers));
          setHasMore(hasNext);
          setOffset(currentOffset + newDrivers.length);
        } else {
          setError(result.error?.message || 'Failed to load drivers');
          if (!append) {
            setDrivers([]);
          }
        }
      } catch (err) {
        console.error('Unexpected error in loadDrivers:', err);
        setError('An unexpected error occurred');
        if (!append) {
          setDrivers([]);
        }
      } finally {
        setLoading(false);
      }
    },
    [offset]
  );

  const loadMore = useCallback(() => {
    if (!loading && hasMore) {
      loadDrivers(true);
    }
  }, [loading, hasMore, loadDrivers]);

  const refreshDrivers = useCallback(async () => {
    setOffset(0);
    await loadDrivers(false);
  }, [loadDrivers]);

  // NOTE: Drivers do NOT auto-load on mount
  // Each page decides when to call loadDrivers()

  return {
    drivers,
    loading,
    error,
    hasMore,
    loadDrivers,
    loadMore,
    refreshDrivers,
  };
}
