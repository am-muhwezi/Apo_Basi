import { useState, useRef, useCallback, useEffect } from 'react';
import { childService } from '../services/childService';
import type { Child } from '../types';

interface UseChildrenParams {
  search?: string;
  ordering?: string;
}

interface UseChildrenReturn {
  children: Child[];
  loading: boolean;
  error: string | null;
  hasMore: boolean;
  totalCount: number;
  loadChildren: (append?: boolean) => Promise<void>;
  loadMore: () => void;
  refreshChildren: () => Promise<void>;
}

const LIMIT = 20;

export function useChildren(params?: UseChildrenParams): UseChildrenReturn {
  const [children, setChildren] = useState<Child[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const offsetRef = useRef(0);
  const loadingRef = useRef(false);
  const searchRef = useRef(params?.search ?? '');
  const orderingRef = useRef(params?.ordering ?? '');

  const loadChildren = useCallback(async (append = false) => {
    if (loadingRef.current) return;
    try {
      loadingRef.current = true;
      setLoading(true);
      setError(null);

      const currentOffset = append ? offsetRef.current : 0;
      const result = await childService.loadChildren({
        limit: LIMIT,
        offset: currentOffset,
        search: searchRef.current || undefined,
        ordering: orderingRef.current || undefined,
      });

      if (result.success && result.data) {
        const { children: newChildren, hasNext, count } = result.data;
        setChildren((prev) => (append ? [...prev, ...newChildren] : newChildren));
        setHasMore(hasNext);
        setTotalCount(count ?? 0);
        offsetRef.current = currentOffset + newChildren.length;
      } else {
        setError(result.error?.message || 'Failed to load children');
        if (!append) setChildren([]);
      }
    } catch {
      setError('An unexpected error occurred');
      if (!append) setChildren([]);
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
      loadChildren(false);
    }
  }, [params?.search, params?.ordering, loadChildren]);

  const loadMore = useCallback(() => {
    if (!loadingRef.current && hasMore) {
      loadChildren(true);
    }
  }, [hasMore, loadChildren]);

  const refreshChildren = useCallback(async () => {
    offsetRef.current = 0;
    await loadChildren(false);
  }, [loadChildren]);

  return { children, loading, error, hasMore, totalCount, loadChildren, loadMore, refreshChildren };
}
