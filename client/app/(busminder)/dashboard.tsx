import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, RefreshControl } from 'react-native';
import { useAuth } from '../../src/contexts/AuthContext';
import { apiService } from '../../src/services/api';
import { Student } from '../../src/types';

export default function BusminderDashboard() {
  const { user, logout } = useAuth();
  const [students, setStudents] = useState<Student[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadStudents = async () => {
    try {
      const response = await apiService.getBusminderStudents();
      setStudents(response.students);
    } catch (error) {
      console.error('Failed to load students:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadStudents();
    setRefreshing(false);
  };

  useEffect(() => {
    loadStudents();
  }, []);

  const getAttendanceCount = () => {
    const present = students.filter(s => s.attendance === true).length;
    const absent = students.filter(s => s.attendance === false).length;
    const pending = students.filter(s => s.attendance === null).length;
    return { present, absent, pending };
  };

  const { present, absent, pending } = getAttendanceCount();

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

      <View style={styles.summaryContainer}>
        <Text style={styles.summaryTitle}>Today's Attendance Summary</Text>
        <View style={styles.summaryRow}>
          <View style={[styles.summaryCard, { backgroundColor: '#34C759' }]}>
            <Text style={styles.summaryNumber}>{present}</Text>
            <Text style={styles.summaryLabel}>Present</Text>
          </View>
          <View style={[styles.summaryCard, { backgroundColor: '#FF3B30' }]}>
            <Text style={styles.summaryNumber}>{absent}</Text>
            <Text style={styles.summaryLabel}>Absent</Text>
          </View>
          <View style={[styles.summaryCard, { backgroundColor: '#8E8E93' }]}>
            <Text style={styles.summaryNumber}>{pending}</Text>
            <Text style={styles.summaryLabel}>Pending</Text>
          </View>
        </View>
      </View>

      <View style={styles.studentsSection}>
        <Text style={styles.sectionTitle}>Today's Students ({students.length})</Text>

        {students.map((student) => (
          <View key={student.id} style={styles.studentCard}>
            <View style={styles.studentInfo}>
              <Text style={styles.studentName}>{student.name}</Text>
              <Text style={styles.studentClass}>Class: {student.class}</Text>
              <Text style={styles.parentPhone}>Parent: {student.parent_phone}</Text>
            </View>

            <View style={styles.attendanceStatus}>
              {student.attendance === null && (
                <Text style={styles.pendingText}>Pending</Text>
              )}
              {student.attendance === true && (
                <Text style={styles.presentText}>✓ Present</Text>
              )}
              {student.attendance === false && (
                <Text style={styles.absentText}>✗ Absent</Text>
              )}
            </View>
          </View>
        ))}
      </View>

      <View style={styles.actionSection}>
        <TouchableOpacity style={styles.markAttendanceButton}>
          <Text style={styles.buttonText}>Mark Attendance</Text>
        </TouchableOpacity>
      </View>
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
    backgroundColor: '#FF9500',
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
  summaryContainer: {
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
  summaryTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 15,
    textAlign: 'center',
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  summaryCard: {
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
    minWidth: 80,
  },
  summaryNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
  },
  summaryLabel: {
    fontSize: 12,
    color: '#fff',
    marginTop: 4,
  },
  studentsSection: {
    margin: 15,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 15,
  },
  studentCard: {
    backgroundColor: '#fff',
    padding: 15,
    borderRadius: 10,
    marginBottom: 10,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  studentInfo: {
    flex: 1,
  },
  studentName: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 2,
  },
  studentClass: {
    fontSize: 14,
    color: '#666',
    marginBottom: 2,
  },
  parentPhone: {
    fontSize: 12,
    color: '#8E8E93',
  },
  attendanceStatus: {
    alignItems: 'center',
  },
  pendingText: {
    color: '#8E8E93',
    fontWeight: '500',
  },
  presentText: {
    color: '#34C759',
    fontWeight: '600',
  },
  absentText: {
    color: '#FF3B30',
    fontWeight: '600',
  },
  actionSection: {
    padding: 15,
  },
  markAttendanceButton: {
    backgroundColor: '#FF9500',
    padding: 15,
    borderRadius: 10,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
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