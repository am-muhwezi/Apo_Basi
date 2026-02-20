import React, { useState, useEffect } from 'react';
import { Plus, Search, Eye, MapPin, Navigation, Users, Clock, TrendingUp, AlertCircle, RefreshCw, StopCircle } from 'lucide-react';
import Button from '../components/common/Button';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import BusMap from '../components/BusMap';
import { getTrips, cancelTrip } from '../services/tripsApi';
import { busWebSocketService, LocationUpdate } from '../services/busWebSocketService';
import { useToast } from '../contexts/ToastContext';
import { useConfirm } from '../contexts/ConfirmContext';
import type { Trip } from '../types';

export default function TripsPage() {
  const toast = useToast();
  const confirm = useConfirm();
  const [trips, setTrips] = useState<Trip[]>([]);
  const [filteredTrips, setFilteredTrips] = useState<Trip[]>([]);
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedTrip, setSelectedTrip] = useState<Trip | null>(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showMapModal, setShowMapModal] = useState(false);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(false);
  const [wsConnected, setWsConnected] = useState(false);
  const [recenterTrigger, setRecenterTrigger] = useState(0);

  // Real-time location tracking
  const [busLocations, setBusLocations] = useState<Map<string, { latitude: number; longitude: number; timestamp: string }>>(new Map());

  useEffect(() => {
    loadTrips();

    return () => {
      // Cleanup: disconnect WebSocket on unmount
      busWebSocketService.disconnect();
    };
  }, []);

  useEffect(() => {
    filterTrips();
  }, [trips, statusFilter]);

  async function loadTrips(append = false) {
    try {
      setLoading(true);
      const offset = append ? trips.length : 0;
      const response = await getTrips({ limit: 20, offset });

      const tripsData = response.data.results || response.data || [];
      const totalCount = response.data.count; // Django pagination includes total count
      
      // Use functional update to ensure we work with latest state
      setTrips(prevTrips => {
        if (append) {
          // Filter out any duplicates by ID before appending
          const existingIds = new Set(prevTrips.map(t => t.id));
          const newTrips = (Array.isArray(tripsData) ? tripsData : []).filter(t => !existingIds.has(t.id));
          return [...prevTrips, ...newTrips];
        }
        return Array.isArray(tripsData) ? tripsData : [];
      });
      
      // Check if there are more items: either use total count or check if we got full page
      if (totalCount !== undefined) {
        // If backend provides count, check if we have loaded all items
        const currentTotal = append ? trips.length + tripsData.length : tripsData.length;
        setHasMore(currentTotal < totalCount);
      } else {
        // Fallback: if we got less than requested, we've reached the end
        setHasMore(Array.isArray(tripsData) && tripsData.length === 20);
      }
    } catch (error) {
      if (!append) {
        setTrips([]);
      }
    } finally {
      setLoading(false);
    }
  }

  function loadMoreTrips() {
    if (!loading && hasMore) {
      loadTrips(true);
    }
  }

  function initializeWebSocket() {
    const token = localStorage.getItem('adminToken');
    if (!token) {
      setWsConnected(false);
      return;
    }

    // Get all unique bus IDs from trips
    const busIds = [...new Set(trips.map(trip => trip.busId))].filter(Boolean);

    if (busIds.length === 0) {
      return;
    }


    // Set authentication token
    busWebSocketService.setToken(token);

    // Subscribe to all buses
    busIds.forEach(busId => {
      busWebSocketService.subscribeToBus(busId);

      // Listen for location updates for this bus
      busWebSocketService.on(busId, (data) => {
        if (data.type === 'location_update') {

          // Update bus locations map
          setBusLocations(prev => {
            const updated = new Map(prev);
            updated.set(data.bus_id, {
              latitude: data.latitude,
              longitude: data.longitude,
              timestamp: data.timestamp
            });
            return updated;
          });

          // Update trip if it's currently being viewed
          if (selectedTrip && selectedTrip.busId === data.bus_id) {
            setSelectedTrip(prev => prev ? {
              ...prev,
              currentLocation: {
                latitude: data.latitude,
                longitude: data.longitude,
                timestamp: data.timestamp
              }
            } : null);
          }

          // Update trips list with new location
          setTrips(prevTrips => prevTrips.map(trip =>
            trip.busId === data.bus_id ? {
              ...trip,
              currentLocation: {
                latitude: data.latitude,
                longitude: data.longitude,
                timestamp: data.timestamp
              }
            } : trip
          ));
        } else if (data.type === 'connected') {
          setWsConnected(true);
        } else if (data.type === 'error') {
        }
      });
    });
  }

  // Initialize WebSocket when trips are loaded
  useEffect(() => {
    if (trips.length > 0) {
      initializeWebSocket();
    }
  }, [trips.length]);

  function filterTrips() {
    let filtered = [...trips];

    if (statusFilter !== 'all') {
      filtered = filtered.filter((trip) => trip.status === statusFilter);
    }

    setFilteredTrips(filtered);
  }

  const handleViewDetails = (trip: Trip) => {
    setSelectedTrip(trip);
    setShowDetailModal(true);
  };

  const handleTrackOnMap = (trip: Trip) => {
    setSelectedTrip(trip);
    setShowMapModal(true);
  };

  const handleRecenterMap = () => {
    setRecenterTrigger(prev => prev + 1);
  };

  const handleStopTrip = async (trip: Trip) => {
    const confirmed = await confirm({
      title: `Stop Trip - Bus ${trip.busNumber}`,
      message: `This will immediately cancel the ${trip.type} trip on ${trip.route}. All parents and staff will be notified.`,
      confirmText: 'Stop Trip',
      variant: 'danger'
    });
    
    if (!confirmed) {
      return;
    }

    try {
      await cancelTrip(trip.id);
      
      // Update trip status in local state
      setTrips(prevTrips => prevTrips.map(t =>
        t.id === trip.id ? { ...t, status: 'cancelled' } : t
      ));

      // Update selected trip if it's the one being stopped
      if (selectedTrip && selectedTrip.id === trip.id) {
        setSelectedTrip({ ...selectedTrip, status: 'cancelled' });
      }

      toast.success(`✅ Trip Cancelled - Bus ${trip.busNumber} ${trip.type} route has been stopped. Parents and driver have been notified.`, 6000);
      loadTrips(); // Refresh the list
    } catch (error) {
      toast.error('❌ Failed to cancel trip. The trip may already be completed or cancelled. Please refresh and try again.');
    }
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

  // Calculate stats
  const totalTrips = trips.length;
  const activeTrips = trips.filter((t) => t.status === 'in-progress').length;
  const completedTrips = trips.filter((t) => t.status === 'completed').length;
  const scheduledTrips = trips.filter((t) => t.status === 'scheduled').length;

  const getStatusBadgeClass = (status: string) => {
    switch (status) {
      case 'in-progress':
        return 'bg-blue-100 text-blue-800';
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'cancelled':
        return 'bg-red-100 text-red-800';
      case 'scheduled':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-slate-100 text-slate-800';
    }
  };

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'scheduled', label: 'Scheduled' },
    { value: 'in-progress', label: 'In Progress' },
    { value: 'completed', label: 'Completed' },
    { value: 'cancelled', label: 'Cancelled' },
  ];

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 mb-2">Trips & Tracking</h1>
          <p className="text-slate-600">Monitor and track all school bus trips in real-time.</p>
          <div className="flex items-center gap-2 mt-2">
            <div className={`w-2 h-2 rounded-full ${wsConnected ? 'bg-green-500' : 'bg-yellow-500'}`} />
            <span className="text-xs text-slate-600">
              {wsConnected ? 'Live tracking active' : 'Connecting...'}
            </span>
          </div>
        </div>
        <div className="flex gap-2 mt-4 md:mt-0">
          <Button size="sm" variant="secondary" onClick={() => loadTrips()}>
            <RefreshCw size={18} />
            <span className="hidden sm:inline ml-1">Refresh</span>
          </Button>
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
          <h3 className="text-sm font-medium text-slate-600 mb-1">Total Trips</h3>
          <p className="text-2xl font-bold text-slate-900">{totalTrips}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-green-100 rounded-lg">
              <Navigation className="w-5 h-5 text-green-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Active Now</h3>
          <p className="text-2xl font-bold text-green-600">{activeTrips}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Clock className="w-5 h-5 text-purple-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Scheduled</h3>
          <p className="text-2xl font-bold text-purple-600">{scheduledTrips}</p>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-2">
            <div className="p-2 bg-slate-100 rounded-lg">
              <TrendingUp className="w-5 h-5 text-slate-600" />
            </div>
          </div>
          <h3 className="text-sm font-medium text-slate-600 mb-1">Completed</h3>
          <p className="text-2xl font-bold text-slate-600">{completedTrips}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl p-4 mb-6 border border-slate-200">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="sm:col-span-2">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {statusOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Trips Table - Desktop */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden hidden md:block">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Route
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Bus
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Driver
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Scheduled Time
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {loading && trips.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-slate-500">
                    Loading trips...
                  </td>
                </tr>
              ) : filteredTrips.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-16 text-center">
                    <p className="text-slate-500 font-medium">
                      {statusFilter !== 'all' ? 'No trips match your filter' : 'No trips yet'}
                    </p>
                  </td>
                </tr>
              ) : (
                filteredTrips.map((trip) => {
                  const location = busLocations.get(trip.busId);
                  const hasRecentLocation = location &&
                    (new Date().getTime() - new Date(location.timestamp).getTime()) < 60000; // Within 1 minute

                  return (
                    <tr key={trip.id} className="hover:bg-slate-50 transition-colors">
                      <td className="px-6 py-4">
                        <div className="text-sm font-medium text-slate-900">{trip.route}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-slate-900">{trip.busNumber}</div>
                        {hasRecentLocation && (
                          <div className="flex items-center gap-1 text-xs text-green-600">
                            <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                            Live
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-slate-900">{trip.driverName}</div>
                        {trip.minderName && (
                          <div className="text-xs text-slate-500">Bus Assistant: {trip.minderName}</div>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <span className="capitalize text-sm text-slate-900">{trip.type}</span>
                      </td>
                      <td className="px-6 py-4">
                        <span
                          className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusBadgeClass(
                            trip.status
                          )}`}
                        >
                          {trip.status.replace('-', ' ').toUpperCase()}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-slate-900">{formatDate(trip.scheduledTime)}</div>
                        <div className="text-xs text-slate-500">{formatTime(trip.scheduledTime)}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleViewDetails(trip)}
                            className="text-slate-600 hover:text-slate-800 transition-colors"
                            title="View Details"
                          >
                            <Eye size={18} />
                          </button>
                          {trip.status === 'in-progress' && (
                            <>
                              <button
                                onClick={() => handleTrackOnMap(trip)}
                                className="text-blue-600 hover:text-blue-800 transition-colors"
                                title="Track on Map"
                              >
                                <MapPin size={18} />
                              </button>
                              <button
                                onClick={() => handleStopTrip(trip)}
                                className="text-red-600 hover:text-red-800 transition-colors"
                                title="Stop Trip"
                              >
                                <StopCircle size={18} />
                              </button>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Load More - Desktop */}
        <div className="p-4 border-t border-slate-200">
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
      </div>

      {/* Trips Cards - Mobile */}
      <div className="md:hidden space-y-4">
        {loading && trips.length === 0 ? (
          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-8 text-center">
            <RefreshCw className="w-8 h-8 animate-spin text-blue-600 mx-auto mb-2" />
            <p className="text-slate-600">Loading trips...</p>
          </div>
        ) : filteredTrips.length === 0 ? (
          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-12 text-center">
            <p className="text-slate-500 font-medium">
              {statusFilter !== 'all' ? 'No trips match your filter' : 'No trips yet'}
            </p>
          </div>
        ) : (
          filteredTrips.map((trip) => {
            const location = busLocations.get(trip.busId);
            const hasRecentLocation = location &&
              (new Date().getTime() - new Date(location.timestamp).getTime()) < 60000;

            return (
              <div key={trip.id} className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h3 className="font-semibold text-slate-900 text-lg">{trip.route}</h3>
                    <p className="text-sm text-slate-600">{trip.busNumber}</p>
                    {hasRecentLocation && (
                      <div className="flex items-center gap-1 text-xs text-green-600 mt-1">
                        <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                        Live Tracking
                      </div>
                    )}
                  </div>
                  <span
                    className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusBadgeClass(trip.status)}`}
                  >
                    {trip.status.replace('-', ' ').toUpperCase()}
                  </span>
                </div>

                <div className="space-y-2 mb-4">
                  <div className="flex items-center gap-2 text-sm">
                    <Users className="w-4 h-4 text-slate-400" />
                    <span className="text-slate-600">Driver:</span>
                    <span className="font-medium text-slate-900">{trip.driverName}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <Navigation className="w-4 h-4 text-slate-400" />
                    <span className="text-slate-600">Type:</span>
                    <span className="font-medium text-slate-900 capitalize">{trip.type}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <Clock className="w-4 h-4 text-slate-400" />
                    <span className="text-slate-600">Scheduled:</span>
                    <span className="font-medium text-slate-900">{formatTime(trip.scheduledTime)}</span>
                  </div>
                </div>

                <div className="flex gap-2 pt-3 border-t border-slate-200">
                  <button
                    onClick={() => handleViewDetails(trip)}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors"
                  >
                    <Eye size={18} />
                    <span className="text-sm font-medium">View</span>
                  </button>
                  {trip.status === 'in-progress' && (
                    <>
                      <button
                        onClick={() => handleTrackOnMap(trip)}
                        className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-green-50 text-green-600 rounded-lg hover:bg-green-100 transition-colors"
                      >
                        <MapPin size={18} />
                        <span className="text-sm font-medium">Track</span>
                      </button>
                      <button
                        onClick={() => handleStopTrip(trip)}
                        className="px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
                      >
                        <StopCircle size={18} />
                      </button>
                    </>
                  )}
                </div>
              </div>
            );
          })
        )}

        {/* Load More - Mobile */}
        {filteredTrips.length > 0 && (
          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
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
                  className="w-full"
                >
                  {loading ? 'Loading...' : 'Load More'}
                </Button>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Trip Details Modal */}
      <Modal
        isOpen={showDetailModal}
        onClose={() => setShowDetailModal(false)}
        title="Trip Details"
        size="lg"
      >
        {selectedTrip && (
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-slate-700">Route</p>
                <p className="text-base text-slate-900">{selectedTrip.route}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Status</p>
                <span
                  className={`inline-block px-3 py-1 rounded-full text-xs font-medium ${getStatusBadgeClass(
                    selectedTrip.status
                  )}`}
                >
                  {selectedTrip.status.replace('-', ' ').toUpperCase()}
                </span>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Bus</p>
                <p className="text-base text-slate-900">{selectedTrip.busNumber}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Driver</p>
                <p className="text-base text-slate-900">{selectedTrip.driverName}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Type</p>
                <p className="text-base text-slate-900 capitalize">{selectedTrip.type}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Scheduled Time</p>
                <p className="text-base text-slate-900">{formatTime(selectedTrip.scheduledTime)}</p>
              </div>
              {selectedTrip.startTime && (
                <div>
                  <p className="text-sm font-medium text-slate-700">Start Time</p>
                  <p className="text-base text-slate-900">{formatTime(selectedTrip.startTime)}</p>
                </div>
              )}
              {selectedTrip.endTime && (
                <div>
                  <p className="text-sm font-medium text-slate-700">End Time</p>
                  <p className="text-base text-slate-900">{formatTime(selectedTrip.endTime)}</p>
                </div>
              )}
            </div>

            {selectedTrip.currentLocation && (
              <div className="bg-blue-50 rounded-lg p-4">
                <h4 className="font-medium text-slate-900 mb-2">Current Location</h4>
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <span className="text-slate-600">Latitude:</span>{' '}
                    <span className="font-medium">{selectedTrip.currentLocation.latitude.toFixed(6)}</span>
                  </div>
                  <div>
                    <span className="text-slate-600">Longitude:</span>{' '}
                    <span className="font-medium">{selectedTrip.currentLocation.longitude.toFixed(6)}</span>
                  </div>
                  <div className="col-span-2">
                    <span className="text-slate-600">Last Update:</span>{' '}
                    <span className="font-medium">{formatTime(selectedTrip.currentLocation.timestamp)}</span>
                  </div>
                </div>
              </div>
            )}

            {selectedTrip.stops && selectedTrip.stops.length > 0 && (
              <div>
                <h4 className="font-medium text-slate-900 mb-3">Stops ({selectedTrip.stops.length})</h4>
                <div className="space-y-2 max-h-64 overflow-y-auto">
                  {selectedTrip.stops.map((stop, index) => (
                    <div key={stop.id} className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                      <div className="flex-shrink-0 w-6 h-6 rounded-full bg-blue-600 text-white text-xs flex items-center justify-center">
                        {index + 1}
                      </div>
                      <div className="flex-1">
                        <p className="text-sm font-medium text-slate-900">{stop.address}</p>
                        <p className="text-xs text-slate-600">Scheduled: {formatTime(stop.scheduledTime)}</p>
                        {stop.actualTime && (
                          <p className="text-xs text-slate-600">Actual: {formatTime(stop.actualTime)}</p>
                        )}
                      </div>
                      <span
                        className={`px-2 py-1 rounded text-xs font-medium ${
                          stop.status === 'completed'
                            ? 'bg-green-100 text-green-800'
                            : stop.status === 'skipped'
                            ? 'bg-red-100 text-red-800'
                            : 'bg-yellow-100 text-yellow-800'
                        }`}
                      >
                        {stop.status}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div className="pt-4">
              <Button onClick={() => setShowDetailModal(false)} className="w-full">
                Close
              </Button>
            </div>
          </div>
        )}
      </Modal>

      {/* Map Tracking Modal */}
      <Modal
        isOpen={showMapModal}
        onClose={() => setShowMapModal(false)}
        title="Live Bus Tracking"
        size="xl"
      >
        {selectedTrip && (
          <div className="space-y-4">
            {/* Trip Info Header */}
            <div className="bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg p-4 border border-blue-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <button
                    onClick={handleRecenterMap}
                    className="bg-blue-600 hover:bg-blue-700 rounded-lg p-3 shadow-md transition-all duration-200 hover:scale-105 active:scale-95"
                    title="Center map on bus location"
                  >
                    <Navigation className="w-6 h-6 text-white" />
                  </button>
                  <div>
                    <h4 className="font-semibold text-lg text-slate-900">{selectedTrip.busNumber}</h4>
                    <p className="text-sm text-slate-600">{selectedTrip.route}</p>
                  </div>
                </div>
                {busLocations.get(selectedTrip.busId) && (
                  <div className="flex items-center gap-2 bg-green-100 px-3 py-1.5 rounded-full">
                    <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                    <span className="text-sm font-medium text-green-700">Live Tracking</span>
                  </div>
                )}
              </div>
            </div>

            {selectedTrip.currentLocation ? (
              <div className="space-y-4">
                {/* Location Stats */}
                <div className="grid grid-cols-3 gap-3">
                  <div className="bg-white border border-slate-200 rounded-lg p-3">
                    <div className="text-xs text-slate-500 mb-1">Latitude</div>
                    <div className="text-sm font-mono font-semibold text-slate-900">
                      {selectedTrip.currentLocation.latitude.toFixed(6)}
                    </div>
                  </div>
                  <div className="bg-white border border-slate-200 rounded-lg p-3">
                    <div className="text-xs text-slate-500 mb-1">Longitude</div>
                    <div className="text-sm font-mono font-semibold text-slate-900">
                      {selectedTrip.currentLocation.longitude.toFixed(6)}
                    </div>
                  </div>
                  <div className="bg-white border border-slate-200 rounded-lg p-3">
                    <div className="text-xs text-slate-500 mb-1">Last Update</div>
                    <div className="text-sm font-semibold text-slate-900">
                      {formatTime(selectedTrip.currentLocation.timestamp)}
                    </div>
                  </div>
                </div>

                {/* Help Guide */}
                <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                  <div className="flex items-start gap-2">
                    <div className="flex-shrink-0 mt-0.5">
                      <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <div className="flex-1">
                      <p className="text-xs font-medium text-blue-900 mb-1">Quick Guide:</p>
                      <ul className="text-xs text-blue-800 space-y-1">
                        <li className="flex items-center gap-1">
                          <span className="inline-flex items-center justify-center w-4 h-4 bg-blue-600 rounded text-white text-[10px]">
                            <Navigation className="w-2.5 h-2.5" />
                          </span>
                          Click the blue arrow button above to recenter map on bus
                        </li>
                        <li className="flex items-center gap-1">
                          <span className="inline-flex items-center justify-center w-4 h-4 bg-blue-600 rounded text-white text-[10px]">+</span>
                          Use +/- buttons or scroll to zoom in/out
                        </li>
                        <li className="flex items-center gap-1">
                          <span className="inline-flex items-center justify-center w-4 h-4 bg-blue-600 rounded text-white text-[10px]">
                            <MapPin className="w-2.5 h-2.5" />
                          </span>
                          Click the bus marker to see details
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>

                {/* Map Container */}
                <BusMap
                  latitude={selectedTrip.currentLocation.latitude}
                  longitude={selectedTrip.currentLocation.longitude}
                  busNumber={selectedTrip.busNumber}
                  route={selectedTrip.route}
                  lastUpdate={selectedTrip.currentLocation.timestamp}
                  recenterTrigger={recenterTrigger}
                />
              </div>
            ) : (
              <div className="bg-slate-50 border-2 border-dashed border-slate-300 rounded-lg h-96 flex items-center justify-center">
                <div className="text-center">
                  <AlertCircle className="w-16 h-16 text-slate-400 mx-auto mb-3" />
                  <p className="text-lg font-medium text-slate-700">No location data available</p>
                  <p className="text-sm text-slate-500 mt-2 max-w-xs mx-auto">
                    Location tracking will begin when the driver starts the trip
                  </p>
                </div>
              </div>
            )}

            <Button onClick={() => setShowMapModal(false)} className="w-full">
              Close
            </Button>
          </div>
        )}
      </Modal>
    </div>
  );
}
