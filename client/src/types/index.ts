export interface User {
  id: number;
  name: string;
  email: string;
  role: 'parent' | 'busminder' | 'driver';
}

export interface Child {
  id: number;
  name: string;
  class: string;
  bus_number: string;
  bus_status: 'on_route' | 'arrived' | 'delayed' | 'not_started';
  attendance: boolean | null;
  pickup_time: string;
  parent_id: number;
}

export interface Student {
  id: number;
  name: string;
  class: string;
  attendance: boolean | null;
  parent_phone: string;
}

export interface Route {
  id: string;
  name: string;
  student_count: number;
  status: 'active' | 'inactive' | 'completed';
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  errors?: string[];
}