import { useState, useEffect } from 'react';
import { getBuses, createBus, updateBus, deleteBus, assignDriver, assignMinder, assignChildren } from '../services/busApi';
import type { Bus } from '../types';

export function useBuses() {
  const [buses, setBuses] = useState<Bus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);

  const loadBuses = async (append = false) => {
    try {
      setLoading(true);
      setError(null);
      const offset = append ? buses.length : 0;
      const response = await getBuses({ limit: 20, offset });

      // Handle paginated response from DRF: {results: [], count, next, previous}
      const data = response.data.results || [];
      setHasMore(!!response.data.next);
      setBuses(append ? [...buses, ...data] : data);
    } catch (err) {
      setError('Failed to load buses');
      console.error('Failed to load buses:', err);
      if (!append) setBuses([]);
    } finally {
      setLoading(false);
    }
  };

  const loadMore = () => {
    if (!loading && hasMore) {
      loadBuses(true);
    }
  };

  useEffect(() => {
    loadBuses();
  }, []);

  const handleCreateBus = async (data: Partial<Bus>) => {
    try {
      const response = await createBus(data);
      if (response.status === 200 || response.status === 201) {
        await loadBuses();
        return { success: true, data: response.data };
      }
      return { success: false, error: 'Failed to create bus' };
    } catch (err) {
      console.error('Failed to create bus:', err);
      return { success: false, error: 'Failed to create bus' };
    }
  };

  const handleUpdateBus = async (id: string, data: Partial<Bus>) => {
    try {
      const response = await updateBus(id, data);
      if (response.status === 200 || response.status === 201) {
        await loadBuses();
        return { success: true, data: response.data };
      }
      return { success: false, error: 'Failed to update bus' };
    } catch (err) {
      console.error('Failed to update bus:', err);
      return { success: false, error: 'Failed to update bus' };
    }
  };

  const handleDeleteBus = async (id: string) => {
    try {
      await deleteBus(id);
      await loadBuses();
      return { success: true };
    } catch (err) {
      console.error('Failed to delete bus:', err);
      return { success: false, error: 'Failed to delete bus' };
    }
  };

  const handleAssignDriver = async (busId: string, driverId: string) => {
    try {
      await assignDriver(busId, driverId);
      await loadBuses();
      return { success: true };
    } catch (err) {
      console.error('Failed to assign driver:', err);
      return { success: false, error: 'Failed to assign driver' };
    }
  };

  const handleAssignMinder = async (busId: string, minderId: string) => {
    try {
      await assignMinder(busId, minderId);
      await loadBuses();
      return { success: true };
    } catch (err) {
      console.error('Failed to assign minder:', err);
      return { success: false, error: 'Failed to assign minder' };
    }
  };

  const handleAssignChildren = async (busId: string, childrenIds: string[]) => {
    try {
      await assignChildren(busId, childrenIds);
      await loadBuses();
      return { success: true };
    } catch (err) {
      console.error('Failed to assign children:', err);
      return { success: false, error: 'Failed to assign children' };
    }
  };

  return {
    buses,
    loading,
    error,
    hasMore,
    loadBuses,
    loadMore,
    createBus: handleCreateBus,
    updateBus: handleUpdateBus,
    deleteBus: handleDeleteBus,
    assignDriver: handleAssignDriver,
    assignMinder: handleAssignMinder,
    assignChildren: handleAssignChildren,
  };
}
