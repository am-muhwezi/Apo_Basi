export interface Bus {
  id: string;
  route: string;
  driver: string;
  capacity: number;
  studentsOnboard: number;
  status: 'Active' | 'Inactive' | 'Maintenance';
  lastUpdated: string;
}

export interface BusFilters {
  search: string;
  status: string;
  route: string;
}