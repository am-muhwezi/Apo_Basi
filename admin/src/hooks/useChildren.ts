import { useState, useEffect } from 'react';
import { getChildren } from '../services/childApi';
import type { Child } from '../types';

export function useChildren() {
  const [children, setChildren] = useState<Child[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);

  useEffect(() => {
    loadChildren();
  }, []);

  const loadChildren = async (append = false) => {
    try {
      setLoading(true);
      setError(null);
      const offset = append ? children.length : 0;
      const response = await getChildren({ limit: 20, offset });

      // Handle paginated response from DRF: {results: [], count, next, previous}
      const data = response.data.results || [];
      setHasMore(!!response.data.next);
      setChildren(append ? [...children, ...data] : data);
    } catch (err) {
      setError('Failed to load children');
      console.error('Failed to load children:', err);
      if (!append) setChildren([]);
    } finally {
      setLoading(false);
    }
  };

  const loadMore = () => {
    if (!loading && hasMore) {
      loadChildren(true);
    }
  };

  return {
    children,
    loading,
    error,
    hasMore,
    loadChildren,
    loadMore,
  };
}
