import { useState, useEffect } from 'react';
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
} from 'lucide-react';
import { getAttendanceStats, getDailyAttendanceReport } from '../services/api';

type AttendanceStatus = 'picked_up' | 'dropped_off' | 'absent' | 'pending';

interface AttendanceRecord {
  id: string;
  childName: string;
  class: string;
  busNumber: string;
  route: string;
  pickupTime: string;
  dropoffTime: string;
  pickupStatus: AttendanceStatus;
  dropoffStatus: AttendanceStatus;
  parentNotified: boolean;
}

interface DailyStats {
  total: number;
  picked_up: number;
  dropped_off: number;
  absent: number;
  pending: number;
  picked_up_percentage?: number;
  dropped_off_percentage?: number;
  absent_percentage?: number;
  pending_percentage?: number;
}

export default function AttendancePage() {
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [tripType, setTripType] = useState<'pickup' | 'dropoff'>('pickup');
  const [loading, setLoading] = useState(false);
  const [dailyStats, setDailyStats] = useState<DailyStats>({
    total: 0,
    picked_up: 0,
    dropped_off: 0,
    absent: 0,
    pending: 0,
  });
  const [attendanceRecords, setAttendanceRecords] = useState<AttendanceRecord[]>([]);

  // Fetch attendance data when date changes
  useEffect(() => {
    fetchAttendanceData();
  }, [selectedDate]);

  const fetchAttendanceData = async () => {
    setLoading(true);
    try {
      const dateStr = selectedDate.toISOString().split('T')[0];

      // Fetch stats
      const statsResponse = await getAttendanceStats(dateStr);
      setDailyStats(statsResponse.data);

      // Fetch daily report
      const reportResponse = await getDailyAttendanceReport(dateStr);

      // Helper function to format timestamp
      const formatTime = (timestamp: string | null) => {
        if (!timestamp) return '-';
        try {
          const date = new Date(timestamp);
          const hours = date.getHours();
          const minutes = date.getMinutes();
          const period = hours >= 12 ? 'PM' : 'AM';
          const displayHours = hours > 12 ? hours - 12 : hours === 0 ? 12 : hours;
          const displayMinutes = minutes.toString().padStart(2, '0');
          return `${displayHours}:${displayMinutes} ${period}`;
        } catch (error) {
          return '-';
        }
      };

      // Transform report data to match AttendanceRecord interface
      // Backend returns individual records per trip, we need to group by child
      const childRecordsMap = new Map<string, any>();
      
      reportResponse.data.buses.forEach((bus: any) => {
        bus.children.forEach((child: any) => {
          const childKey = `${bus.bus_number}-${child.id}`;
          const time = formatTime(child.timestamp);
          const tripType = child.trip_type;
          
          // Get or create child record
          if (!childRecordsMap.has(childKey)) {
            childRecordsMap.set(childKey, {
              id: child.id,
              childName: child.name,
              class: child.grade || 'N/A',
              busNumber: bus.bus_number,
              route: bus.bus_number,
              pickupTime: '-',
              dropoffTime: '-',
              pickupStatus: 'pending' as AttendanceStatus,
              dropoffStatus: 'pending' as AttendanceStatus,
              parentNotified: true,
              records: [], // Store both trip records
            });
          }
          
          const record = childRecordsMap.get(childKey);
          
          // Add time and status based on trip type
          if (tripType === 'pickup') {
            record.pickupTime = time;
            record.pickupStatus = child.status as AttendanceStatus;
            record.records.push({ type: 'pickup', status: child.status, time });
          } else if (tripType === 'dropoff') {
            record.dropoffTime = time;
            record.dropoffStatus = child.status as AttendanceStatus;
            record.records.push({ type: 'dropoff', status: child.status, time });
          }
        });
      });
      
      // Convert map to array
      const records: AttendanceRecord[] = Array.from(childRecordsMap.values()).map(record => ({
        id: record.id,
        childName: record.childName,
        class: record.class,
        busNumber: record.busNumber,
        route: record.route,
        pickupTime: record.pickupTime,
        dropoffTime: record.dropoffTime,
        pickupStatus: record.pickupStatus,
        dropoffStatus: record.dropoffStatus,
        parentNotified: record.parentNotified,
      }));
      
      setAttendanceRecords(records);
    } catch (error) {
      console.error('Error fetching attendance data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status: AttendanceStatus) => {
    const badges = {
      picked_up: {
        icon: <CheckCircle size={16} />,
        text: 'Picked Up',
        className: 'bg-green-100 text-green-700 border-green-200',
      },
      dropped_off: {
        icon: <CheckCircle size={16} />,
        text: 'Dropped Off',
        className: 'bg-blue-100 text-blue-700 border-blue-200',
      },
      absent: {
        icon: <XCircle size={16} />,
        text: 'Absent',
        className: 'bg-red-100 text-red-700 border-red-200',
      },
      pending: {
        icon: <Clock size={16} />,
        text: 'Pending',
        className: 'bg-yellow-100 text-yellow-700 border-yellow-200',
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

  const filteredRecords = attendanceRecords.filter((record: AttendanceRecord) => {
    const matchesSearch =
      record.childName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      record.busNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      record.route.toLowerCase().includes(searchQuery.toLowerCase());

    // Get status for current trip type
    const currentStatus: AttendanceStatus = tripType === 'pickup' ? record.pickupStatus : record.dropoffStatus;
    const matchesStatus = statusFilter === 'all' || currentStatus === statusFilter;

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
      <div className="grid grid-cols-5 gap-4 mb-6">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Users className="w-5 h-5 text-blue-600" />
            </div>
          </div>
          <h3 className="text-xs font-medium text-slate-600 mb-1">Total Students</h3>
          <p className="text-2xl font-bold text-slate-900">{filteredRecords.length}</p>
        </div>

        <div className={`bg-white p-4 rounded-xl border shadow-sm ${tripType === 'pickup' ? 'border-green-300 ring-2 ring-green-100' : 'border-slate-200'}`}>
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-green-100 rounded-lg">
              <CheckCircle className="w-5 h-5 text-green-600" />
            </div>
            <span className="text-xs text-green-600 font-medium">
              {dailyStats.picked_up_percentage?.toFixed(1) || '0.0'}%
            </span>
          </div>
          <h3 className="text-xs font-medium text-slate-600 mb-1">Picked Up</h3>
          <p className="text-2xl font-bold text-slate-900">{dailyStats.picked_up}</p>
        </div>

        <div className={`bg-white p-4 rounded-xl border shadow-sm ${tripType === 'dropoff' ? 'border-blue-300 ring-2 ring-blue-100' : 'border-slate-200'}`}>
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-blue-100 rounded-lg">
              <CheckCircle className="w-5 h-5 text-blue-600" />
            </div>
            <span className="text-xs text-blue-600 font-medium">
              {dailyStats.dropped_off_percentage?.toFixed(1) || '0.0'}%
            </span>
          </div>
          <h3 className="text-xs font-medium text-slate-600 mb-1">Dropped Off</h3>
          <p className="text-2xl font-bold text-slate-900">{dailyStats.dropped_off}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-red-100 rounded-lg">
              <XCircle className="w-5 h-5 text-red-600" />
            </div>
            <span className="text-xs text-red-600 font-medium">
              {dailyStats.absent_percentage?.toFixed(1) || '0.0'}%
            </span>
          </div>
          <h3 className="text-xs font-medium text-slate-600 mb-1">Absent</h3>
          <p className="text-2xl font-bold text-slate-900">{dailyStats.absent}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-yellow-100 rounded-lg">
              <Clock className="w-5 h-5 text-yellow-600" />
            </div>
            <span className="text-xs text-yellow-600 font-medium">
              {dailyStats.pending_percentage?.toFixed(1) || '0.0'}%
            </span>
          </div>
          <h3 className="text-xs font-medium text-slate-600 mb-1">Pending</h3>
          <p className="text-2xl font-bold text-slate-900">{dailyStats.pending}</p>
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
                      {getStatusBadge(tripType === 'pickup' ? record.pickupStatus : record.dropoffStatus)}
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
