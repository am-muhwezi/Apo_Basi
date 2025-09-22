import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { apiService } from '../../src/services/api';
import { Student } from '../../src/types';

export default function AttendanceScreen() {
  const [students, setStudents] = useState<Student[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadStudents();
  }, []);

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

  const markAttendance = async (studentId: number, status: 'present' | 'absent') => {
    try {
      await apiService.markAttendance(studentId, status);

      // Update local state
      setStudents(students.map(student =>
        student.id === studentId
          ? { ...student, attendance: status === 'present' }
          : student
      ));

      Alert.alert('Success', `Attendance marked as ${status}`);
    } catch (error) {
      console.error('Failed to mark attendance:', error);
      Alert.alert('Error', 'Failed to mark attendance');
    }
  };

  const confirmAttendance = (student: Student, status: 'present' | 'absent') => {
    Alert.alert(
      'Confirm Attendance',
      `Mark ${student.name} as ${status}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Confirm',
          onPress: () => markAttendance(student.id, status)
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
        <Text style={styles.title}>Mark Attendance</Text>
        <Text style={styles.subtitle}>Tap Present or Absent for each student</Text>
      </View>

      {students.map((student) => (
        <View key={student.id} style={styles.studentCard}>
          <View style={styles.studentInfo}>
            <Text style={styles.studentName}>{student.name}</Text>
            <Text style={styles.studentClass}>Class: {student.class}</Text>
            <Text style={styles.parentPhone}>Parent: {student.parent_phone}</Text>
          </View>

          <View style={styles.attendanceButtons}>
            {student.attendance === null ? (
              <View style={styles.buttonGroup}>
                <TouchableOpacity
                  style={[styles.attendanceButton, styles.presentButton]}
                  onPress={() => confirmAttendance(student, 'present')}
                >
                  <Text style={styles.buttonText}>Present</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.attendanceButton, styles.absentButton]}
                  onPress={() => confirmAttendance(student, 'absent')}
                >
                  <Text style={styles.buttonText}>Absent</Text>
                </TouchableOpacity>
              </View>
            ) : (
              <View style={styles.statusContainer}>
                <Text style={[
                  styles.statusText,
                  student.attendance ? styles.presentStatus : styles.absentStatus
                ]}>
                  {student.attendance ? '✓ Present' : '✗ Absent'}
                </Text>
                <TouchableOpacity
                  style={styles.changeButton}
                  onPress={() => {
                    const newStatus = student.attendance ? 'absent' : 'present';
                    confirmAttendance(student, newStatus);
                  }}
                >
                  <Text style={styles.changeButtonText}>Change</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        </View>
      ))}

      <View style={styles.summarySection}>
        <Text style={styles.summaryTitle}>Summary</Text>
        <Text style={styles.summaryText}>
          Present: {students.filter(s => s.attendance === true).length}
        </Text>
        <Text style={styles.summaryText}>
          Absent: {students.filter(s => s.attendance === false).length}
        </Text>
        <Text style={styles.summaryText}>
          Pending: {students.filter(s => s.attendance === null).length}
        </Text>
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
    padding: 20,
    backgroundColor: '#fff',
    marginBottom: 15,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
  studentCard: {
    backgroundColor: '#fff',
    margin: 10,
    padding: 15,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  studentInfo: {
    marginBottom: 15,
  },
  studentName: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 4,
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
  attendanceButtons: {
    alignItems: 'flex-end',
  },
  buttonGroup: {
    flexDirection: 'row',
    gap: 10,
  },
  attendanceButton: {
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
    minWidth: 80,
    alignItems: 'center',
  },
  presentButton: {
    backgroundColor: '#34C759',
  },
  absentButton: {
    backgroundColor: '#FF3B30',
  },
  buttonText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 14,
  },
  statusContainer: {
    alignItems: 'center',
  },
  statusText: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 5,
  },
  presentStatus: {
    color: '#34C759',
  },
  absentStatus: {
    color: '#FF3B30',
  },
  changeButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#007AFF',
    borderRadius: 6,
  },
  changeButtonText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '500',
  },
  summarySection: {
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
    marginBottom: 10,
  },
  summaryText: {
    fontSize: 14,
    marginBottom: 4,
  },
  loadingText: {
    textAlign: 'center',
    marginTop: 50,
    fontSize: 16,
    color: '#666',
  },
});