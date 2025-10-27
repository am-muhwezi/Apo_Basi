import axios from './axiosConfig';

export interface DashboardStats {
  buses: {
    total: number;
    active: number;
    maintenance: number;
    inactive: number;
  };
  children: {
    total: number;
    active: number;
    with_bus: number;
    checked_in: number;
  };
  users: {
    parents: number;
    drivers: number;
    minders: number;
    admins: number;
  };
  capacity: {
    total: number;
    students_onboard: number;
  };
  recent_activity: Array<{
    id: string | number;
    action: string;
    time: string;
    type: 'success' | 'warning' | 'error' | 'info';
  }>;
  fleet_status: Array<{
    status: string;
    count: number;
    color: string;
  }>;
}

export const dashboardService = {
  async getStats(): Promise<DashboardStats> {
    const response = await axios.get('/admins/dashboard/stats/');
    return response.data;
  },
};
