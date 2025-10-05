import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity } from 'react-native';
import { apiService } from '../../src/services/api';
import { Child } from '../../src/types';

export default function ChildrenScreen() {
  const [children, setChildren] = useState<Child[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadChildren();
  }, []);

  const loadChildren = async () => {
    try {
      const response = await apiService.getParentDashboard();
      setChildren(response.children);
    } catch (error) {
      console.error('Failed to load children:', error);
    } finally {
      setIsLoading(false);
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
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Children Details</Text>

      {children.map((child) => (
        <View key={child.id} style={styles.childCard}>
          <View style={styles.childHeader}>
            <Text style={styles.childName}>{child.name}</Text>
          </View>

          <View style={styles.infoSection}>
            <Text style={styles.sectionTitle}>School Information</Text>
            <Text style={styles.infoText}>Class: {child.class}</Text>
            <Text style={styles.infoText}>Student ID: {child.id}</Text>
          </View>

          <View style={styles.infoSection}>
            <Text style={styles.sectionTitle}>Transportation</Text>
            <Text style={styles.infoText}>Bus Number: {child.bus_number}</Text>
            <Text style={styles.infoText}>Pickup Time: {child.pickup_time}</Text>
            <Text style={styles.infoText}>Current Status: {child.bus_status}</Text>
          </View>

          <TouchableOpacity style={styles.detailButton}>
            <Text style={styles.detailButtonText}>View Attendance History</Text>
          </TouchableOpacity>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7',
    padding: 15,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  childCard: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 20,
    marginBottom: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  childHeader: {
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5EA',
    paddingBottom: 15,
    marginBottom: 15,
  },
  childName: {
    fontSize: 20,
    fontWeight: '600',
  },
  infoSection: {
    marginBottom: 15,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
    color: '#007AFF',
  },
  infoText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 4,
  },
  detailButton: {
    backgroundColor: '#007AFF',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 10,
  },
  detailButtonText: {
    color: '#fff',
    fontWeight: '600',
  },
  loadingText: {
    textAlign: 'center',
    marginTop: 50,
    fontSize: 16,
    color: '#666',
  },
});