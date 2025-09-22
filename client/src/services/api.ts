import AsyncStorage from '@react-native-async-storage/async-storage';
import { AuthResponse, User, Child, Student, Route, ApiResponse } from '../types';

const API_BASE_URL = 'http://localhost:8000/api/v1';

class ApiService {
  private async getToken(): Promise<string | null> {
    return await AsyncStorage.getItem('token');
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const token = await this.getToken();

    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...options.headers,
      },
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`);
    }

    return response.json();
  }

  // Mock API calls for MVP
  async login(email: string, password: string): Promise<AuthResponse> {
    // Mock response based on email domain
    const mockUsers = {
      'parent@test.com': { id: 1, name: 'John Parent', email, role: 'parent' as const },
      'busminder@test.com': { id: 2, name: 'Jane BusMinder', email, role: 'busminder' as const },
      'driver@test.com': { id: 3, name: 'Mike Driver', email, role: 'driver' as const },
    };

    const user = mockUsers[email as keyof typeof mockUsers];
    if (!user) {
      throw new Error('Invalid credentials');
    }

    return {
      token: 'mock-jwt-token-' + user.role,
      user,
    };
  }

  async getProfile(): Promise<User> {
    const token = await this.getToken();
    if (!token) throw new Error('No token');

    // Extract role from mock token
    const role = token.split('-')[3] as 'parent' | 'busminder' | 'driver';
    const mockUser = {
      parent: { id: 1, name: 'John Parent', email: 'parent@test.com', role: 'parent' as const },
      busminder: { id: 2, name: 'Jane BusMinder', email: 'busminder@test.com', role: 'busminder' as const },
      driver: { id: 3, name: 'Mike Driver', email: 'driver@test.com', role: 'driver' as const },
    };

    return mockUser[role];
  }

  async getParentDashboard(): Promise<{ children: Child[] }> {
    return {
      children: [
        {
          id: 1,
          name: 'Alice',
          class: '5A',
          bus_number: 'B001',
          bus_status: 'on_route',
          attendance: true,
          pickup_time: '07:30',
          parent_id: 1,
        },
        {
          id: 2,
          name: 'Bob',
          class: '3B',
          bus_number: 'B002',
          bus_status: 'arrived',
          attendance: true,
          pickup_time: '07:45',
          parent_id: 1,
        },
      ],
    };
  }

  async getBusminderStudents(): Promise<{ students: Student[] }> {
    return {
      students: [
        { id: 1, name: 'Alice', class: '5A', attendance: null, parent_phone: '+1234567890' },
        { id: 2, name: 'Bob', class: '3B', attendance: null, parent_phone: '+1234567891' },
        { id: 3, name: 'Charlie', class: '4C', attendance: null, parent_phone: '+1234567892' },
      ],
    };
  }

  async markAttendance(studentId: number, status: 'present' | 'absent'): Promise<ApiResponse<any>> {
    return {
      success: true,
      data: {
        student_id: studentId,
        status,
        timestamp: new Date().toISOString(),
      },
    };
  }

  async getDriverRoute(): Promise<{ route: Route }> {
    return {
      route: {
        id: 'R001',
        name: 'Route A',
        student_count: 15,
        status: 'inactive',
      },
    };
  }

  async logout(): Promise<void> {
    await AsyncStorage.removeItem('token');
  }
}

export const apiService = new ApiService();