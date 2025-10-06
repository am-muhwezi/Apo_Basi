import React, { useState } from 'react';
import { Plus, Search, Eye, MapPin, Navigation } from 'lucide-react';
import Button from '../components/common/Button';
import Select from '../components/common/Select';
import Modal from '../components/common/Modal';
import { getTrips } from '../services/tripsApi';
import { getBuses } from '../services/busApi';
import { getDrivers } from '../services/driverApi';
import { getBusMinders } from '../services/busMinderApi';
import { getChildren } from '../services/childApi';
import type { Trip, Bus, Driver, Minder, Child } from '../types';

export default function TripsPage() {
  const [trips, setTrips] = useState<Trip[]>([]);
  const [buses, setBuses] = useState<Bus[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [minders, setMinders] = useState<Minder[]>([]);
  const [children, setChildren] = useState<Child[]>([]);
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedTrip, setSelectedTrip] = useState<Trip | null>(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showMapModal, setShowMapModal] = useState(false);

  // Fetch all data from backend
  React.useEffect(() => {
    loadAllData();
  }, []);

  async function loadAllData() {
    try {
      const [tripsRes, busesRes, driversRes, mindersRes, childrenRes] = await Promise.all([
        getTrips(),
        getBuses(),
        getDrivers(),
        getBusMinders(),
        getChildren()
      ]);
      setTrips(tripsRes.data);
      setBuses(busesRes.data);
      setDrivers(driversRes.data);
      setMinders(mindersRes.data);
      setChildren(childrenRes.data);
    } catch (error) {
      console.error('Failed to load data:', error);
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

  return (
    <div>
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-900 mb-4 md:mb-0">Trips & Tracking</h1>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 mb-6 p-4">
        <Select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          options={[
            { value: 'all', label: 'All Trips' },
            { value: 'scheduled', label: 'Scheduled' },
            { value: 'in-progress', label: 'In Progress' },
            { value: 'completed', label: 'Completed' },
            { value: 'cancelled', label: 'Cancelled' },
          ]}
        />
      </div>

      <div className="grid gap-6">
        {filteredTrips.map((trip) => (
          <div
            key={trip.id}
            className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow"
          >
            <div className="flex flex-col md:flex-row md:items-start md:justify-between mb-4">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <h3 className="text-lg font-semibold text-slate-900">{trip.route}</h3>
                  <span
                    className={`px-3 py-1 text-xs font-medium rounded-full ${
                      trip.status === 'in-progress'
                        ? 'bg-blue-100 text-blue-800'
                        : trip.status === 'completed'
                        ? 'bg-green-100 text-green-800'
                        : trip.status === 'cancelled'
                        ? 'bg-red-100 text-red-800'
                        : 'bg-slate-100 text-slate-800'
                    }`}
                  >
                    {trip.status}
                  </span>
                  <span
                    className={`px-3 py-1 text-xs font-medium rounded-full ${
                      trip.type === 'pickup'
                        ? 'bg-orange-100 text-orange-800'
                        : 'bg-teal-100 text-teal-800'
                    }`}
                  >
                    {trip.type}
                  </span>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-slate-600">
                  <div>
                    <span className="font-medium">Bus:</span> {getBusNumber(trip.busId)}
                  </div>
                  <div>
                    <span className="font-medium">Driver:</span> {getDriverName(trip.driverId)}
                  </div>
                  <div>
                    <span className="font-medium">Minder:</span> {getMinderName(trip.minderId)}
                  </div>
                  <div>
                    <span className="font-medium">Children:</span> {trip.childrenIds.length}
                  </div>
                  <div>
                    <span className="font-medium">Scheduled:</span> {formatTime(trip.scheduledTime)}
                  </div>
                  {trip.startTime && (
                    <div>
                      <span className="font-medium">Started:</span> {formatTime(trip.startTime)}
                    </div>
                  )}
                </div>
              </div>
              <div className="flex gap-2 mt-4 md:mt-0">
                {trip.status === 'in-progress' && (
                  <Button size="sm" onClick={() => handleTrack(trip)}>
                    <Navigation size={16} className="mr-2" />
                    Track Live
                  </Button>
                )}
                <Button size="sm" variant="secondary" onClick={() => handleView(trip)}>
                  <Eye size={16} className="mr-2" />
                  View Details
                </Button>
              </div>
            </div>

            <div className="border-t border-slate-200 pt-4">
              <h4 className="text-sm font-medium text-slate-700 mb-3">Stops Progress</h4>
              <div className="space-y-2">
                {trip.stops.map((stop, index) => (
                  <div key={stop.id} className="flex items-center gap-3">
                    <div
                      className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                        stop.status === 'completed'
                          ? 'bg-green-100 text-green-700'
                          : stop.status === 'skipped'
                          ? 'bg-red-100 text-red-700'
                          : 'bg-slate-100 text-slate-700'
                      }`}
                    >
                      {index + 1}
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium text-slate-900">{stop.address}</p>
                      <p className="text-xs text-slate-600">
                        {stop.childrenIds.length} children • Scheduled: {formatTime(stop.scheduledTime)}
                        {stop.actualTime && ` • Actual: ${formatTime(stop.actualTime)}`}
                      </p>
                    </div>
                    <span
                      className={`px-2 py-1 text-xs font-medium rounded-full ${
                        stop.status === 'completed'
                          ? 'bg-green-100 text-green-800'
                          : stop.status === 'skipped'
                          ? 'bg-red-100 text-red-800'
                          : 'bg-slate-100 text-slate-800'
                      }`}
                    >
                      {stop.status}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ))}

        {filteredTrips.length === 0 && (
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center">
            <MapPin className="mx-auto mb-4 text-slate-400" size={48} />
            <h3 className="text-lg font-medium text-slate-900 mb-2">No Trips Found</h3>
            <p className="text-slate-600">
              {statusFilter === 'all'
                ? 'There are no trips scheduled yet.'
                : `There are no ${statusFilter} trips.`}
            </p>
          </div>
        )}
      </div>

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
                <p className="text-sm font-medium text-slate-700">Type</p>
                <p className="text-base text-slate-900 capitalize">{selectedTrip.type}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Status</p>
                <p className="text-base text-slate-900 capitalize">{selectedTrip.status}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Date</p>
                <p className="text-base text-slate-900">{formatDate(selectedTrip.scheduledTime)}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Bus</p>
                <p className="text-base text-slate-900">{getBusNumber(selectedTrip.busId)}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Driver</p>
                <p className="text-base text-slate-900">{getDriverName(selectedTrip.driverId)}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Bus Minder</p>
                <p className="text-base text-slate-900">{getMinderName(selectedTrip.minderId)}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-slate-700">Scheduled Time</p>
                <p className="text-base text-slate-900">{formatTime(selectedTrip.scheduledTime)}</p>
              </div>
            </div>

            <div>
              <p className="text-sm font-medium text-slate-700 mb-3">Children on Trip</p>
              <div className="grid grid-cols-2 gap-2">
                {selectedTrip.childrenIds.map((childId) => {
                  const child = children.find(c => c.id === childId);
                  return child ? (
                    <div key={child.id} className="p-3 bg-slate-50 rounded-lg">
                      <p className="font-medium text-slate-900">
                        {child.firstName} {child.lastName}
                      </p>
                      <p className="text-sm text-slate-600">{child.grade}</p>
                    </div>
                  ) : null;
                })}
              </div>
            </div>

            <div>
              <p className="text-sm font-medium text-slate-700 mb-3">Stops</p>
              <div className="space-y-3">
                {selectedTrip.stops.map((stop, index) => (
                  <div key={stop.id} className="p-4 bg-slate-50 rounded-lg">
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className="w-6 h-6 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center text-sm font-medium">
                          {index + 1}
                        </span>
                        <h4 className="font-medium text-slate-900">{stop.address}</h4>
                      </div>
                      <span
                        className={`px-2 py-1 text-xs font-medium rounded-full ${
                          stop.status === 'completed'
                            ? 'bg-green-100 text-green-800'
                            : stop.status === 'skipped'
                            ? 'bg-red-100 text-red-800'
                            : 'bg-slate-100 text-slate-800'
                        }`}
                      >
                        {stop.status}
                      </span>
                    </div>
                    <div className="text-sm text-slate-600 space-y-1">
                      <p>Scheduled: {formatTime(stop.scheduledTime)}</p>
                      {stop.actualTime && <p>Actual: {formatTime(stop.actualTime)}</p>}
                      <p>Children: {stop.childrenIds.length}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </Modal>

      <Modal
        isOpen={showMapModal}
        onClose={() => setShowMapModal(false)}
        title="Live Location Tracking"
        size="xl"
      >
        {selectedTrip && (
          <div className="space-y-4">
            <div className="bg-slate-100 rounded-lg p-8 flex items-center justify-center" style={{ height: '400px' }}>
              <div className="text-center">
                <MapPin className="mx-auto mb-4 text-blue-600" size={64} />
                <h3 className="text-xl font-semibold text-slate-900 mb-2">
                  Live Tracking: {selectedTrip.route}
                </h3>
                {selectedTrip.currentLocation ? (
                  <div className="space-y-2 text-slate-700">
                    <p className="font-medium">Current Location</p>
                    <p className="text-sm">Lat: {selectedTrip.currentLocation.latitude.toFixed(4)}</p>
                    <p className="text-sm">Lng: {selectedTrip.currentLocation.longitude.toFixed(4)}</p>
                    <p className="text-xs text-slate-600">
                      Last updated: {formatTime(selectedTrip.currentLocation.timestamp)}
                    </p>
                  </div>
                ) : (
                  <p className="text-slate-600">Waiting for location data...</p>
                )}
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4 text-center">
              <div className="p-4 bg-blue-50 rounded-lg">
                <p className="text-sm text-blue-700 font-medium mb-1">Bus</p>
                <p className="text-lg font-semibold text-slate-900">{getBusNumber(selectedTrip.busId)}</p>
              </div>
              <div className="p-4 bg-green-50 rounded-lg">
                <p className="text-sm text-green-700 font-medium mb-1">Completed Stops</p>
                <p className="text-lg font-semibold text-slate-900">
                  {selectedTrip.stops.filter((s) => s.status === 'completed').length} / {selectedTrip.stops.length}
                </p>
              </div>
              <div className="p-4 bg-orange-50 rounded-lg">
                <p className="text-sm text-orange-700 font-medium mb-1">Children</p>
                <p className="text-lg font-semibold text-slate-900">{selectedTrip.childrenIds.length}</p>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
