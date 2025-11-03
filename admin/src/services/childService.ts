import * as childApi from './childApi';
import * as parentApi from './parentApi';
import * as busApi from './busApi';
import type { Child, Parent, Bus } from '../types';

class ChildService {
  /**
   * Load all children from DRF API with pagination
   */
  async loadChildren(params?: { limit?: number; offset?: number }): Promise<Child[]> {
    const response = await childApi.getChildren(params);
    // Handle paginated response from DRF: {results: [], count, next, previous}
    return response.data.results || [];
  }

  /**
   * Load all parents (for parent dropdown) with pagination
   */
  async loadParents(params?: { limit?: number; offset?: number }): Promise<Parent[]> {
    const response = await parentApi.getParents(params);
    // Handle paginated response from DRF: {results: [], count, next, previous}
    return response.data.results || [];
  }

  /**
   * Load all buses (for bus assignment dropdown) with pagination
   */
  async loadBuses(params?: { limit?: number; offset?: number }): Promise<Bus[]> {
    const response = await busApi.getBuses(params);
    // Handle paginated response from DRF: {results: [], count, next, previous}
    return response.data.results || [];
  }

  /**
   * Get single child by ID
   */
  async getChild(id: string): Promise<Child> {
    const response = await childApi.getChild(id);
    return response.data;
  }

  /**
   * Create new child
   */
  async createChild(formData: Partial<Child>): Promise<Child> {
    const childData = {
      firstName: formData.firstName!,
      lastName: formData.lastName!,
      grade: formData.grade!,
      age: formData.age,
      status: formData.status || 'active',
      parentId: formData.parentId!,
      assignedBusId: formData.assignedBusId,
    };

    const response = await childApi.createChild(childData);
    return response.data;
  }

  /**
   * Update existing child
   */
  async updateChild(id: string, formData: Partial<Child>): Promise<Child> {
    const childData = {
      firstName: formData.firstName,
      lastName: formData.lastName,
      grade: formData.grade,
      age: formData.age,
      status: formData.status,
      parentId: formData.parentId,
      assignedBusId: formData.assignedBusId,
    };

    const response = await childApi.updateChild(id, childData);
    return response.data;
  }

  /**
   * Delete child
   */
  async deleteChild(id: string): Promise<void> {
    await childApi.deleteChild(id);
  }
}

export const childService = new ChildService();
