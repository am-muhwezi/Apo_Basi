import { useState, useEffect } from 'react';
import { Bus } from '../types/bus';
import { mockBuses } from '../data/mockBuses';

interface UseBusesReturn {
  buses: Bus[];
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

// Custom hook for bus data management
// This is where you would integrate with your API later
export const useBuses = (): UseBusesReturn => {
  const [buses, setBuses] = useState<Bus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBuses = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Replace this with actual API call:
      // const response = await fetch('/api/buses');
      // const data = await response.json();
      // setBuses(data);
      
      setBuses(mockBuses);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch buses');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBuses();
  }, []);

  return {
    buses,
    loading,
    error,
    refetch: fetchBuses
  };
};