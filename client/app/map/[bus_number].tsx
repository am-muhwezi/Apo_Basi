import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  Animated,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import MapView, { Marker, Polyline, PROVIDER_GOOGLE } from 'react-native-maps';
import { apiService } from '../../src/services/api';
import { BusLocation, LocationHistory } from '../../src/types/index';

// Nairobi coordinates and configuration
const NAIROBI_COORDINATES = {
  latitude: -1.2921,
  longitude: 36.8219,
  latitudeDelta: 0.0922,
  longitudeDelta: 0.0421,
};

// Common Nairobi landmarks for reference
const NAIROBI_LANDMARKS = [
  { name: 'CBD', latitude: -1.2921, longitude: 36.8219 },
  { name: 'KICC', latitude: -1.2922, longitude: 36.8214 },
  { name: 'Uhuru Park', latitude: -1.2935, longitude: 36.8147 },
  { name: 'Westlands', latitude: -1.2639, longitude: 36.8003 },
  { name: 'Karen', latitude: -1.3194, longitude: 36.6853 },
  { name: 'Kasarani', latitude: -1.2258, longitude: 36.8917 },
];

export default function BusMapScreen() {
  const { bus_number, child_id } = useLocalSearchParams();
  const router = useRouter();

  const [busLocation, setBusLocation] = useState<BusLocation | null>(null);
  const [breadcrumbTrail, setBreadcrumbTrail] = useState<LocationHistory['breadcrumb_trail']>([]);
  const [loading, setLoading] = useState(true);
  const [following, setFollowing] = useState(true);

  const mapRef = useRef<MapView>(null);
  const pulseAnimation = useRef(new Animated.Value(0)).current;

  // Start pulse animation for live tracking
  useEffect(() => {
    const pulse = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnimation, {
          toValue: 1,
          duration: 1000,
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnimation, {
          toValue: 0,
          duration: 1000,
          useNativeDriver: true,
        }),
      ])
    );
    pulse.start();
    return () => pulse.stop();
  }, []);

  // Function to check if coordinates are within Nairobi bounds
  const isWithinNairobiBounds = (lat: number, lng: number) => {
    const nairobiBounds = {
      north: -1.163,
      south: -1.444,
      east: 37.103,
      west: 36.650,
    };
    return lat >= nairobiBounds.south && lat <= nairobiBounds.north &&
           lng >= nairobiBounds.west && lng <= nairobiBounds.east;
  };

  const loadBusLocation = async () => {
    try {
      if (!bus_number) return;

      const [locationData, trailData] = await Promise.all([
        apiService.getBusLocation(bus_number as string),
        apiService.getBusTrail(bus_number as string)
      ]);

      setBusLocation(locationData);
      setBreadcrumbTrail(trailData.breadcrumb_trail || []);

      // Auto-focus on bus location if following and within Nairobi bounds
      if (following && locationData && mapRef.current) {
        const { latitude, longitude } = locationData.current_position;

        // Use bus location if within Nairobi, otherwise default to Nairobi center
        const targetRegion = isWithinNairobiBounds(latitude, longitude) ? {
          latitude,
          longitude,
          latitudeDelta: 0.01,
          longitudeDelta: 0.01,
        } : {
          ...NAIROBI_COORDINATES,
          latitudeDelta: 0.05,
          longitudeDelta: 0.05,
        };

        mapRef.current.animateToRegion(targetRegion, 1000);
      }
    } catch (error) {
      console.error('Error loading bus location:', error);
      Alert.alert('Error', 'Failed to load bus location');
    } finally {
      setLoading(false);
    }
  };

  // Load data on mount and set up polling for real-time updates
  useEffect(() => {
    loadBusLocation();

    // Poll for updates every 30 seconds
    const interval = setInterval(loadBusLocation, 30000);
    return () => clearInterval(interval);
  }, [bus_number]);

  const handleFollowBus = () => {
    setFollowing(true);
    if (busLocation && mapRef.current) {
      const { latitude, longitude } = busLocation.current_position;

      // Use bus location if within Nairobi, otherwise show Nairobi overview
      const targetRegion = isWithinNairobiBounds(latitude, longitude) ? {
        latitude,
        longitude,
        latitudeDelta: 0.01,
        longitudeDelta: 0.01,
      } : NAIROBI_COORDINATES;

      mapRef.current.animateToRegion(targetRegion, 1000);
    } else if (mapRef.current) {
      // No bus location, show Nairobi center
      mapRef.current.animateToRegion(NAIROBI_COORDINATES, 1000);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return '#4CAF50';
      case 'idle': return '#FF9800';
      case 'maintenance': return '#F44336';
      default: return '#9E9E9E';
    }
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>Loading bus location...</Text>
      </View>
    );
  }

  if (!busLocation) {
    return (
      <View style={styles.errorContainer}>
        <Ionicons name="warning-outline" size={64} color="#F44336" />
        <Text style={styles.errorTitle}>Bus Not Found</Text>
        <Text style={styles.errorText}>Unable to locate bus {bus_number}</Text>
        <TouchableOpacity style={styles.retryButton} onPress={loadBusLocation}>
          <Text style={styles.retryText}>Retry</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const pulseScale = pulseAnimation.interpolate({
    inputRange: [0, 1],
    outputRange: [1, 1.3],
  });

  const pulseOpacity = pulseAnimation.interpolate({
    inputRange: [0, 1],
    outputRange: [0.7, 0.3],
  });

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color="#1A1A1A" />
        </TouchableOpacity>

        <View style={styles.headerInfo}>
          <Text style={styles.busTitle}>Bus {bus_number}</Text>
          <View style={[styles.statusBadge, { backgroundColor: getStatusColor(busLocation.status) }]}>
            <Text style={styles.statusText}>{busLocation.status.toUpperCase()}</Text>
          </View>
        </View>

        <TouchableOpacity style={styles.followButton} onPress={handleFollowBus}>
          <Ionicons name="locate" size={20} color="#007AFF" />
        </TouchableOpacity>
      </View>

      {/* Map */}
      <MapView
        ref={mapRef}
        style={styles.map}
        provider={PROVIDER_GOOGLE}
        initialRegion={
          busLocation && isWithinNairobiBounds(
            busLocation.current_position.latitude,
            busLocation.current_position.longitude
          ) ? {
            latitude: busLocation.current_position.latitude,
            longitude: busLocation.current_position.longitude,
            latitudeDelta: 0.01,
            longitudeDelta: 0.01,
          } : NAIROBI_COORDINATES
        }
        onRegionChangeStart={() => setFollowing(false)}
        showsUserLocation
        showsMyLocationButton={false}
        showsTraffic
        showsBuildings
        showsIndoors
        loadingEnabled
        maxZoomLevel={18}
        minZoomLevel={10}
      >
        {/* Nairobi Landmarks (show when zoomed out) */}
        {NAIROBI_LANDMARKS.map((landmark, index) => (
          <Marker
            key={`landmark-${index}`}
            coordinate={{
              latitude: landmark.latitude,
              longitude: landmark.longitude,
            }}
            title={landmark.name}
            description="Nairobi Landmark"
          >
            <View style={styles.landmarkMarker}>
              <Ionicons name="location" size={16} color="#6366f1" />
            </View>
          </Marker>
        ))}

        {/* Breadcrumb Trail */}
        {breadcrumbTrail.length > 1 && (
          <Polyline
            coordinates={breadcrumbTrail.map(point => ({
              latitude: point.latitude,
              longitude: point.longitude,
            }))}
            strokeColor="#6366f1"
            strokeWidth={4}
            strokePattern={[1, 10]}
          />
        )}

        {/* Bus Marker with Animation */}
        {busLocation && (
          <Marker
            coordinate={{
              latitude: busLocation.current_position.latitude,
              longitude: busLocation.current_position.longitude,
            }}
            rotation={busLocation.current_position.heading || 0}
            anchor={{ x: 0.5, y: 0.5 }}
            title={`Bus ${bus_number}`}
            description={`Status: ${busLocation.status}`}
          >
            <View style={styles.busMarkerContainer}>
              {/* Animated Pulse Effect */}
              <Animated.View
                style={[
                  styles.pulseDot,
                  {
                    transform: [{ scale: pulseScale }],
                    opacity: pulseOpacity,
                  },
                ]}
              />
              <View style={[styles.busMarker, { backgroundColor: getStatusColor(busLocation.status) }]}>
                <Ionicons name="bus" size={24} color="white" />
              </View>
            </View>
          </Marker>
        )}
      </MapView>

      {/* Bottom Info Panel */}
      <View style={styles.bottomPanel}>
        <View style={styles.infoRow}>
          <View style={styles.infoItem}>
            <Ionicons name="speedometer-outline" size={20} color="#666" />
            <Text style={styles.infoLabel}>Speed</Text>
            <Text style={styles.infoValue}>
              {busLocation.current_position.speed || 0} km/h
            </Text>
          </View>

          <View style={styles.divider} />

          <View style={styles.infoItem}>
            <Ionicons name="time-outline" size={20} color="#666" />
            <Text style={styles.infoLabel}>ETA</Text>
            <Text style={styles.infoValue}>{busLocation.estimated_arrival}</Text>
          </View>

          <View style={styles.divider} />

          <View style={styles.infoItem}>
            <Ionicons name="analytics-outline" size={20} color="#666" />
            <Text style={styles.infoLabel}>Progress</Text>
            <Text style={styles.infoValue}>{busLocation.route_progress}%</Text>
          </View>
        </View>

        <View style={styles.progressBar}>
          <View
            style={[
              styles.progressFill,
              { width: `${busLocation.route_progress}%` },
            ]}
          />
        </View>

        <Text style={styles.lastUpdate}>
          Last updated: {new Date(busLocation.last_updated).toLocaleTimeString()}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8F9FA',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F8F9FA',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F8F9FA',
    padding: 40,
  },
  errorTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1A1A1A',
    marginTop: 16,
    marginBottom: 8,
  },
  errorText: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    marginBottom: 24,
  },
  retryButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  retryText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    paddingTop: 60,
    backgroundColor: 'white',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  backButton: {
    padding: 8,
  },
  headerInfo: {
    flex: 1,
    marginLeft: 16,
  },
  busTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1A1A1A',
    marginBottom: 4,
  },
  statusBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  statusText: {
    fontSize: 12,
    fontWeight: '600',
    color: 'white',
  },
  followButton: {
    padding: 8,
    backgroundColor: '#E3F2FD',
    borderRadius: 20,
  },
  map: {
    flex: 1,
  },
  landmarkMarker: {
    width: 28,
    height: 28,
    backgroundColor: 'rgba(99, 102, 241, 0.1)',
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#6366f1',
  },
  busMarkerContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  pulseDot: {
    position: 'absolute',
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#6366f1',
  },
  busMarker: {
    width: 44,
    height: 44,
    backgroundColor: '#6366f1',
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 4,
    borderColor: 'white',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 8,
  },
  bottomPanel: {
    backgroundColor: 'white',
    paddingHorizontal: 20,
    paddingVertical: 24,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 5,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  infoItem: {
    flex: 1,
    alignItems: 'center',
  },
  infoLabel: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
    marginBottom: 2,
  },
  infoValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1A1A1A',
  },
  divider: {
    width: 1,
    height: 40,
    backgroundColor: '#E0E0E0',
    marginHorizontal: 16,
  },
  progressBar: {
    height: 4,
    backgroundColor: '#E0E0E0',
    borderRadius: 2,
    marginBottom: 12,
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#4CAF50',
    borderRadius: 2,
  },
  lastUpdate: {
    fontSize: 12,
    color: '#999',
    textAlign: 'center',
  },
});