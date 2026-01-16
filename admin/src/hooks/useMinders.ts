/**
 * useMinders Hook
 *
 * Custom React hook for managing bus minders state and operations.
 *
 * Architecture:
 * - Manages local state (minders, loading, error)
 * - Calls busMinderService methods (NOT API directly)
 * - Handles UI-specific concerns (loading states, pagination)
 */

import { useState, useEffect, useCallback } from 'react';
import { busMinderService } from '../services/busMinderService';
import type { Minder } from '../types';

interface UseMindersReturn {
  minders: Minder[];
  loading: boolean;
  error: string | null;
  hasMore: boolean;
  loadMinders: (append?: boolean) => Promise<void>;
  loadMore: () => void;
  refreshMinders: () => Promise<void>;
}

/**
 * Custom hook for bus minders management
 */
export function useMinders(): UseMindersReturn {
  const [minders, setMinders] = useState<Minder[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [offset, setOffset] = useState(0);
  const LIMIT = 20;

  const loadMinders = useCallback(
    async (append = false) => {
      try {
        setLoading(true);
        setError(null);

        const currentOffset = append ? offset : 0;
        const result = await busMinderService.loadBusMinders({
          limit: LIMIT,
          offset: currentOffset,
        });

        if (result.success && result.data) {
          const { minders: newMinders, hasNext } = result.data;

          setMinders((prev) => (append ? [...prev, ...newMinders] : newMinders));
          setHasMore(hasNext);
          setOffset(currentOffset + newMinders.length);
        } else {
          setError(result.error?.message || 'Failed to load minders');
          if (!append) {
            setMinders([]);
          }
        }
      } catch (err) {
        setError('An unexpected error occurred');
        if (!append) {
          setMinders([]);
        }
      } finally {
        setLoading(false);
      }
    },
    [offset]
  );

  const loadMore = useCallback(() => {
    if (!loading && hasMore) {
      loadMinders(true);
    }
  }, [loading, hasMore, loadMinders]);

  const refreshMinders = useCallback(async () => {
    setOffset(0);
    await loadMinders(false);
  }, [loadMinders]);

  // NOTE: Minders do NOT auto-load on mount
  // Each page decides when to call loadMinders()

  return {
    minders,
    loading,
    error,
    hasMore,
    loadMinders,
    loadMore,
    refreshMinders,
  };
}
