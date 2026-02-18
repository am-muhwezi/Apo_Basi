import { useState, useRef, useCallback, useEffect } from 'react';
import { busMinderService } from '../services/busMinderService';
import type { Minder } from '../types';

interface UseMindersParams {
  search?: string;
  ordering?: string;
}

interface UseMindersReturn {
  minders: Minder[];
  loading: boolean;
  error: string | null;
  hasMore: boolean;
  totalCount: number;
  loadMinders: (append?: boolean) => Promise<void>;
  loadMore: () => void;
  refreshMinders: () => Promise<void>;
}

const LIMIT = 20;

export function useMinders(params?: UseMindersParams): UseMindersReturn {
  const [minders, setMinders] = useState<Minder[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const offsetRef = useRef(0);
  const loadingRef = useRef(false);
  const searchRef = useRef(params?.search ?? '');
  const orderingRef = useRef(params?.ordering ?? '');

  const loadMinders = useCallback(async (append = false) => {
    if (loadingRef.current) return;
    try {
      loadingRef.current = true;
      setLoading(true);
      setError(null);

      const currentOffset = append ? offsetRef.current : 0;
      const result = await busMinderService.loadBusMinders({
        limit: LIMIT,
        offset: currentOffset,
        search: searchRef.current || undefined,
        ordering: orderingRef.current || undefined,
      });

      if (result.success && result.data) {
        const { minders: newMinders, hasNext, count } = result.data;
        setMinders((prev) => (append ? [...prev, ...newMinders] : newMinders));
        setHasMore(hasNext);
        setTotalCount(count ?? 0);
        offsetRef.current = currentOffset + newMinders.length;
      } else {
        setError(result.error?.message || 'Failed to load minders');
        if (!append) setMinders([]);
      }
    } catch {
      setError('An unexpected error occurred');
      if (!append) setMinders([]);
    } finally {
      loadingRef.current = false;
      setLoading(false);
    }
  }, []); // No deps — uses refs

  // Re-fetch when search or ordering changes
  useEffect(() => {
    const newSearch = params?.search ?? '';
    const newOrdering = params?.ordering ?? '';
    if (searchRef.current !== newSearch || orderingRef.current !== newOrdering) {
      searchRef.current = newSearch;
      orderingRef.current = newOrdering;
      offsetRef.current = 0;
      loadMinders(false);
    }
  }, [params?.search, params?.ordering, loadMinders]);

  const loadMore = useCallback(() => {
    if (!loadingRef.current && hasMore) {
      loadMinders(true);
    }
  }, [hasMore, loadMinders]);

  const refreshMinders = useCallback(async () => {
    offsetRef.current = 0;
    await loadMinders(false);
  }, [loadMinders]);

  return { minders, loading, error, hasMore, totalCount, loadMinders, loadMore, refreshMinders };
}
