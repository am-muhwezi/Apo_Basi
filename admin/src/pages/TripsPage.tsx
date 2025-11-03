import React, { useState } from 'react';
import { Plus, Search, Eye, MapPin, Navigation, Users, Clock, TrendingUp } from 'lucide-react';
import Button from '../components/common/Button';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import { getTrips } from '../services/tripsApi';
import { getBuses } from '../services/busApi';
import { getDrivers } from '../services/driverApi';
import { getBusMinders } from '../services/busMinderApi';
import { getChildren } from '../services/childApi';
import type { Trip, Bus, Driver, Minder, Child } from '../types';

// Dummy route data
const dummyRoutes = [
  {
    id: 'route-a',
    name: 'Route A',
    busNumber: 'Bus 101',
    driver: 'Ethan Carter',
    startTime: '7:00 AM',
    students: 32,
    stops: 12,
    duration: 45,
    distance: 15.2,
    status: 'Active'
  },
  {
    id: 'route-b',
    name: 'Route B',
    busNumber: 'Bus 102',
    driver: 'Olivia Bennett',
    startTime: '7:05 AM',
    students: 28,
    stops: 10,
    duration: 40,
    distance: 12.8,
    status: 'Active'
  },
  {
    id: 'route-c',
    name: 'Route C',
    busNumber: 'Bus 103',
    driver: 'Noah Thompson',
    startTime: '6:55 AM',
    students: 35,
    stops: 14,
    duration: 50,
    distance: 18.5,
    status: 'Active'
  },
  {
    id: 'route-d',
    name: 'Route D',
    busNumber: 'Bus 104',
    driver: 'Ava Harper',
    startTime: '6:50 AM',
    students: 40,
    stops: 16,
    duration: 55,
    distance: 20.1,
    status: 'Active'
  },
  {
    id: 'route-e',
    name: 'Route E',
    busNumber: 'Bus 105',
    driver: 'Liam Foster',
    startTime: '7:10 AM',
    students: 30,
    stops: 11,
    duration: 42,
    distance: 14.3,
    status: 'Active'
  },
];

