import React, { useState, useMemo } from 'react';
import { Search, Filter, Download, Phone, MapPin, AlertCircle } from 'lucide-react';
import { Student, StudentFilters } from '../types/student';
import { mockStudents } from '../data/mockStudents';

const StudentsView: React.FC = () => {
  const [filters, setFilters] = useState<StudentFilters>({
    search: '',
    route: '',
    grade: '',
    checkInStatus: ''
  });

  const filteredStudents = useMemo(() => {
    return mockStudents.filter((student: Student) => {
      const matchesSearch = student.name.toLowerCase().includes(filters.search.toLowerCase()) ||
                           student.parentName.toLowerCase().includes(filters.search.toLowerCase()) ||
                           student.address.toLowerCase().includes(filters.search.toLowerCase());
      
      const matchesRoute = !filters.route || student.route === filters.route;
      const matchesGrade = !filters.grade || student.grade === filters.grade;
      const matchesStatus = !filters.checkInStatus || student.checkInStatus === filters.checkInStatus;
      
      return matchesSearch && matchesRoute && matchesGrade && matchesStatus;
    });
  }, [filters]);

  const uniqueRoutes = Array.from(new Set(mockStudents.map(student => student.route)));
  const uniqueGrades = Array.from(new Set(mockStudents.map(student => student.grade)));

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'checked-in':
        return 'bg-green-100 text-green-800';
      case 'not-checked-in':
        return 'bg-yellow-100 text-yellow-800';
      case 'absent':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'checked-in':
        return 'Checked In';
      case 'not-checked-in':
        return 'Not Checked In';
      case 'absent':
        return 'Absent';
      default:
        return 'Unknown';
    }
  };

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Students</h1>
        <p className="text-gray-600">Manage student information and track attendance across all routes.</p>
      </div>

      {/* Search and Filters */}
      <div className="mb-6 flex flex-col lg:flex-row lg:items-center lg:justify-between space-y-4 lg:space-y-0 lg:space-x-4">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Search students..."
            value={filters.search}
            onChange={(e) => setFilters({ ...filters, search: e.target.value })}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
          />
        </div>
        
        <div className="flex items-center space-x-3">
          <select
            value={filters.route}
            onChange={(e) => setFilters({ ...filters, route: e.target.value })}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="">All Routes</option>
            {uniqueRoutes.map(route => (
              <option key={route} value={route}>{route}</option>
            ))}
          </select>
          
          <select
            value={filters.grade}
            onChange={(e) => setFilters({ ...filters, grade: e.target.value })}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="">All Grades</option>
            {uniqueGrades.map(grade => (
              <option key={grade} value={grade}>{grade}</option>
            ))}
          </select>

          <select
            value={filters.checkInStatus}
            onChange={(e) => setFilters({ ...filters, checkInStatus: e.target.value })}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="">All Status</option>
            <option value="checked-in">Checked In</option>
            <option value="not-checked-in">Not Checked In</option>
            <option value="absent">Absent</option>
          </select>
          
          <button className="flex items-center space-x-2 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors duration-200">
            <Filter size={16} />
            <span>Filter</span>
          </button>
          
          <button className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            <Download size={16} />
            <span>Export</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Total Students</h3>
          <p className="text-2xl font-bold text-gray-900">{mockStudents.length}</p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Checked In</h3>
          <p className="text-2xl font-bold text-green-600">
            {mockStudents.filter(student => student.checkInStatus === 'checked-in').length}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Not Checked In</h3>
          <p className="text-2xl font-bold text-yellow-600">
            {mockStudents.filter(student => student.checkInStatus === 'not-checked-in').length}
          </p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Absent</h3>
          <p className="text-2xl font-bold text-red-600">
            {mockStudents.filter(student => student.checkInStatus === 'absent').length}
          </p>
        </div>
      </div>

      {/* Results count */}
      <div className="mb-4">
        <p className="text-sm text-gray-600">
          Showing {filteredStudents.length} of {mockStudents.length} students
        </p>
      </div>

      {/* Students Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Student</th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Grade</th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Route</th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Pickup Time</th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Parent</th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Status</th>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-600">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredStudents.map((student, index) => (
                <tr 
                  key={student.id} 
                  className={`hover:bg-gray-50 transition-colors duration-150 ${
                    index % 2 === 0 ? 'bg-white' : 'bg-gray-25'
                  }`}
                >
                  <td className="px-6 py-4">
                    <div>
                      <div className="text-sm font-medium text-gray-900">{student.name}</div>
                      <div className="text-sm text-gray-500 flex items-center">
                        <MapPin size={12} className="mr-1" />
                        {student.address}
                      </div>
                      {student.medicalNotes && (
                        <div className="text-xs text-red-600 flex items-center mt-1">
                          <AlertCircle size={12} className="mr-1" />
                          {student.medicalNotes}
                        </div>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-700">{student.grade}</td>
                  <td className="px-6 py-4 text-sm text-blue-600 hover:text-blue-800 cursor-pointer">
                    {student.route}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-700">{student.pickupTime}</td>
                  <td className="px-6 py-4">
                    <div>
                      <div className="text-sm text-gray-900">{student.parentName}</div>
                      <div className="text-sm text-gray-500 flex items-center">
                        <Phone size={12} className="mr-1" />
                        {student.parentPhone}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(student.checkInStatus)}`}>
                      {getStatusText(student.checkInStatus)}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <button className="text-blue-600 hover:text-blue-800 text-sm font-medium px-2 py-1 rounded hover:bg-blue-50 transition-colors duration-150">
                      View Details
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default StudentsView;