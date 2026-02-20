/**
 * Native WebSocket service for real-time bus location tracking
 * Connects to Django Channels WebSocket endpoints
 */

// Automatically convert HTTP API URL to WebSocket URL
const getWebSocketUrl = (): string => {
  const apiUrl = import.meta.env.VITE_API_BASE_URL || 'http://192.168.100.65:8000';
  return apiUrl.replace(/^http/, 'ws');
};

const WS_BASE_URL = import.meta.env.VITE_WS_URL || getWebSocketUrl();

export interface LocationUpdate {
  type: 'location_update';
  bus_id: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  timestamp: string;
}

export interface ConnectionMessage {
  type: 'connected';
  bus_id: string;
  message: string;
}

export interface ErrorMessage {
  type: 'error';
  message: string;
}

type WebSocketMessage = LocationUpdate | ConnectionMessage | ErrorMessage;

interface BusConnection {
  ws: WebSocket;
  reconnectAttempts: number;
  reconnectTimer?: number;
  stopped: boolean;
}

class BusWebSocketService {
  private connections: Map<string, BusConnection> = new Map();
  private listeners: Map<string, Set<(data: WebSocketMessage) => void>> = new Map();
  private token: string | null = null;
  private readonly MAX_RECONNECT_ATTEMPTS = 5;
  private readonly RECONNECT_DELAY = 3000;

  /**
   * Set authentication token for WebSocket connections
   */
  setToken(token: string): void {
    this.token = token;
  }

  /**
   * Subscribe to a specific bus for location updates
   */
  subscribeToBus(busId: string): void {
    if (!this.token) {
      return;
    }

    // If already connected, don't create a new connection
    if (this.connections.has(busId)) {
      return;
    }

    this.createConnection(busId);
  }

  /**
   * Unsubscribe from a specific bus
   */
  unsubscribeFromBus(busId: string): void {
    const connection = this.connections.get(busId);
    if (connection) {
      connection.stopped = true;
      if (connection.reconnectTimer) {
        clearTimeout(connection.reconnectTimer);
      }
      connection.ws.close(1000, 'Unsubscribed');
      this.connections.delete(busId);
    }
  }

  /**
   * Subscribe to all buses (admin only)
   * Note: This creates individual connections for each bus
   */
  subscribeToAllBuses(busIds: string[]): void {
    busIds.forEach(busId => this.subscribeToBus(busId));
  }

  /**
   * Unsubscribe from all buses and close all connections
   */
  disconnect(): void {
    this.connections.forEach((connection) => {
      connection.stopped = true;
      if (connection.reconnectTimer) {
        clearTimeout(connection.reconnectTimer);
      }
      connection.ws.close(1000, 'Disconnected');
    });
    this.connections.clear();
    this.listeners.clear();
  }

  /**
   * Send location update (for drivers)
   */
  sendLocationUpdate(
    busId: string,
    latitude: number,
    longitude: number,
    speed: number = 0,
    heading: number = 0
  ): void {
    const connection = this.connections.get(busId);
    if (connection && connection.ws.readyState === WebSocket.OPEN) {
      connection.ws.send(JSON.stringify({
        type: 'location_update',
        latitude,
        longitude,
        speed,
        heading,
        timestamp: new Date().toISOString()
      }));
    }
  }

  /**
   * Request current location for a bus
   */
  requestCurrentLocation(busId: string): void {
    const connection = this.connections.get(busId);
    if (connection && connection.ws.readyState === WebSocket.OPEN) {
      connection.ws.send(JSON.stringify({
        type: 'request_current_location'
      }));
    }
  }

  /**
   * Add event listener for WebSocket messages
   */
  on(busId: string, callback: (data: WebSocketMessage) => void): void {
    const key = busId;
    if (!this.listeners.has(key)) {
      this.listeners.set(key, new Set());
    }
    this.listeners.get(key)!.add(callback);
  }

  /**
   * Add global event listener for all buses
   */
  onAny(callback: (data: WebSocketMessage) => void): void {
    this.on('*', callback);
  }

  /**
   * Remove event listener
   */
  off(busId: string, callback: (data: WebSocketMessage) => void): void {
    const listeners = this.listeners.get(busId);
    if (listeners) {
      listeners.delete(callback);
    }
  }

  /**
   * Check if connected to a specific bus
   */
  isConnected(busId: string): boolean {
    const connection = this.connections.get(busId);
    return connection?.ws.readyState === WebSocket.OPEN || false;
  }

  /**
   * Create WebSocket connection for a bus
   */
  private createConnection(busId: string, previousAttempts = 0): void {
    const wsUrl = `${WS_BASE_URL}/ws/bus/${busId}/?token=${this.token}`;
    const ws = new WebSocket(wsUrl);

    const connection: BusConnection = {
      ws,
      reconnectAttempts: previousAttempts,
      stopped: false,
    };

    this.connections.set(busId, connection);

    ws.onopen = () => {
      connection.reconnectAttempts = 0;

      // Request current location on connect
      this.requestCurrentLocation(busId);
    };

    ws.onmessage = (event) => {
      try {
        const data: WebSocketMessage = JSON.parse(event.data);

        // Emit to bus-specific listeners
        this.emit(busId, data);

        // Emit to global listeners
        this.emit('*', data);
      } catch (error) {
        // Silent error handling
      }
    };

    ws.onerror = (_error) => {
      // Silent error handling
    };

    ws.onclose = (event) => {
      if (connection.stopped) return;

      // Attempt reconnection if not a normal closure and under max attempts
      if (event.code !== 1000 && connection.reconnectAttempts < this.MAX_RECONNECT_ATTEMPTS) {
        const attempts = connection.reconnectAttempts + 1;
        const delay = this.RECONNECT_DELAY * Math.pow(2, attempts - 1); // exponential backoff

        connection.reconnectTimer = window.setTimeout(() => {
          if (!this.connections.has(busId) || this.connections.get(busId) === connection) {
            this.connections.delete(busId);
            this.createConnection(busId, attempts);
          }
        }, delay);
      } else {
        // Max attempts reached — stop trying
        this.connections.delete(busId);
      }
    };
  }

  /**
   * Emit event to all listeners
   */
  private emit(busId: string, data: WebSocketMessage): void {
    const listeners = this.listeners.get(busId);
    if (listeners) {
      listeners.forEach((callback) => callback(data));
    }
  }
}

// Export singleton instance
export const busWebSocketService = new BusWebSocketService();
