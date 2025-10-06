import * as driverApi from './driverApi';
import * as busApi from './busApi';
import type { Driver, Bus } from '../types';

class DriverService {
  /**
   * Load all drivers from DRF API
   */
  async loadDrivers(): Promise<Driver[]> {
    const response = await driverApi.getDrivers();
    return response.data;
  }

  /**
   * Load all buses (for assignment dropdown)
   */
  async loadBuses(): Promise<Bus[]> {
    const response = await busApi.getBuses();
    return response.data;
  }

  /**
   * Get single driver by ID
   */
  async getDriver(id: string): Promise<Driver> {
    const response = await driverApi.getDriver(id);
    return response.data;
  }

  /**
   * Create new driver
   */
  async createDriver(formData: Partial<Driver>): Promise<Driver> {
    const driverData = {
      firstName: formData.firstName!,
      lastName: formData.lastName!,
      email: formData.email,
      phone: formData.phone!,
      licenseNumber: formData.licenseNumber!,
      licenseExpiry: formData.licenseExpiry,
      status: formData.status || 'active',
      assignedBusId: formData.assignedBusId,
    };

    const response = await driverApi.createDriver(driverData);
    return response.data;
  }

  /**
   * Update existing driver
   */
  async updateDriver(id: string, formData: Partial<Driver>): Promise<Driver> {
    const driverData = {
      firstName: formData.firstName,
      lastName: formData.lastName,
      email: formData.email,
      phone: formData.phone,
      licenseNumber: formData.licenseNumber,
      licenseExpiry: formData.licenseExpiry,
      status: formData.status,
      assignedBusId: formData.assignedBusId,
    };

    const response = await driverApi.updateDriver(id, driverData);
    return response.data;
  }

  /**
   * Delete driver
   */
  async deleteDriver(id: string): Promise<void> {
    await driverApi.deleteDriver(id);
  }

  /**
   * Get bus number for display
   */
  getBusNumber(buses: Bus[], busId?: string): string {
    if (!busId) return 'Not Assigned';
    const bus = buses.find((b) => b.id === busId);
    return bus ? bus.busNumber : 'Unknown';
  }
}

export const driverService = new DriverService();
