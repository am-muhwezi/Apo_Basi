import React from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { useAuth } from '../../src/contexts/AuthContext';

export default function DriverProfile() {
  const { user, logout } = useAuth();

  const handleLogout = () => {
    Alert.alert(
      'Logout',
      'Are you sure you want to logout?',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Logout', onPress: logout, style: 'destructive' },
      ]
    );
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.profileHeader}>
        <Text style={styles.name}>{user?.name}</Text>
        <Text style={styles.email}>{user?.email}</Text>
        <Text style={styles.role}>Driver Account</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Driver Information</Text>
        <View style={styles.driverInfo}>
          <Text style={styles.infoText}>License: DL123456789</Text>
          <Text style={styles.infoText}>CDL Class: B</Text>
          <Text style={styles.infoText}>Experience: 5 years</Text>
          <Text style={styles.infoText}>Status: Active</Text>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Vehicle Assignment</Text>
        <View style={styles.vehicleInfo}>
          <Text style={styles.infoText}>Bus Number: B001</Text>
          <Text style={styles.infoText}>Model: Blue Bird Vision</Text>
          <Text style={styles.infoText}>Capacity: 72 passengers</Text>
          <Text style={styles.infoText}>Last Inspection: Dec 15, 2024</Text>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Route Assignment</Text>
        <View style={styles.routeInfo}>
          <Text style={styles.infoText}>Route: Route A</Text>
          <Text style={styles.infoText}>Students: 15</Text>
          <Text style={styles.infoText}>Stops: 5</Text>
          <Text style={styles.infoText}>Duration: 60 minutes</Text>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Emergency Contacts</Text>
        <View style={styles.contactInfo}>
          <Text style={styles.infoText}>Dispatch: +1 (555) 911-0000</Text>
          <Text style={styles.infoText}>School: +1 (555) 123-4567</Text>
          <Text style={styles.infoText}>Supervisor: +1 (555) 987-6543</Text>
          <Text style={styles.infoText}>Emergency: 911</Text>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Driver Tools</Text>
        <TouchableOpacity style={styles.toolItem}>
          <Text style={styles.toolText}>Vehicle Inspection Checklist</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.toolItem}>
          <Text style={styles.toolText}>Route Schedule</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.toolItem}>
          <Text style={styles.toolText}>Student Manifest</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.toolItem}>
          <Text style={styles.toolText}>Incident Report</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.toolItem}>
          <Text style={styles.toolText}>Safety Procedures</Text>
        </TouchableOpacity>
      </View>

      <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
        <Text style={styles.logoutText}>Logout</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7',
  },
  profileHeader: {
    backgroundColor: '#34C759',
    padding: 30,
    alignItems: 'center',
  },
  name: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 5,
  },
  email: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.8)',
    marginBottom: 5,
  },
  role: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.6)',
  },
  section: {
    backgroundColor: '#fff',
    margin: 15,
    borderRadius: 10,
    padding: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 15,
    color: '#333',
  },
  driverInfo: {
    backgroundColor: '#F8F9FA',
    padding: 12,
    borderRadius: 8,
  },
  vehicleInfo: {
    backgroundColor: '#F8F9FA',
    padding: 12,
    borderRadius: 8,
  },
  routeInfo: {
    backgroundColor: '#F8F9FA',
    padding: 12,
    borderRadius: 8,
  },
  contactInfo: {
    backgroundColor: '#F8F9FA',
    padding: 12,
    borderRadius: 8,
  },
  infoText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 4,
  },
  toolItem: {
    paddingVertical: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5EA',
  },
  toolText: {
    fontSize: 16,
    color: '#333',
  },
  logoutButton: {
    backgroundColor: '#FF3B30',
    margin: 15,
    padding: 15,
    borderRadius: 10,
    alignItems: 'center',
  },
  logoutText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});