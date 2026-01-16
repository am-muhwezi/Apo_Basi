/**
 * Shared Export Service
 *
 * This service provides export functionality for converting data to CSV and downloading files.
 * Can be used across all pages in the application.
 */

interface ExportColumn {
  key: string;
  header: string;
  formatter?: (value: any) => string;
}

class ExportService {
  /**
   * Convert data to CSV format
   */
  private convertToCSV(data: any[], columns: ExportColumn[]): string {
    if (!data || data.length === 0) {
      return '';
    }

    // Create header row
    const headers = columns.map(col => this.escapeCSVValue(col.header));
    const headerRow = headers.join(',');

    // Create data rows
    const dataRows = data.map(item => {
      const row = columns.map(col => {
        let value = item[col.key];

        // Apply formatter if provided
        if (col.formatter) {
          value = col.formatter(value);
        }

        // Convert to string and escape
        return this.escapeCSVValue(value);
      });
      return row.join(',');
    });

    // Combine header and data rows
    return [headerRow, ...dataRows].join('\n');
  }

  /**
   * Escape CSV values to handle commas, quotes, and newlines
   */
  private escapeCSVValue(value: any): string {
    if (value === null || value === undefined) {
      return '';
    }

    const stringValue = String(value);

    // If value contains comma, quote, or newline, wrap in quotes and escape existing quotes
    if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
      return `"${stringValue.replace(/"/g, '""')}"`;
    }