export default function TripsPage() {
  const [trips, setTrips] = useState<Trip[]>([]);
  const [buses, setBuses] = useState<Bus[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [minders, setMinders] = useState<Minder[]>([]);
  const [children, setChildren] = useState<Child[]>([]);
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedTrip, setSelectedTrip] = useState<Trip | null>(null);
  const [selectedRoute, setSelectedRoute] = useState<typeof dummyRoutes[0] | null>(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showMapModal, setShowMapModal] = useState(false);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(false);

  // Use dummy routes for now
  const [routes] = useState(dummyRoutes);

  // Fetch all data from backend
  React.useEffect(() => {
    loadAllData();
  }, []);

  async function loadAllData(append = false) {
    try {
      setLoading(true);
      const offset = append ? trips.length : 0;
      const [tripsRes, busesRes, driversRes, mindersRes, childrenRes] = await Promise.all([
        getTrips({ limit: 20, offset }),
        getBuses({ limit: 100 }),
        getDrivers({ limit: 100 }),
        getBusMinders({ limit: 100 }),
        getChildren({ limit: 100 })
      ]);

      // Handle paginated responses
      const tripsData = tripsRes.data.results || tripsRes.data || [];
      const busesData = busesRes.data.results || busesRes.data || [];
      const driversData = driversRes.data.results || driversRes.data || [];
      const mindersData = mindersRes.data.results || mindersRes.data || [];
      const childrenData = childrenRes.data.results || childrenRes.data || [];

      setTrips(append ? [...trips, ...Array.isArray(tripsData) ? tripsData : []] : (Array.isArray(tripsData) ? tripsData : []));
      setBuses(Array.isArray(busesData) ? busesData : []);
      setDrivers(Array.isArray(driversData) ? driversData : []);
      setMinders(Array.isArray(mindersData) ? mindersData : []);
      setChildren(Array.isArray(childrenData) ? childrenData : []);

      setHasMore(Array.isArray(tripsData) && tripsData.length === 20);
    } catch (error) {
      console.error('Failed to load data:', error);
      if (!append) {
        setTrips([]);
        setBuses([]);
        setDrivers([]);
        setMinders([]);
        setChildren([]);
      }
    } finally {
      setLoading(false);
    }
  }

  function loadMoreTrips() {
    if (!loading && hasMore) {
      loadAllData(true);
    }
  }

  const filteredTrips = trips.filter((trip) => {
    const matchesStatus = statusFilter === 'all' || trip.status === statusFilter;
    return matchesStatus;
  });

  const handleView = (trip: Trip) => {
    setSelectedTrip(trip);
    setShowDetailModal(true);
  };

  const handleTrack = (trip: Trip) => {
    setSelectedTrip(trip);
    setShowMapModal(true);
  };

  const getBusNumber = (busId: string) => {
    const bus = buses.find((b) => b.id === busId);
    return bus ? bus.busNumber : 'Unknown';
  };

  const getDriverName = (driverId: string) => {
    const driver = drivers.find((d) => d.id === driverId);
    return driver ? `${driver.firstName} ${driver.lastName}` : 'Unknown';
  };

  const getMinderName = (minderId?: string) => {
    if (!minderId) return 'Not Assigned';
    const minder = minders.find((m) => m.id === minderId);
    return minder ? `${minder.firstName} ${minder.lastName}` : 'Unknown';
  };

  const formatTime = (timestamp: string) => {
    return new Date(timestamp).toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const formatDate = (timestamp: string) => {
    return new Date(timestamp).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  // Calculate stats from dummy routes
  const totalRoutes = routes.length;
  const totalStudents = routes.reduce((sum, route) => sum + route.students, 0);
  const totalStops = routes.reduce((sum, route) => sum + route.stops, 0);
  const avgDuration = routes.length > 0 ? Math.round(routes.reduce((sum, route) => sum + route.duration, 0) / routes.length) : 0;

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 mb-2">Routes & Tracking</h1>
          <p className="text-slate-600">Manage and optimize school bus routes for efficient transportation.</p>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-blue-100 rounded-lg">
              <MapPin className="w-5 h-5 text-blue-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Routes</h3>
          <p className="text-2xl font-bold text-slate-900">{totalRoutes}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-green-100 rounded-lg">
              <Users className="w-5 h-5 text-green-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Students</h3>
          <p className="text-2xl font-bold text-slate-900">{totalStudents}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Navigation className="w-5 h-5 text-purple-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Stops</h3>
          <p className="text-2xl font-bold text-slate-900">{totalStops}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-orange-100 rounded-lg">
              <Clock className="w-5 h-5 text-orange-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Avg Duration</h3>
          <p className="text-2xl font-bold text-slate-900">{avgDuration} min</p>
        </div>
      </div>

      {/* Routes Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {routes.map((route) => (
          <div
            key={route.id}
            className="bg-white rounded-xl border border-slate-200 shadow-sm p-6 hover:shadow-md transition-shadow"
          >
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-blue-100 rounded-lg">
                  <MapPin className="w-6 h-6 text-blue-600" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-slate-900">{route.name}</h3>
                  <p className="text-sm text-slate-600">{route.busNumber}</p>
                </div>
              </div>
              <span className="px-3 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
                {route.status}
              </span>
            </div>

            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <Users className="w-4 h-4" />
                <span>{route.students} students</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <Navigation className="w-4 h-4" />
                <span>{route.stops} stops</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <Clock className="w-4 h-4" />
                <span>{route.duration} minutes</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <MapPin className="w-4 h-4" />
                <span>{route.distance} miles</span>
              </div>
            </div>

            <div className="border-t border-slate-200 pt-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-slate-700">Driver: {route.driver}</p>
                  <p className="text-xs text-slate-600">Starts at {route.startTime}</p>
                </div>
                <Button
                  size="sm"
                  variant="secondary"
                  onClick={() => setSelectedRoute(route)}
                >
                  <Eye size={16} className="mr-2" />
                  View Details
                </Button>
              </div>
            </div>
          </div>
        ))}

        {routes.length === 0 && (
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center col-span-2">
            <MapPin className="mx-auto mb-4 text-slate-400" size={48} />
            <h3 className="text-lg font-medium text-slate-900 mb-2">No Routes Found</h3>
            <p className="text-slate-600">There are no routes configured yet.</p>
          </div>
        )}
      </div>

      {/* Loaded Indicator */}
      <div className="mt-6 p-4 bg-white rounded-xl border border-slate-200">
        <div className="flex flex-col items-center gap-3">
          <span className="text-sm text-slate-600">
            Loaded {filteredTrips.length} of {filteredTrips.length}{hasMore ? '+' : ''} trips
          </span>
          {hasMore && (
            <Button
              onClick={loadMoreTrips}
              disabled={loading}
              variant="secondary"
              size="sm"
            >
              {loading ? 'Loading...' : 'Load More'}
            </Button>
          )}
        </div>
      </div>

      {/* Route Details Modal */}
      <Modal
        isOpen={selectedRoute !== null}
        onClose={() => setSelectedRoute(null)}
        title="Route Details"
        size="lg"
      >
        {selectedRoute && (
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-slate-700">Route Name</p>
                <p className="text-base text-slate-900">{selectedRoute.name}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Status</p>
                <p className="text-base text-slate-900">{selectedRoute.status}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Bus</p>
                <p className="text-base text-slate-900">{selectedRoute.busNumber}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Driver</p>
                <p className="text-base text-slate-900">{selectedRoute.driver}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Start Time</p>
                <p className="text-base text-slate-900">{selectedRoute.startTime}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Students</p>
                <p className="text-base text-slate-900">{selectedRoute.students}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Total Stops</p>
                <p className="text-base text-slate-900">{selectedRoute.stops}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Duration</p>
                <p className="text-base text-slate-900">{selectedRoute.duration} minutes</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Distance</p>
                <p className="text-base text-slate-900">{selectedRoute.distance} miles</p>
              </div>
            </div>

            <div className="bg-blue-50 rounded-lg p-4">
              <h4 className="font-medium text-slate-900 mb-2">Route Information</h4>
              <p className="text-sm text-slate-600">
                This route covers {selectedRoute.stops} pickup/drop-off points with an estimated duration of {selectedRoute.duration} minutes.
                The bus travels approximately {selectedRoute.distance} miles to transport {selectedRoute.students} students.
              </p>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
