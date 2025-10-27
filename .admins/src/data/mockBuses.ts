import { Bus } from '../types/bus';

export const mockBuses: Bus[] = [
  {
    id: 'Bus 101',
    route: 'Route A',
    driver: 'Ethan Carter',
    capacity: 45,
    studentsOnboard: 32,
    status: 'Active',
    lastUpdated: '2025-01-10T08:30:00Z'
  },
  {
    id: 'Bus 102',
    route: 'Route B',
    driver: 'Olivia Bennett',
    capacity: 40,
    studentsOnboard: 28,
    status: 'Active',
    lastUpdated: '2025-01-10T08:32:00Z'
  },
  {
    id: 'Bus 103',
    route: 'Route C',
    driver: 'Noah Thompson',
    capacity: 42,
    studentsOnboard: 35,
    status: 'Active',
    lastUpdated: '2025-01-10T08:28:00Z'
  },
  {
    id: 'Bus 104',
    route: 'Route D',
    driver: 'Ava Harper',
    capacity: 48,
    studentsOnboard: 40,
    status: 'Active',
    lastUpdated: '2025-01-10T08:35:00Z'
  },
  {
    id: 'Bus 105',
    route: 'Route E',
    driver: 'Liam Foster',
    capacity: 40,
    studentsOnboard: 30,
    status: 'Active',
    lastUpdated: '2025-01-10T08:25:00Z'
  },
  {
    id: 'Bus 106',
    route: 'Route F',
    driver: 'Emma Davis',
    capacity: 45,
    studentsOnboard: 0,
    status: 'Maintenance',
    lastUpdated: '2025-01-10T07:00:00Z'
  },
  {
    id: 'Bus 107',
    route: 'Route G',
    driver: 'Mason Wilson',
    capacity: 38,
    studentsOnboard: 0,
    status: 'Inactive',
    lastUpdated: '2025-01-10T06:45:00Z'
  }
];