import * as assignmentApi from './assignmentApi';
import type { Assignment, BusRoute, AssignmentHistory, AssignmentFormData, RouteFormData } from '../types';

class AssignmentService {
  // Assignment methods
  async loadAssignments(filters?: Record<string, any>): Promise<Assignment[]> {
    try {
      const response = await assignmentApi.getAssignments(filters);
      return response.data;
    } catch (error) {
      console.error('Error loading assignments:', error);
      throw error;
    }
  }

  async getAssignment(id: string): Promise<Assignment> {
    try {
      const response = await assignmentApi.getAssignment(id);
      return response.data;
    } catch (error) {
      console.error(`Error loading assignment ${id}:`, error);
      throw error;
    }
  }

  async createAssignment(data: AssignmentFormData): Promise<Assignment> {
    try {
      const response = await assignmentApi.createAssignment(data);
      return response.data;
    } catch (error) {
      console.error('Error creating assignment:', error);
      throw error;
    }
  }

  async updateAssignment(id: string, data: Partial<AssignmentFormData>): Promise<Assignment> {
    try {
      const response = await assignmentApi.updateAssignment(id, data);
      return response.data;
    } catch (error) {
      console.error(`Error updating assignment ${id}:`, error);
      throw error;
    }
  }

  async deleteAssignment(id: string): Promise<void> {
    try {
      await assignmentApi.deleteAssignment(id);
    } catch (error) {
      console.error(`Error deleting assignment ${id}:`, error);
      throw error;
    }
  }

  async cancelAssignment(id: string, reason: string): Promise<void> {
    try {
      await assignmentApi.cancelAssignment(id, reason);
    } catch (error) {
      console.error(`Error cancelling assignment ${id}:`, error);
      throw error;
    }
  }

  async getAssignmentHistory(id: string): Promise<AssignmentHistory[]> {
    try {
      const response = await assignmentApi.getAssignmentHistory(id);
      return response.data;
    } catch (error) {
      console.error(`Error loading assignment history for ${id}:`, error);
      throw error;
    }
  }

  async bulkAssignChildrenToBus(busId: number, childrenIds: number[], effectiveDate?: string): Promise<any> {
    try {
      const response = await assignmentApi.bulkAssignChildrenToBus(busId, childrenIds, effectiveDate);
      return response.data;
    } catch (error) {
      console.error('Error bulk assigning children to bus:', error);
      throw error;
    }
  }

  async bulkAssignChildrenToRoute(routeId: number, childrenIds: number[], effectiveDate?: string): Promise<any> {
    try {
      const response = await assignmentApi.bulkAssignChildrenToRoute(routeId, childrenIds, effectiveDate);
      return response.data;
    } catch (error) {
      console.error('Error bulk assigning children to route:', error);
      throw error;
    }
  }

  async getBusUtilization(): Promise<any[]> {
    try {
      const response = await assignmentApi.getBusUtilization();
      return response.data;
    } catch (error) {
      console.error('Error loading bus utilization:', error);
      throw error;
    }
  }

  async transferAssignment(assignmentId: number, newAssignedToId: number, newAssignedToType: string, reason?: string): Promise<any> {
    try {
      const response = await assignmentApi.transferAssignment(assignmentId, newAssignedToId, newAssignedToType, reason);
      return response.data;
    } catch (error) {
      console.error('Error transferring assignment:', error);
      throw error;
    }
  }

  // Route methods
  async loadRoutes(): Promise<BusRoute[]> {
    try {
      const response = await assignmentApi.getRoutes();
      return response.data;
    } catch (error) {
      console.error('Error loading routes:', error);
      throw error;
    }
  }

  async getRoute(id: string): Promise<BusRoute> {
    try {
      const response = await assignmentApi.getRoute(id);
      return response.data;
    } catch (error) {
      console.error(`Error loading route ${id}:`, error);
      throw error;
    }
  }

  async createRoute(data: RouteFormData): Promise<BusRoute> {
    try {
      const response = await assignmentApi.createRoute(data);
      return response.data;
    } catch (error) {
      console.error('Error creating route:', error);
      throw error;
    }
  }

  async updateRoute(id: string, data: Partial<RouteFormData>): Promise<BusRoute> {
    try {
      const response = await assignmentApi.updateRoute(id, data);
      return response.data;
    } catch (error) {
      console.error(`Error updating route ${id}:`, error);
      throw error;
    }
  }

  async deleteRoute(id: string): Promise<void> {
    try {
      await assignmentApi.deleteRoute(id);
    } catch (error) {
      console.error(`Error deleting route ${id}:`, error);
      throw error;
    }
  }

  async getRouteAssignments(id: string): Promise<Assignment[]> {
    try {
      const response = await assignmentApi.getRouteAssignments(id);
      return response.data;
    } catch (error) {
      console.error(`Error loading route assignments for ${id}:`, error);
      throw error;
    }
  }

  async getRouteStatistics(id: string): Promise<any> {
    try {
      const response = await assignmentApi.getRouteStatistics(id);
      return response.data;
    } catch (error) {
      console.error(`Error loading route statistics for ${id}:`, error);
      throw error;
    }
  }

  // History methods
  async loadAllHistory(filters?: Record<string, any>): Promise<AssignmentHistory[]> {
    try {
      const response = await assignmentApi.getAllHistory(filters);
      return response.data;
    } catch (error) {
      console.error('Error loading assignment history:', error);
      throw error;
    }
  }
}

export const assignmentService = new AssignmentService();
