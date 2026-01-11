/**
 * Mapbox Service for Admin Dashboard
 * 
 * Provides:
 * - Snap-to-roads functionality
 * - Route polyline generation
 * - ETA calculations
 */

// Get Mapbox token from environment or use a placeholder
const MAPBOX_ACCESS_TOKEN = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN || 'YOUR_MAPBOX_TOKEN';

export interface LatLng {
  latitude: number;
  longitude: number;
}

export interface RouteResponse {
  coordinates: [number, number][]; // [lng, lat][]
  duration: number; // seconds
  distance: number; // meters
}

/**
 * Snap a single GPS coordinate to the nearest road
 */
export async function snapToRoad(
  location: LatLng
): Promise<LatLng | null> {
  try {
    const coords = `${location.longitude},${location.latitude}`;
    const url = `https://api.mapbox.com/matching/v5/mapbox/driving/${coords}?access_token=${MAPBOX_ACCESS_TOKEN}&radiuses=25`;

    const response = await fetch(url);
    if (!response.ok) {
      console.warn('Mapbox snap-to-road failed, using original coordinates');
      return location;
    }

    const data = await response.json();
    if (data.matchings && data.matchings.length > 0) {
      const snappedCoords = data.matchings[0].geometry.coordinates[0];
      return {
        latitude: snappedCoords[1],
        longitude: snappedCoords[0]
      };
    }

    return location;
  } catch (error) {
    console.error('Error snapping to road:', error);
    return location;
  }
}

/**
 * Get route polyline from origin to destination
 */
export async function getRoute(
  origin: LatLng,
  destination: LatLng
): Promise<RouteResponse | null> {
  try {
    const coords = `${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}`;
    const url = `https://api.mapbox.com/directions/v5/mapbox/driving/${coords}?geometries=geojson&overview=full&access_token=${MAPBOX_ACCESS_TOKEN}`;

    const response = await fetch(url);
    if (!response.ok) {
      console.error('Mapbox directions API failed');
      return null;
    }

    const data = await response.json();
    if (data.routes && data.routes.length > 0) {
      const route = data.routes[0];
      return {
        coordinates: route.geometry.coordinates,
        duration: route.duration,
        distance: route.distance
      };
    }

    return null;
  } catch (error) {
    console.error('Error fetching route:', error);
    return null;
  }
}

/**
 * Get route polyline from origin to multiple destinations
 */
export async function getMultiStopRoute(
  origin: LatLng,
  destinations: LatLng[]
): Promise<RouteResponse | null> {
  try {
    // Build coordinates string for all waypoints
    const allPoints = [origin, ...destinations];
    const coords = allPoints
      .map(p => `${p.longitude},${p.latitude}`)
      .join(';');

    const url = `https://api.mapbox.com/directions/v5/mapbox/driving/${coords}?geometries=geojson&overview=full&access_token=${MAPBOX_ACCESS_TOKEN}`;

    const response = await fetch(url);
    if (!response.ok) {
      console.error('Mapbox directions API failed');
      return null;
    }

    const data = await response.json();
    if (data.routes && data.routes.length > 0) {
      const route = data.routes[0];
      return {
        coordinates: route.geometry.coordinates,
        duration: route.duration,
        distance: route.distance
      };
    }

    return null;
  } catch (error) {
    console.error('Error fetching multi-stop route:', error);
    return null;
  }
}

/**
 * Format duration to human-readable string
 */
export function formatDuration(seconds: number): string {
  if (seconds < 60) {
    return `${Math.round(seconds)}s`;
  } else if (seconds < 3600) {
    const minutes = Math.floor(seconds / 60);
    return `${minutes}min`;
  } else {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}min`;
  }
}

/**
 * Format distance to human-readable string
 */
export function formatDistance(meters: number): string {
  if (meters < 1000) {
    return `${Math.round(meters)}m`;
  } else {
    return `${(meters / 1000).toFixed(1)}km`;
  }
}

/**
 * Check if Mapbox is configured
 */
export function isMapboxConfigured(): boolean {
  return MAPBOX_ACCESS_TOKEN !== 'YOUR_MAPBOX_TOKEN' && MAPBOX_ACCESS_TOKEN.length > 0;
}
