import { useState, useEffect } from 'react';
import { getDrivers } from '../services/driverApi';
import type { Driver } from '../types';

export function useDrivers() {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDrivers();
  }, []);

  const loadDrivers = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await getDrivers();
      setDrivers(response.data || []);
    } catch (err) {
      setError('Failed to load drivers');
      console.error('Failed to load drivers:', err);
      setDrivers([]);
    } finally {
      setLoading(false);
    }
  };

  return {
    drivers,
    loading,
    error,
    loadDrivers,
  };
}
