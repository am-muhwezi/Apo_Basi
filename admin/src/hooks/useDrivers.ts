import { useState, useEffect } from 'react';
import { getDrivers } from '../services/driverApi';
import type { Driver } from '../types';

export function useDrivers() {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);

  useEffect(() => {
    loadDrivers();
  }, []);

  const loadDrivers = async (append = false) => {
    try {
      setLoading(true);
      setError(null);
      const offset = append ? drivers.length : 0;
      const response = await getDrivers({ limit: 20, offset });

      // Handle paginated response from DRF: {results: [], count, next, previous}
      const data = response.data.results || [];
      setHasMore(!!response.data.next);
      setDrivers(append ? [...drivers, ...data] : data);
    } catch (err) {
      setError('Failed to load drivers');
      console.error('Failed to load drivers:', err);
      if (!append) setDrivers([]);
    } finally {
      setLoading(false);
    }
  };

  const loadMore = () => {
    if (!loading && hasMore) {
      loadDrivers(true);
    }
  };

  return {
    drivers,
    loading,
    error,
    hasMore,
    loadDrivers,
    loadMore,
  };
}
