/**
 * useBuses Hook
 *
 * Custom React hook for managing bus state and operations.
 * This is the state management layer between UI and services.
 *
 * Architecture:
 * - Manages local state (buses, loading, error)
 * - Calls busService methods (not API directly)
 * - Handles UI-specific concerns (loading states, pagination)
 * - Returns functions for components to use
 *
 * Junior Dev Guide:
 * - Hooks manage STATE, services manage LOGIC
 * - Always call service layer, never API layer directly
 * - Handle loading states for better UX
 * - Return consistent interface for components
 */

import { useState, useRef, useCallback, useEffect } from 'react';
import { busService } from '../services/busService';
import type { Bus } from '../types';
import type { ApiResponse } from '../types/api';

interface UseBusesParams {
  search?: string;
  ordering?: string;
}

interface UseBusesReturn {
  // State
  buses: Bus[];
  loading: boolean;
  error: string | null;
  hasMore: boolean;
  totalCount: number;

  // Actions
  loadBuses: (append?: boolean) => Promise<void>;
  loadMore: () => void;
  refreshBuses: () => Promise<void>;
  createBus: (data: Partial<Bus>) => Promise<ApiResponse<Bus>>;
  updateBus: (id: string, data: Partial<Bus>) => Promise<ApiResponse<Bus>>;
  deleteBus: (id: string) => Promise<ApiResponse<void>>;
  assignDriver: (busId: string, driverId: string) => Promise<ApiResponse<any>>;
  assignMinder: (busId: string, minderId: string) => Promise<ApiResponse<any>>;
  assignChildren: (busId: string, childrenIds: string[]) => Promise<ApiResponse<any>>;
}

/**
 * Custom hook for bus management
 *
 * Example usage in a component:
 * ```tsx
 * function BusesPage() {
 *   const { buses, loading, error, createBus, updateBus } = useBuses();
 *
 *   const handleCreate = async (formData) => {
 *     const result = await createBus(formData);
 *     if (result.success) {
 *       toast.success('Bus created!');
 *     } else {
 *       toast.error(result.error.message);
 *     }
 *   };
 *
 *   if (loading) return <Spinner />;
 *   if (error) return <Error message={error} />;
 *   return <BusList buses={buses} />;
 * }
 * ```
 */
const LIMIT = 20;

export function useBuses(params?: UseBusesParams): UseBusesReturn {
  const [buses, setBuses] = useState<Bus[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const offsetRef = useRef(0);
  const loadingRef = useRef(false);
  const searchRef = useRef(params?.search ?? '');
  const orderingRef = useRef(params?.ordering ?? '');

  /**
   * Load buses with optional pagination
   * @param append - If true, append to existing buses; if false, replace
   */
  const loadBuses = useCallback(async (append = false) => {
    if (loadingRef.current) return;
    try {
      loadingRef.current = true;
      setLoading(true);
      setError(null);

      const currentOffset = append ? offsetRef.current : 0;
      const result = await busService.loadBuses({
        limit: LIMIT,
        offset: currentOffset,
        search: searchRef.current || undefined,
        ordering: orderingRef.current || undefined,
      });

      if (result.success && result.data) {
        const { buses: newBuses, count } = result.data;
        const newOffset = currentOffset + newBuses.length;
        setBuses((prev) => (append ? [...prev, ...newBuses] : newBuses));
        setTotalCount(count ?? 0);
        setHasMore(newOffset < (count ?? 0));
        offsetRef.current = newOffset;
      } else {
        setError(result.error?.message || 'Failed to load buses');
        if (!append) setBuses([]);
      }
    } catch {
      setError('An unexpected error occurred');
      if (!append) setBuses([]);
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
      loadBuses(false);
    }
  }, [params?.search, params?.ordering, loadBuses]);

  /**
   * Load more buses (pagination)
   */
  const loadMore = useCallback(() => {
    if (!loadingRef.current && hasMore) {
      loadBuses(true);
    }
  }, [hasMore, loadBuses]);

  const refreshBuses = useCallback(async () => {
    offsetRef.current = 0;
    await loadBuses(false);
  }, [loadBuses]);

  /**
   * Create a new bus
   */
  const handleCreateBus = useCallback(
    async (data: Partial<Bus>): Promise<ApiResponse<Bus>> => {
      const result = await busService.createBus(data);

      if (result.success) {
        // Refresh the list to show the new bus
        await refreshBuses();
      }

      return result;
    },
    [refreshBuses]
  );

  /**
   * Update an existing bus
   */
  const handleUpdateBus = useCallback(
    async (id: string, data: Partial<Bus>): Promise<ApiResponse<Bus>> => {
      const result = await busService.updateBus(id, data);

      if (result.success) {
        // Optimistic update: update the bus in local state
        setBuses((prev) =>
          prev.map((bus) => (bus.id === id ? { ...bus, ...data } : bus))
        );
      }

      return result;
    },
    []
  );

  /**
   * Delete a bus
   */
  const handleDeleteBus = useCallback(
    async (id: string): Promise<ApiResponse<void>> => {
      const result = await busService.deleteBus(id);

      if (result.success) {
        // Optimistic update: remove from local state
        setBuses((prev) => prev.filter((bus) => bus.id !== id));
      }

      return result;
    },
    []
  );

  /**
   * Assign a driver to a bus
   */
  const handleAssignDriver = useCallback(
    async (busId: string, driverId: string): Promise<ApiResponse<any>> => {
      const result = await busService.assignDriver(busId, driverId);

      if (result.success) {
        // Refresh to get updated bus data
        await refreshBuses();
      }

      return result;
    },
    [refreshBuses]
  );

  /**
   * Assign a minder to a bus
   */
  const handleAssignMinder = useCallback(
    async (busId: string, minderId: string): Promise<ApiResponse<any>> => {
      const result = await busService.assignMinder(busId, minderId);

      if (result.success) {
        // Refresh to get updated bus data
        await refreshBuses();
      }

      return result;
    },
    [refreshBuses]
  );

  /**
   * Assign children to a bus
   */
  const handleAssignChildren = useCallback(
    async (busId: string, childrenIds: string[]): Promise<ApiResponse<any>> => {
      // Get bus capacity for validation
      const bus = buses.find((b) => b.id === busId);
      const result = await busService.assignChildren(
        busId,
        childrenIds,
        bus?.capacity
      );

      if (result.success) {
        // Refresh to get updated bus data
        await refreshBuses();
      }

      return result;
    },
    [buses, refreshBuses]
  );

  // NOTE: Buses do NOT auto-load on mount
  // Each page decides when to call loadBuses()

  return {
    // State
    buses,
    loading,
    error,
    hasMore,
    totalCount,

    // Actions
    loadBuses,
    loadMore,
    refreshBuses,
    createBus: handleCreateBus,
    updateBus: handleUpdateBus,
    deleteBus: handleDeleteBus,
    assignDriver: handleAssignDriver,
    assignMinder: handleAssignMinder,
    assignChildren: handleAssignChildren,
  };
}
