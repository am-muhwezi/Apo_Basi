import * as parentApi from './parentApi';
import type { Parent } from '../types';

class ParentService {
  /**
   * Load all parents from DRF API
   */
  async loadParents(): Promise<Parent[]> {
    const response = await parentApi.getParents();
    return response.data;
  }

  /**
   * Get single parent by ID
   */
  async getParent(id: string): Promise<Parent> {
    const response = await parentApi.getParent(id);
    return response.data;
  }

  /**
   * Create new parent
   */
  async createParent(formData: Partial<Parent>): Promise<Parent> {
    const parentData = {
      firstName: formData.firstName!,
      lastName: formData.lastName!,
      email: formData.email,
      phone: formData.phone!,
      address: formData.address,
      emergencyContact: formData.emergencyContact,
      status: formData.status || 'active',
    };

    const response = await parentApi.createParent(parentData);
    return response.data;
  }

  /**
   * Update existing parent
   */
  async updateParent(id: string, formData: Partial<Parent>): Promise<Parent> {
    const parentData = {
      firstName: formData.firstName,
      lastName: formData.lastName,
      email: formData.email,
      phone: formData.phone,
      address: formData.address,
      emergencyContact: formData.emergencyContact,
      status: formData.status,
    };

    const response = await parentApi.updateParent(id, parentData);
    return response.data;
  }

  /**
   * Delete parent
   */
  async deleteParent(id: string): Promise<void> {
    await parentApi.deleteParent(id);
  }
}

export const parentService = new ParentService();
