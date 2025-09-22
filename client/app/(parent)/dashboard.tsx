import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, RefreshControl } from 'react-native';
import { useAuth } from '../../src/contexts/AuthContext';
import { apiService } from '../../src/services/api';
import { Child } from '../../src/types';

export default function ParentDashboard() {
  const { user, logout } = useAuth();
  const [children, setChildren] = useState<Child[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadDashboard = async () => {
    try {
      const response = await apiService.getParentDashboard();
      setChildren(response.children);
    } catch (error) {
      console.error('Failed to load dashboard:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadDashboard();
    setRefreshing(false);
  };

  useEffect(() => {
    loadDashboard();
  }, []);

  const getStatusColor = (status: Child['bus_status']) => {
    switch (status) {
      case 'on_route': return '#FF9500';
      case 'arrived': return '#34C759';
      case 'delayed': return '#FF3B30';
      default: return '#8E8E93';
    }
  };

  const getStatusText = (status: Child['bus_status']) => {
    switch (status) {
      case 'on_route': return 'On Route';
      case 'arrived': return 'Arrived';
      case 'delayed': return 'Delayed';
      default: return 'Not Started';
    }
  };

  if (isLoading) {
    return (
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    >
      <View style={styles.header}>
        <Text style={styles.welcomeText}>Welcome, {user?.name}</Text>
        <TouchableOpacity onPress={logout} style={styles.logoutButton}>
          <Text style={styles.logoutText}>Logout</Text>
        </TouchableOpacity>
      </View>

      <Text style={styles.sectionTitle}>Your Children</Text>

      {children.map((child) => (
        <View key={child.id} style={styles.childCard}>
          <View style={styles.childHeader}>
            <Text style={styles.childName}>{child.name}</Text>
            <View style={[styles.statusBadge, { backgroundColor: getStatusColor(child.bus_status) }]}>
              <Text style={styles.statusText}>{getStatusText(child.bus_status)}</Text>
            </View>
          </View>

          <View style={styles.childDetails}>
            <Text style={styles.detailText}>Class: {child.class}</Text>
            <Text style={styles.detailText}>Bus: {child.bus_number}</Text>
            <Text style={styles.detailText}>Pickup: {child.pickup_time}</Text>
          </View>

          <View style={styles.attendanceRow}>
            <Text style={styles.attendanceLabel}>Today's Attendance:</Text>
            <Text style={[
              styles.attendanceStatus,
              { color: child.attendance ? '#34C759' : '#FF3B30' }
            ]}>
              {child.attendance ? '✓ Present' : '✗ Absent'}
            </Text>
          </View>
        </View>
      ))}
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
    backgroundColor: '#007AFF',
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
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    margin: 20,
    marginBottom: 15,
  },
  childCard: {
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
  childHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  childName: {
    fontSize: 18,
    fontWeight: '600',
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  statusText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  childDetails: {
    marginBottom: 10,
  },
  detailText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 2,
  },
  attendanceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#E5E5EA',
  },
  attendanceLabel: {
    fontSize: 14,
    fontWeight: '500',
  },
  attendanceStatus: {
    fontSize: 14,
    fontWeight: '600',
  },
  loadingText: {
    textAlign: 'center',
    marginTop: 50,
    fontSize: 16,
    color: '#666',
  },
});