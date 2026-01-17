import { io, Socket } from 'socket.io-client';
import type { Location } from '../types';

/**
 * Socket.IO service for real-time bus tracking
 * Connects admin dashboard to Socket.IO server for live location updates
 */

const SOCKET_URL = import.meta.env.VITE_SOCKET_URL || 'http://192.168.61.114:3000';

export interface LocationUpdate {
  busId: string;
  bus_number: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  timestamp: string;
}

export interface TripStartedEvent {
  busId: string;
  busNumber: string;
  tripType: 'pickup' | 'dropoff';
  tripId: string;
  title: string;
  message: string;
  timestamp: string;
}

export interface TripEndedEvent {
  busId: string;
  busNumber: string;
  tripType?: 'pickup' | 'dropoff';
  tripId: string;
  title: string;
  message: string;
  timestamp: string;
}

class SocketService {
  private socket: Socket | null = null;
  private listeners: Map<string, Set<Function>> = new Map();

  /**
   * Connect to Socket.IO server as admin
   */
  connect(token: string): void {
    if (this.socket?.connected) {
      return;
    }

    this.socket = io(SOCKET_URL, {
      auth: {
        token,
        userType: 'admin', // Important: identify as admin
      },
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5,
    });

    this.socket.on('connect', () => {
      this.emit('connected');
    });

    this.socket.on('disconnect', (reason) => {
      this.emit('disconnected', reason);
    });

    this.socket.on('error', (error) => {
      this.emit('error', error);
    });

    this.socket.on('subscribed', (data) => {
      this.emit('subscribed', data);
    });

    this.socket.on('unsubscribed', (data) => {
      this.emit('unsubscribed', data);
    });

    // Location updates
    this.socket.on('location_update', (data: LocationUpdate) => {
      this.emit('location_update', data);
    });

    // Trip lifecycle events
    this.socket.on('trip_started', (data: TripStartedEvent) => {
      this.emit('trip_started', data);
    });

    this.socket.on('trip_ended', (data: TripEndedEvent) => {
      this.emit('trip_ended', data);
    });

    this.socket.on('trip_completed', (data: TripEndedEvent) => {
      this.emit('trip_completed', data);
    });

    // Active trips response
    this.socket.on('active_trips', (data) => {
      this.emit('active_trips', data);
    });
  }

  /**
   * Disconnect from Socket.IO server
   */
  disconnect(): void {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
      this.listeners.clear();
    }
  }

  /**
   * Subscribe to a specific bus or all buses
   * @param busId - Bus ID or 'all' to monitor all buses
   */
  subscribeToBus(busId: string | number | 'all'): void {
    if (!this.socket?.connected) {
      return;
    }

    this.socket.emit('subscribe_to_bus', { busId });
  }

  /**
   * Unsubscribe from a bus
   */
  unsubscribeFromBus(busId: string | number | 'all'): void {
    if (!this.socket?.connected) {
      return;
    }

    this.socket.emit('unsubscribe_from_bus', { busId });
  }

  /**
   * Request current status of all active trips
   */
  requestActiveTrips(): void {
    if (!this.socket?.connected) {
      return;
    }

    this.socket.emit('request_active_trips');
  }

  /**
   * Add event listener
   */
  on(event: string, callback: Function): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);
  }

  /**
   * Remove event listener
   */
  off(event: string, callback: Function): void {
    const eventListeners = this.listeners.get(event);
    if (eventListeners) {
      eventListeners.delete(callback);
    }
  }

  /**
   * Emit event to all listeners
   */
  private emit(event: string, data?: any): void {
    const eventListeners = this.listeners.get(event);
    if (eventListeners) {
      eventListeners.forEach((callback) => callback(data));
    }
  }

  /**
   * Check if socket is connected
   */
  isConnected(): boolean {
    return this.socket?.connected || false;
  }
}

// Export singleton instance
export const socketService = new SocketService();