    return stringValue;
  }

  /**
   * Download data as CSV file
   */
  downloadCSV(data: any[], columns: ExportColumn[], filename: string): void {
    try {
      // Convert data to CSV
      const csv = this.convertToCSV(data, columns);

      if (!csv) {
        throw new Error('No data to export');
      }

      // Create blob
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });

      // Create download link
      const link = document.createElement('a');
      const url = URL.createObjectURL(blob);

      // Set download attributes
      link.setAttribute('href', url);
      link.setAttribute('download', `${filename}.csv`);
      link.style.visibility = 'hidden';

      // Append to body, click, and remove
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      // Clean up URL
      URL.revokeObjectURL(url);
    } catch (error) {
      throw new Error(`Export failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Download data as JSON file
   */
  downloadJSON(data: any, filename: string): void {
    try {
      // Convert data to JSON string
      const json = JSON.stringify(data, null, 2);

      // Create blob
      const blob = new Blob([json], { type: 'application/json;charset=utf-8;' });

      // Create download link
      const link = document.createElement('a');
      const url = URL.createObjectURL(blob);

      // Set download attributes
      link.setAttribute('href', url);
      link.setAttribute('download', `${filename}.json`);
      link.style.visibility = 'hidden';

      // Append to body, click, and remove
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      // Clean up URL
      URL.revokeObjectURL(url);
    } catch (error) {
      throw new Error(`Export failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Export attendance report
   */
  exportAttendanceReport(
    data: any[],
    date: Date,
    tripType: 'pickup' | 'dropoff'
  ): void {
    const columns: ExportColumn[] = [
      { key: 'childName', header: 'Student Name' },
      { key: 'class', header: 'Class' },
      { key: 'busNumber', header: 'Bus Number' },
      { key: 'route', header: 'Route' },
      {
        key: tripType === 'pickup' ? 'pickupTime' : 'dropoffTime',
        header: tripType === 'pickup' ? 'Pickup Time' : 'Dropoff Time'
      },
      {
        key: tripType === 'pickup' ? 'pickupStatus' : 'dropoffStatus',
        header: 'Status',
        formatter: (value) => value ? value.replace(/_/g, ' ').toUpperCase() : 'N/A'
      },
      {
        key: 'parentNotified',
        header: 'Parent Notified',
        formatter: (value) => value ? 'Yes' : 'No'
      },
    ];

    const dateStr = date.toISOString().split('T')[0];
    const filename = `attendance_${tripType}_${dateStr}`;

    this.downloadCSV(data, columns, filename);
  }

  /**
   * Export bus utilization report
   */
  exportBusUtilizationReport(data: any[]): void {
    // Flatten children data for CSV export
    const flatData: any[] = [];

    data.forEach(bus => {
      if (bus.children && bus.children.length > 0) {
        bus.children.forEach((child: any) => {
          flatData.push({
            bus_number: bus.bus_number,
            license_plate: bus.license_plate,
            capacity: bus.capacity,
            utilization_percentage: bus.utilization_percentage,
            driver_name: bus.driver ? `${bus.driver.first_name} ${bus.driver.last_name}` : 'N/A',
            driver_phone: bus.driver?.phone || 'N/A',
            minder_name: bus.minder ? `${bus.minder.first_name} ${bus.minder.last_name}` : 'N/A',
            minder_phone: bus.minder?.phone || 'N/A',
            route_name: bus.route?.name || 'N/A',
            route_code: bus.route?.route_code || 'N/A',
            child_name: `${child.first_name} ${child.last_name}`,
            child_grade: child.grade || 'N/A',
            parent_name: child.parent_name,
            parent_phone: child.parent_phone,
          });
        });
      } else {
        // Include buses with no children
        flatData.push({
          bus_number: bus.bus_number,
          license_plate: bus.license_plate,
          capacity: bus.capacity,
          utilization_percentage: bus.utilization_percentage,
          driver_name: bus.driver ? `${bus.driver.first_name} ${bus.driver.last_name}` : 'N/A',
          driver_phone: bus.driver?.phone || 'N/A',
          minder_name: bus.minder ? `${bus.minder.first_name} ${bus.minder.last_name}` : 'N/A',
          minder_phone: bus.minder?.phone || 'N/A',
          route_name: bus.route?.name || 'N/A',
          route_code: bus.route?.route_code || 'N/A',
          child_name: 'No children assigned',
          child_grade: 'N/A',
          parent_name: 'N/A',
          parent_phone: 'N/A',
        });
      }
    });

    const columns: ExportColumn[] = [
      { key: 'bus_number', header: 'Bus Number' },
      { key: 'license_plate', header: 'License Plate' },
      { key: 'capacity', header: 'Capacity' },
      { key: 'utilization_percentage', header: 'Utilization %' },
      { key: 'driver_name', header: 'Driver Name' },
      { key: 'driver_phone', header: 'Driver Phone' },
      { key: 'minder_name', header: 'Bus Assistant Name' },
      { key: 'minder_phone', header: 'Bus Assistant Phone' },
      { key: 'route_name', header: 'Route Name' },
      { key: 'route_code', header: 'Route Code' },
      { key: 'child_name', header: 'Child Name' },
      { key: 'child_grade', header: 'Grade' },
      { key: 'parent_name', header: 'Parent Name' },
      { key: 'parent_phone', header: 'Parent Phone' },
    ];

    const timestamp = new Date().toISOString().split('T')[0];
    const filename = `bus_utilization_${timestamp}`;

    this.downloadCSV(flatData, columns, filename);
  }

  /**
   * Export assignments report
   */
  exportAssignmentsReport(data: any[]): void {
    const columns: ExportColumn[] = [
      {
        key: 'assignmentType',
        header: 'Assignment Type',
        formatter: (value) => value ? value.replace(/_/g, ' ').toUpperCase() : 'N/A'
      },
      { key: 'assigneeName', header: 'Assignee Name' },
      { key: 'assigneeType', header: 'Assignee Type' },
      { key: 'assignedToName', header: 'Assigned To' },
      { key: 'assignedToType', header: 'Assigned To Type' },
      { key: 'effectiveDate', header: 'Effective Date' },
      { key: 'expiryDate', header: 'Expiry Date' },
      {
        key: 'status',
        header: 'Status',
        formatter: (value) => value ? value.toUpperCase() : 'N/A'
      },
      { key: 'reason', header: 'Reason' },
    ];

    const timestamp = new Date().toISOString().split('T')[0];
    const filename = `assignments_${timestamp}`;

    this.downloadCSV(data, columns, filename);
  }

  /**
   * Generic export for any data with custom columns
   */
  exportGeneric(
    data: any[],
    columns: ExportColumn[],
    filename: string
  ): void {
    this.downloadCSV(data, columns, filename);
  }
}

// Export singleton instance
export const exportService = new ExportService();

// Export types for use in other files
export type { ExportColumn };
