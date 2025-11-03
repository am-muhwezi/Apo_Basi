import React, { useState, useEffect } from 'react';
import {
  Calendar,
  Users,
  CheckCircle,
  XCircle,
  Clock,
  Download,
  Filter,
  Search,
  ChevronLeft,
  ChevronRight,
  TrendingUp,
  AlertTriangle,
} from 'lucide-react';

interface AttendanceRecord {
  id: string;
  childName: string;
  class: string;
  busNumber: string;
  route: string;
  pickupTime: string;
  dropoffTime: string;
  status: 'present' | 'absent' | 'late' | 'early_dismissal';
  parentNotified: boolean;
}

interface DailyStats {
  total: number;
  present: number;
  absent: number;
  late: number;
  attendanceRate: number;
}

export default function AttendancePage() {
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [tripType, setTripType] = useState<'pickup' | 'dropoff'>('pickup');
  const [loading, setLoading] = useState(false);

  // Mock data - replace with actual API calls
  const dailyStats: DailyStats = {
    total: 856,
    present: 742,
    absent: 28,
    late: 86,
    attendanceRate: 96.4,
  };

  const attendanceRecords: AttendanceRecord[] = [
    {
      id: '1',
      childName: 'Sarah Johnson',
      class: 'Grade 5A',
      busNumber: 'BUS-001',
      route: 'Route A - North',
      pickupTime: '07:15 AM',
      dropoffTime: '03:45 PM',
      status: 'present',
      parentNotified: true,
    },
    {
      id: '2',
      childName: 'Michael Chen',
      class: 'Grade 4B',
      busNumber: 'BUS-002',
      route: 'Route B - East',
      pickupTime: '07:30 AM',
      dropoffTime: '04:00 PM',
      status: 'present',
      parentNotified: true,
    },
    {
      id: '3',
      childName: 'Emily Rodriguez',
      class: 'Grade 6A',
      busNumber: 'BUS-001',
      route: 'Route A - North',
      pickupTime: '07:45 AM',
      dropoffTime: '-',
      status: 'late',
      parentNotified: true,
    },
    {
      id: '4',
      childName: 'James Williams',
      class: 'Grade 3C',
      busNumber: 'BUS-003',
      route: 'Route C - South',
      pickupTime: '-',
      dropoffTime: '-',
      status: 'absent',
      parentNotified: true,
    },
    {
      id: '5',
      childName: 'Olivia Brown',
      class: 'Grade 5B',
      busNumber: 'BUS-002',
      route: 'Route B - East',
      pickupTime: '07:20 AM',
      dropoffTime: '02:30 PM',
      status: 'early_dismissal',
      parentNotified: true,
    },
  ];

  const getStatusBadge = (status: AttendanceRecord['status']) => {
    const badges = {
      present: {
        icon: <CheckCircle size={16} />,
        text: 'Present',
        className: 'bg-green-100 text-green-700 border-green-200',
      },
      absent: {
        icon: <XCircle size={16} />,
        text: 'Absent',
        className: 'bg-red-100 text-red-700 border-red-200',
      },
      late: {
        icon: <Clock size={16} />,
        text: 'Late',
        className: 'bg-yellow-100 text-yellow-700 border-yellow-200',
      },
      early_dismissal: {
        icon: <AlertTriangle size={16} />,
        text: 'Early Dismissal',
        className: 'bg-orange-100 text-orange-700 border-orange-200',
      },
    };

    const badge = badges[status];
    return (
      <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-medium border ${badge.className}`}>
        {badge.icon}
        {badge.text}
      </span>
    );
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const changeDate = (days: number) => {
    const newDate = new Date(selectedDate);
    newDate.setDate(newDate.getDate() + days);
    setSelectedDate(newDate);
  };

  const filteredRecords = attendanceRecords.filter((record) => {
    const matchesSearch =
      record.childName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      record.busNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      record.route.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesStatus = statusFilter === 'all' || record.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900 mb-2">Attendance Tracking</h1>
        <p className="text-slate-600">Monitor and manage daily student attendance</p>
      </div>

      {/* Date Selector and Trip Type */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6 mb-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
          {/* Date Navigation */}
          <div className="flex items-center justify-between md:justify-start flex-1">
            <button
              onClick={() => changeDate(-1)}
              className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
            >
              <ChevronLeft size={20} className="text-slate-600" />
            </button>

            <div className="flex items-center gap-3 mx-4">
              <Calendar className="text-blue-600" size={24} />
              <div className="text-center">
                <p className="text-lg font-semibold text-slate-900">{formatDate(selectedDate)}</p>
                <button
                  onClick={() => setSelectedDate(new Date())}
                  className="text-sm text-blue-600 hover:text-blue-700 font-medium"
                >
                  Go to Today
                </button>
              </div>
            </div>

            <button
              onClick={() => changeDate(1)}
              className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
            >
              <ChevronRight size={20} className="text-slate-600" />
            </button>
          </div>

          {/* Trip Type Selector */}
          <div className="flex gap-2">
            <button
              onClick={() => setTripType('pickup')}
              className={`flex items-center gap-2 px-6 py-3 rounded-lg font-medium transition-colors ${
                tripType === 'pickup'
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              Pickup Trip
            </button>
            <button
              onClick={() => setTripType('dropoff')}
              className={`flex items-center gap-2 px-6 py-3 rounded-lg font-medium transition-colors ${
                tripType === 'dropoff'
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              Dropoff Trip
            </button>
          </div>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Users className="w-6 h-6 text-blue-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Students</h3>
          <p className="text-3xl font-bold text-slate-900">{dailyStats.total}</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-green-100 rounded-lg">
              <CheckCircle className="w-6 h-6 text-green-600" />
            </div>
            <span className="text-sm text-green-600 font-medium">
              {((dailyStats.present / dailyStats.total) * 100).toFixed(1)}%
            </span>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Present</h3>
          <p className="text-3xl font-bold text-slate-900">{dailyStats.present}</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-red-100 rounded-lg">
              <XCircle className="w-6 h-6 text-red-600" />
            </div>
            <span className="text-sm text-red-600 font-medium">
              {((dailyStats.absent / dailyStats.total) * 100).toFixed(1)}%
            </span>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Absent</h3>
          <p className="text-3xl font-bold text-slate-900">{dailyStats.absent}</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="p-2 bg-yellow-100 rounded-lg">
              <Clock className="w-6 h-6 text-yellow-600" />
            </div>
            <span className="text-sm text-yellow-600 font-medium">
              {((dailyStats.late / dailyStats.total) * 100).toFixed(1)}%
            </span>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Late Arrivals</h3>
          <p className="text-3xl font-bold text-slate-900">{dailyStats.late}</p>
        </div>
      </div>

      {/* Filters and Actions */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6 mb-6">
        <div className="flex flex-col md:flex-row gap-4">
          {/* Search */}
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" size={20} />
            <input
              type="text"
              placeholder="Search by student name, bus, or route..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Status Filter */}
          <div className="flex items-center gap-2">
            <Filter size={20} className="text-slate-600" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All Status</option>
              <option value="present">Present</option>
              <option value="absent">Absent</option>
              <option value="late">Late</option>
              <option value="early_dismissal">Early Dismissal</option>
            </select>
          </div>

          {/* Export Button */}
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
            <Download size={20} />
            Export Report
          </button>
        </div>
      </div>

      {/* Attendance Table */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Student
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Class
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Bus / Route
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  {tripType === 'pickup' ? 'Pickup Time' : 'Dropoff Time'}
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Parent Notified
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {filteredRecords.length > 0 ? (
                filteredRecords.map((record) => (
                  <tr key={record.id} className="hover:bg-slate-50 transition-colors">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="font-medium text-slate-900">{record.childName}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-slate-900">{record.class}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-slate-900">{record.busNumber}</div>
                      <div className="text-xs text-slate-500">{record.route}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
                      {tripType === 'pickup' ? record.pickupTime : record.dropoffTime}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {getStatusBadge(record.status)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {record.parentNotified ? (
                        <CheckCircle className="text-green-600" size={20} />
                      ) : (
                        <XCircle className="text-slate-300" size={20} />
                      )}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-500">
                    No attendance records found
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
}
