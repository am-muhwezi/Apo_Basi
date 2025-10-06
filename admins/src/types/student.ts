export interface Student {
  id: string;
  name: string;
  grade: string;
  route: string;
  busId: string;
  pickupTime: string;
  dropoffTime: string;
  address: string;
  parentName: string;
  parentPhone: string;
  checkInStatus: 'checked-in' | 'not-checked-in' | 'absent';
  emergencyContact: string;
  medicalNotes?: string;
}

export interface StudentFilters {
  search: string;
  route: string;
  grade: string;
  checkInStatus: string;
}