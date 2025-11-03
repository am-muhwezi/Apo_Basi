import { useState, useEffect } from 'react';
import { getBusMinders } from '../services/busMinderApi';
import type { Minder } from '../types';

export function useMinders() {
  const [minders, setMinders] = useState<Minder[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);

  useEffect(() => {
    loadMinders();
  }, []);

  const loadMinders = async (append = false) => {
    try {
      setLoading(true);
      setError(null);
      const offset = append ? minders.length : 0;
      const response = await getBusMinders({ limit: 20, offset });

      // Handle paginated response from DRF: {results: [], count, next, previous}
      const data = response.data.results || [];
      setHasMore(!!response.data.next);
      setMinders(append ? [...minders, ...data] : data);
    } catch (err) {
      setError('Failed to load minders');
      console.error('Failed to load minders:', err);
      if (!append) setMinders([]);
    } finally {
      setLoading(false);
    }
  };

  const loadMore = () => {
    if (!loading && hasMore) {
      loadMinders(true);
    }
  };

  return {
    minders,
    loading,
    error,
    hasMore,
    loadMinders,
    loadMore,
  };
}
