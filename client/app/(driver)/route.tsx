import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { apiService } from '../../src/services/api';
import { Route } from '../../src/types';

export default function RouteScreen() {
  const [route, setRoute] = useState<Route | null>(null);
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

  const mockStops = [
    { id: 1, name: 'Lincoln Elementary School', address: '123 School St', time: '07:30', students: 3, completed: false },
    { id: 2, name: 'Maple Street Stop', address: '456 Maple St', time: '07:45', students: 2, completed: false },
    { id: 3, name: 'Oak Avenue Stop', address: '789 Oak Ave', time: '08:00', students: 4, completed: false },
    { id: 4, name: 'Pine Road Stop', address: '321 Pine Rd', time: '08:15', students: 3, completed: false },
    { id: 5, name: 'School Arrival', address: '123 School St', time: '08:30', students: 15, completed: false },
  ];

  if (isLoading) {
    return (
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      {route && (
        <>
          <View style={styles.routeHeader}>
            <Text style={styles.routeTitle}>{route.name}</Text>
            <View style={styles.routeStats}>
              <View style={styles.statItem}>
                <Text style={styles.statNumber}>{route.student_count}</Text>
                <Text style={styles.statLabel}>Students</Text>
              </View>
              <View style={styles.statItem}>
                <Text style={styles.statNumber}>5</Text>
                <Text style={styles.statLabel}>Stops</Text>
              </View>
              <View style={styles.statItem}>
                <Text style={styles.statNumber}>60</Text>
                <Text style={styles.statLabel}>Minutes</Text>
              </View>
            </View>
          </View>

          <View style={styles.stopsSection}>
            <Text style={styles.sectionTitle}>Route Stops</Text>

            {mockStops.map((stop, index) => (
              <View key={stop.id} style={styles.stopCard}>
                <View style={styles.stopHeader}>
                  <View style={styles.stopNumber}>
                    <Text style={styles.stopNumberText}>{index + 1}</Text>
                  </View>
                  <View style={styles.stopInfo}>
                    <Text style={styles.stopName}>{stop.name}</Text>
                    <Text style={styles.stopAddress}>{stop.address}</Text>
                  </View>
                  <View style={styles.stopTime}>
                    <Text style={styles.timeText}>{stop.time}</Text>
                  </View>
                </View>

                <View style={styles.stopDetails}>
                  <View style={styles.studentInfo}>
                    <Ionicons name="people" size={16} color="#666" />
                    <Text style={styles.studentCount}>{stop.students} students</Text>
                  </View>

                  {stop.completed ? (
                    <View style={styles.completedBadge}>
                      <Ionicons name="checkmark-circle" size={16} color="#34C759" />
                      <Text style={styles.completedText}>Completed</Text>
                    </View>
                  ) : (
                    <TouchableOpacity style={styles.completeButton}>
                      <Text style={styles.completeButtonText}>Mark Complete</Text>
                    </TouchableOpacity>
                  )}
                </View>
              </View>
            ))}
          </View>

          <View style={styles.routeActions}>
            <TouchableOpacity style={styles.navigationButton}>
              <Ionicons name="navigate" size={20} color="#fff" />
              <Text style={styles.navigationButtonText}>Start Navigation</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.emergencyButton}>
              <Ionicons name="call" size={20} color="#FF3B30" />
              <Text style={styles.emergencyButtonText}>Emergency Call</Text>
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
  routeHeader: {
    backgroundColor: '#34C759',
    padding: 20,
  },
  routeTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 15,
  },
  routeStats: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#fff',
  },
  statLabel: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.8)',
    marginTop: 2,
  },
  stopsSection: {
    padding: 15,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 15,
  },
  stopCard: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 15,
    marginBottom: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  stopHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  stopNumber: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: '#34C759',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  stopNumberText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 14,
  },
  stopInfo: {
    flex: 1,
  },
  stopName: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 2,
  },
  stopAddress: {
    fontSize: 14,
    color: '#666',
  },
  stopTime: {
    alignItems: 'center',
  },
  timeText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#34C759',
  },
  stopDetails: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#E5E5EA',
  },
  studentInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  studentCount: {
    marginLeft: 5,
    fontSize: 14,
    color: '#666',
  },
  completedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  completedText: {
    marginLeft: 5,
    fontSize: 14,
    color: '#34C759',
    fontWeight: '500',
  },
  completeButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#007AFF',
    borderRadius: 6,
  },
  completeButtonText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '500',
  },
  routeActions: {
    padding: 15,
    gap: 10,
  },
  navigationButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#34C759',
    padding: 15,
    borderRadius: 10,
  },
  navigationButtonText: {
    marginLeft: 8,
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  emergencyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fff',
    borderWidth: 2,
    borderColor: '#FF3B30',
    padding: 15,
    borderRadius: 10,
  },
  emergencyButtonText: {
    marginLeft: 8,
    color: '#FF3B30',
    fontSize: 16,
    fontWeight: '600',
  },
  loadingText: {
    textAlign: 'center',
    marginTop: 50,
    fontSize: 16,
    color: '#666',
  },
});