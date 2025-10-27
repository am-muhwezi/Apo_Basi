export interface Notification {
  id: string;
  title: string;
  message: string;
  type: 'info' | 'warning' | 'error' | 'success';
  timestamp: string;
  read: boolean;
  busId?: string;
  route?: string;
  priority: 'low' | 'medium' | 'high';
}