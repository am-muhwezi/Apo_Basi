import { useState, useRef, useCallback, useEffect } from 'react';
import { driverService } from '../services/driverService';
import type { Driver } from '../types';
import type { ApiResponse } from '../types/api';

interface UseDriversParams {
  search?: string;
}

interface UseDriversReturn {
  drivers: Driver[];
  loading: boolean;
  error: string | null;
  hasMore: boolean;
  totalCount: number;
  loadDrivers: (append?: boolean) => Promise<void>;
  loadMore: () => void;
  refreshDrivers: () => Promise<void>;
}

const LIMIT = 20;

export function useDrivers(params?: UseDriversParams): UseDriversReturn {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const offsetRef = useRef(0);
  const loadingRef = useRef(false);
  const searchRef = useRef(params?.search ?? '');

  const loadDrivers = useCallback(async (append = false) => {
    if (loadingRef.current) return;
    try {
      loadingRef.current = true;
      setLoading(true);
      setError(null);

      const currentOffset = append ? offsetRef.current : 0;
      const result = await driverService.loadDrivers({
        limit: LIMIT,
        offset: currentOffset,
        search: searchRef.current || undefined,
      });

      if (result.success && result.data) {
        const { drivers: newDrivers, hasNext, count } = result.data;
        setDrivers((prev) => (append ? [...prev, ...newDrivers] : newDrivers));
        setHasMore(hasNext);
        setTotalCount(count ?? 0);
        offsetRef.current = currentOffset + newDrivers.length;
      } else {
        setError(result.error?.message || 'Failed to load drivers');
        if (!append) setDrivers([]);
      }
    } catch {
      setError('An unexpected error occurred');
      if (!append) setDrivers([]);
    } finally {
      loadingRef.current = false;
      setLoading(false);
    }
  }, []); // No deps — uses refs

  // Re-fetch when search changes
  useEffect(() => {
    const newSearch = params?.search ?? '';
    if (searchRef.current !== newSearch) {
      searchRef.current = newSearch;
      offsetRef.current = 0;
      loadDrivers(false);
    }
  }, [params?.search, loadDrivers]);

  const loadMore = useCallback(() => {
    if (!loadingRef.current && hasMore) {
      loadDrivers(true);
    }
  }, [hasMore, loadDrivers]);

  const refreshDrivers = useCallback(async () => {
    offsetRef.current = 0;
    await loadDrivers(false);
  }, [loadDrivers]);

  return { drivers, loading, error, hasMore, totalCount, loadDrivers, loadMore, refreshDrivers };
}
