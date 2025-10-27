import { useState, useEffect } from 'react';
import { getBusMinders } from '../services/busMinderApi';
import type { Minder } from '../types';

export function useMinders() {
  const [minders, setMinders] = useState<Minder[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadMinders();
  }, []);

  const loadMinders = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await getBusMinders();
      setMinders(response.data || []);
    } catch (err) {
      setError('Failed to load minders');
      console.error('Failed to load minders:', err);
      setMinders([]);
    } finally {
      setLoading(false);
    }
  };

  return {
    minders,
    loading,
    error,
    loadMinders,
  };
}
