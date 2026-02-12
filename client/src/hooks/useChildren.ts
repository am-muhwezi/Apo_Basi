/**
 * useChildren Hook
 *
 * Custom React hook for managing children state and operations.
 *
 * Architecture:
 * - Manages local state (children, loading, error)
 * - Calls childService methods (NOT API directly)
 * - Handles UI-specific concerns (loading states, pagination)
 */

import { useState, useRef, useCallback } from 'react';
import { childService } from '../services/childService';
import type { Child } from '../types';

interface UseChildrenReturn {
  children: Child[];
  loading: boolean;
  error: string | null;
  hasMore: boolean;
  loadChildren: (append?: boolean) => Promise<void>;
  loadMore: () => void;
  refreshChildren: () => Promise<void>;
}

/**
 * Custom hook for children management
 */
export function useChildren(): UseChildrenReturn {
  const [children, setChildren] = useState<Child[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  // Use a ref for offset to avoid stale closures in useCallback
  const offsetRef = useRef(0);
  const loadingRef = useRef(false);
  const LIMIT = 20;

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
      });

      if (result.success && result.data) {
        const { children: newChildren, hasNext } = result.data;

        setChildren((prev) => (append ? [...prev, ...newChildren] : newChildren));
        setHasMore(hasNext);
        offsetRef.current = currentOffset + newChildren.length;
      } else {
        setError(result.error?.message || 'Failed to load children');
        if (!append) {
          setChildren([]);
        }
      }
    } catch (err) {
      setError('An unexpected error occurred');
      if (!append) {
        setChildren([]);
      }
    } finally {
      loadingRef.current = false;
      setLoading(false);
    }
  }, []); // No deps — uses refs instead of captured state

  const loadMore = useCallback(() => {
    if (!loadingRef.current && hasMore) {
      loadChildren(true);
    }
  }, [hasMore, loadChildren]);

  const refreshChildren = useCallback(async () => {
    offsetRef.current = 0;
    await loadChildren(false);
  }, [loadChildren]);

  // NOTE: Children do NOT auto-load on mount
  // Each page decides when to call loadChildren()

  return {
    children,
    loading,
    error,
    hasMore,
    loadChildren,
    loadMore,
    refreshChildren,
  };
}
