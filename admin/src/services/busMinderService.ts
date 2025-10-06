import * as busMinderApi from './busMinderApi';
import type { BusMinder } from '../types';

class BusMinderService {
  /**
   * Load all bus minders from DRF API
   */
  async loadBusMinders(): Promise<BusMinder[]> {
    const response = await busMinderApi.getBusMinders();
    return response.data;
  }

  /**
   * Get single bus minder by ID
   */
  async getBusMinder(id: string): Promise<BusMinder> {
    const response = await busMinderApi.getBusMinder(id);
    return response.data;
  }

  /**
   * Create new bus minder
   */
  async createBusMinder(formData: Partial<BusMinder>): Promise<BusMinder> {
    const busMinderData = {
      firstName: formData.firstName!,
      lastName: formData.lastName!,
      email: formData.email,
      phone: formData.phone!,
      status: formData.status || 'active',
    };

    const response = await busMinderApi.createBusMinder(busMinderData);
    return response.data;
  }

  /**
   * Update existing bus minder
   */
  async updateBusMinder(id: string, formData: Partial<BusMinder>): Promise<BusMinder> {
    const busMinderData = {
      firstName: formData.firstName,
      lastName: formData.lastName,
      email: formData.email,
      phone: formData.phone,
      status: formData.status,
    };

    const response = await busMinderApi.updateBusMinder(id, busMinderData);
    return response.data;
  }

  /**
   * Delete bus minder
   */
  async deleteBusMinder(id: string): Promise<void> {
    await busMinderApi.deleteBusMinder(id);
  }
}

export const busMinderService = new BusMinderService();
