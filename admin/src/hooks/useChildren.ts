import { useState, useEffect } from 'react';
import { getChildren } from '../services/childApi';
import type { Child } from '../types';

export function useChildren() {
  const [children, setChildren] = useState<Child[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadChildren();
  }, []);

  const loadChildren = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await getChildren();
      setChildren(response.data || []);
    } catch (err) {
      setError('Failed to load children');
      console.error('Failed to load children:', err);
      setChildren([]);
    } finally {
      setLoading(false);
    }
  };

  return {
    children,
    loading,
    error,
    loadChildren,
  };
}
