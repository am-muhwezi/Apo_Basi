import * as busApi from './busApi';
import type { Bus } from '../types';

class BusService {
  /**
   * Load all buses from DRF API with pagination
   */
  async loadBuses(params?: { limit?: number; offset?: number }): Promise<Bus[]> {
    const response = await busApi.getBuses(params);
    // Handle paginated response from DRF: {results: [], count, next, previous}
    return response.data.results || [];
  }

  /**
   * Get single bus by ID
   */
  async getBus(id: string): Promise<Bus> {
    const response = await busApi.getBus(id);
    return response.data;
  }

  /**
   * Create new bus
   */
  async createBus(formData: Partial<Bus>): Promise<Bus> {
    const busData = {
      busNumber: formData.busNumber!,
      licensePlate: formData.licensePlate!,
      capacity: formData.capacity!,
      model: formData.model,
      year: formData.year,
      status: formData.status || 'active',
      lastMaintenance: formData.lastMaintenance,
    };

    const response = await busApi.createBus(busData);
    return response.data;
  }

  /**
   * Update existing bus
   */
  async updateBus(id: string, formData: Partial<Bus>): Promise<Bus> {
    const response = await busApi.updateBus(id, formData);
    return response.data;
  }

  /**
   * Delete bus
   */
  async deleteBus(id: string): Promise<void> {
    await busApi.deleteBus(id);
  }

  /**
   * Assign driver to bus
   */
  async assignDriver(busId: string, driverId: string): Promise<any> {
    const response = await busApi.assignDriver(busId, driverId);
    return response.data;
  }

  /**
   * Assign minder to bus
   */
  async assignMinder(busId: string, minderId: string): Promise<any> {
    const response = await busApi.assignMinder(busId, minderId);
    return response.data;
  }

  /**
   * Assign children to bus
   */
  async assignChildren(busId: string, childrenIds: string[]): Promise<any> {
    const response = await busApi.assignChildren(busId, childrenIds);
    return response.data;
  }

  /**
   * Get bus children
   */
  async getBusChildren(busId: string): Promise<any> {
    const response = await busApi.getBusChildren(busId);
    return response.data;
  }
}

export const busService = new BusService();
