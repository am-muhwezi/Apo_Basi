import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/AuthContext';
import { apiService } from '../../src/services/api';
import { Route } from '../../src/types';

export default function DriverDashboard() {
  const { user, logout } = useAuth();
  const [route, setRoute] = useState<Route | null>(null);
  const [isLocationSharing, setIsLocationSharing] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadRoute();
  }, []);

  const loadRoute = async () => {
    try {
      const response = await apiService.getDriverRoute();
      setRoute(response.route);
    } catch (error) {
      console.error('Failed to load route:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleLocationSharing = () => {
    setIsLocationSharing(!isLocationSharing);
    Alert.alert(
      'Location Sharing',
      `Location sharing ${!isLocationSharing ? 'enabled' : 'disabled'}`
    );
  };

  const startRoute = () => {
    Alert.alert(
      'Start Route',
      'Are you ready to start your route?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Start',
          onPress: () => {
            setRoute(prev => prev ? { ...prev, status: 'active' } : null);
            Alert.alert('Route Started', 'Your route is now active. Location sharing enabled.');
            setIsLocationSharing(true);
          }
        },
      ]
    );
  };

  const endRoute = () => {
    Alert.alert(
      'End Route',
      'Are you sure you want to end your route?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'End Route',
          onPress: () => {
            setRoute(prev => prev ? { ...prev, status: 'completed' } : null);
            Alert.alert('Route Completed', 'Your route has been marked as completed.');
            setIsLocationSharing(false);
          },
          style: 'destructive'
        },
      ]
    );
  };

  if (isLoading) {
    return (
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.welcomeText}>Welcome, {user?.name}</Text>
        <TouchableOpacity onPress={logout} style={styles.logoutButton}>
          <Text style={styles.logoutText}>Logout</Text>
        </TouchableOpacity>
      </View>

      {route && (
        <>
          <View style={styles.routeCard}>
            <Text style={styles.routeTitle}>Today's Route</Text>
            <View style={styles.routeInfo}>
              <Text style={styles.routeName}>{route.name}</Text>
              <Text style={styles.routeDetails}>Students: {route.student_count}</Text>
              <View style={styles.statusRow}>
                <Text style={styles.statusLabel}>Status:</Text>
                <Text style={[
                  styles.statusText,
                  route.status === 'active' ? styles.activeStatus :
                  route.status === 'completed' ? styles.completedStatus :
                  styles.inactiveStatus
                ]}>
                  {route.status === 'active' ? 'Active' :
                   route.status === 'completed' ? 'Completed' :
                   'Not Started'}
                </Text>
              </View>
            </View>
          </View>

          <View style={styles.controlsCard}>
            <Text style={styles.controlsTitle}>Route Controls</Text>

            <TouchableOpacity
              style={[styles.locationButton, isLocationSharing && styles.locationActiveButton]}
              onPress={toggleLocationSharing}
            >
              <Ionicons
                name={isLocationSharing ? "location" : "location-outline"}
                size={20}
                color={isLocationSharing ? "#fff" : "#34C759"}
              />
              <Text style={[
                styles.locationButtonText,
                isLocationSharing && styles.locationActiveButtonText
              ]}>
                {isLocationSharing ? 'Location Sharing: ON' : 'Location Sharing: OFF'}
              </Text>
            </TouchableOpacity>

            {route.status === 'inactive' && (
              <TouchableOpacity style={styles.startButton} onPress={startRoute}>
                <Ionicons name="play" size={20} color="#fff" />
                <Text style={styles.startButtonText}>Start Route</Text>
              </TouchableOpacity>
            )}

            {route.status === 'active' && (
              <TouchableOpacity style={styles.endButton} onPress={endRoute}>
                <Ionicons name="stop" size={20} color="#fff" />
                <Text style={styles.endButtonText}>End Route</Text>
              </TouchableOpacity>
            )}
          </View>

          <View style={styles.statsCard}>
            <Text style={styles.statsTitle}>Today's Statistics</Text>
            <View style={styles.statsRow}>
              <View style={styles.statItem}>
                <Text style={styles.statNumber}>{route.student_count}</Text>
                <Text style={styles.statLabel}>Total Students</Text>
              </View>
              <View style={styles.statItem}>
                <Text style={styles.statNumber}>0</Text>
                <Text style={styles.statLabel}>Stops Completed</Text>
              </View>
              <View style={styles.statItem}>
                <Text style={styles.statNumber}>5</Text>
                <Text style={styles.statLabel}>Total Stops</Text>
              </View>
            </View>
          </View>

          <View style={styles.emergencyCard}>
            <TouchableOpacity style={styles.emergencyButton}>
              <Ionicons name="warning" size={24} color="#FF3B30" />
              <Text style={styles.emergencyText}>Emergency Contact</Text>
            </TouchableOpacity>
          </View>
        </>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#34C759',
  },
  welcomeText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#fff',
  },
  logoutButton: {
    padding: 8,
    backgroundColor: 'rgba(255,255,255,0.2)',
    borderRadius: 6,
  },
  logoutText: {
    color: '#fff',
    fontSize: 14,
  },
  routeCard: {
    backgroundColor: '#fff',
    margin: 15,
    padding: 15,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  routeTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 10,
  },
  routeInfo: {
    backgroundColor: '#F8F9FA',
    padding: 12,
    borderRadius: 8,
  },
  routeName: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 4,
  },
  routeDetails: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statusLabel: {
    fontSize: 14,
    fontWeight: '500',
    marginRight: 8,
  },
  statusText: {
    fontSize: 14,
    fontWeight: '600',
  },
  activeStatus: {
    color: '#34C759',
  },
  completedStatus: {
    color: '#007AFF',
  },
  inactiveStatus: {
    color: '#8E8E93',
  },
  controlsCard: {
    backgroundColor: '#fff',
    margin: 15,
    padding: 15,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  controlsTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 15,
  },
  locationButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 15,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: '#34C759',
    marginBottom: 10,
  },
  locationActiveButton: {
    backgroundColor: '#34C759',
    borderColor: '#34C759',
  },
  locationButtonText: {
    marginLeft: 8,
    fontSize: 16,
    fontWeight: '600',
    color: '#34C759',
  },
  locationActiveButtonText: {
    color: '#fff',
  },
  startButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#34C759',
    padding: 15,
    borderRadius: 10,
  },
  startButtonText: {
    marginLeft: 8,
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  endButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FF3B30',
    padding: 15,
    borderRadius: 10,
  },
  endButtonText: {
    marginLeft: 8,
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  statsCard: {
    backgroundColor: '#fff',
    margin: 15,
    padding: 15,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  statsTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 15,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#34C759',
  },
  statLabel: {
    fontSize: 12,
    color: '#666',
    marginTop: 4,
  },
  emergencyCard: {
    margin: 15,
  },
  emergencyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fff',
    padding: 15,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: '#FF3B30',
  },
  emergencyText: {
    marginLeft: 8,
    fontSize: 16,
    fontWeight: '600',
    color: '#FF3B30',
  },
  loadingText: {
    textAlign: 'center',
    marginTop: 50,
    fontSize: 16,
    color: '#666',
  },
});