import { Notification } from '../types/notification';

export const mockNotifications: Notification[] = [
  {
    id: 'NOT001',
    title: 'Bus 106 Maintenance Required',
    message: 'Bus 106 requires immediate maintenance check. Engine warning light is on.',
    type: 'warning',
    timestamp: '2025-01-10T08:45:00Z',
    read: false,
    busId: 'Bus 106',
    route: 'Route F',
    priority: 'high'
  },
  {
    id: 'NOT002',
    title: 'Route A Delay',
    message: 'Route A is experiencing a 15-minute delay due to traffic congestion on Main Street.',
    type: 'info',
    timestamp: '2025-01-10T08:30:00Z',
    read: false,
    busId: 'Bus 101',
    route: 'Route A',
    priority: 'medium'
  },
  {
    id: 'NOT003',
    title: 'Student Check-in Alert',
    message: 'Sophia Rodriguez has not checked in for Route B. Please verify attendance.',
    type: 'warning',
    timestamp: '2025-01-10T08:15:00Z',
    read: true,
    route: 'Route B',
    priority: 'medium'
  },
  {
    id: 'NOT004',
    title: 'New Driver Assignment',
    message: 'Mason Wilson has been assigned as the new driver for Bus 107.',
    type: 'success',
    timestamp: '2025-01-10T07:00:00Z',
    read: true,
    busId: 'Bus 107',
    priority: 'low'
  },
  {
    id: 'NOT005',
    title: 'Emergency Contact Update',
    message: 'Emergency contact information has been updated for Emma Johnson.',
    type: 'info',
    timestamp: '2025-01-09T16:30:00Z',
    read: true,
    priority: 'low'
  },
  {
    id: 'NOT006',
    title: 'Route Optimization Complete',
    message: 'Route optimization analysis has been completed. New routes will be effective Monday.',
    type: 'success',
    timestamp: '2025-01-09T14:20:00Z',
    read: true,
    priority: 'medium'
  }
];