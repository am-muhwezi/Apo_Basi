import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from 'react-leaflet';
import L from 'leaflet';
import { FaBus } from 'react-icons/fa';
import { snapToRoad, getRoute, formatDuration, formatDistance, isMapboxConfigured, type LatLng, type RouteResponse } from '../services/mapboxService';

// Custom bus icon with better styling using FontAwesome bus icon
const createBusIcon = () => {
  return L.divIcon({
    className: 'custom-bus-marker',
    html: `
      <div style="position: relative;">
        <!-- Pulse animation -->
        <div style="
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          width: 60px;
          height: 60px;
          background: rgba(37, 99, 235, 0.3);
          border-radius: 50%;
          animation: pulse 2s ease-out infinite;
        "></div>

        <!-- Bus icon container -->
        <div style="
          position: relative;
          width: 44px;
          height: 44px;
          background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
          border: 3px solid white;
        ">
          <!-- FontAwesome Bus SVG icon -->
          <svg width="24" height="24" viewBox="0 0 576 512" fill="white">
            <path d="M288 0C422.4 0 512 35.2 512 80V128C529.7 128 544 142.3 544 160V224C544 241.7 529.7 256 512 256L512 416C512 433.7 497.7 448 480 448V480C480 497.7 465.7 512 448 512H416C398.3 512 384 497.7 384 480V448H192V480C192 497.7 177.7 512 160 512H128C110.3 512 96 497.7 96 480V448C78.33 448 64 433.7 64 416L64 256C46.33 256 32 241.7 32 224V160C32 142.3 46.33 128 64 128V80C64 35.2 153.6 0 288 0zM128 256C128 273.7 142.3 288 160 288H416C433.7 288 448 273.7 448 256V128H128V256zM144 400C162.1 400 176 386.1 176 368C176 349.9 162.1 336 144 336C125.9 336 112 349.9 112 368C112 386.1 125.9 400 144 400zM432 400C450.1 400 464 386.1 464 368C464 349.9 450.1 336 432 336C413.9 336 400 349.9 400 368C400 386.1 413.9 400 432 400z"/>
          </svg>
        </div>

        <!-- Direction indicator (small arrow pointing forward) -->
        <div style="
          position: absolute;
          bottom: -8px;
          left: 50%;
          transform: translateX(-50%);
          width: 0;
          height: 0;
          border-left: 6px solid transparent;
          border-right: 6px solid transparent;
          border-top: 8px solid white;
        "></div>
      </div>

      <style>
        @keyframes pulse {
          0% {
            transform: translate(-50%, -50%) scale(0.8);
            opacity: 0.8;
          }
          50% {
            transform: translate(-50%, -50%) scale(1.2);
            opacity: 0.4;
          }
          100% {
            transform: translate(-50%, -50%) scale(0.8);
            opacity: 0.8;
          }
        }
      </style>
    `,
    iconSize: [44, 44],
    iconAnchor: [22, 40],
    popupAnchor: [0, -40],
  });
};

interface BusMapProps {
  latitude: number;
  longitude: number;
  busNumber?: string;
  route?: string;
  lastUpdate?: string;
  recenterTrigger?: number;
  childrenLocations?: Array<{ latitude: number; longitude: number; name: string; address: string }>;
  showRoute?: boolean; // Show route polyline from bus to children
}

// Component to handle map updates when location changes or recenter is triggered
function MapUpdater({ latitude, longitude, recenterTrigger }: { latitude: number; longitude: number; recenterTrigger?: number }) {
  const map = useMap();

  useEffect(() => {
    map.setView([latitude, longitude], map.getZoom());
  }, [latitude, longitude, map]);

  // Recenter and zoom when recenter is triggered
  useEffect(() => {
    if (recenterTrigger) {
      map.setView([latitude, longitude], 16, {
        animate: true,
        duration: 0.5
      });
    }
  }, [recenterTrigger, latitude, longitude, map]);

  return null;
}

const BusMap: React.FC<BusMapProps> = ({
  latitude,
  longitude,
  busNumber = 'Bus',
  route = '',
  lastUpdate,
  recenterTrigger,
  childrenLocations = [],
  showRoute = true
}) => {
  const [snappedLocation, setSnappedLocation] = useState<LatLng | null>(null);
  const [routeData, setRouteData] = useState<RouteResponse | null>(null);
  const [isLoadingRoute, setIsLoadingRoute] = useState(false);

  const busLocation: LatLng = { latitude, longitude };
  const displayLocation = snappedLocation || busLocation;
  const position: [number, number] = [displayLocation.latitude, displayLocation.longitude];

  // Snap bus location to road when coordinates change
  useEffect(() => {
    if (!isMapboxConfigured()) {
      return;
    }

    const snapBusToRoad = async () => {
      const snapped = await snapToRoad(busLocation);
      if (snapped) {
        setSnappedLocation(snapped);
      }
    };

    snapBusToRoad();
  }, [latitude, longitude]);

  // Fetch route when children locations or bus location changes
  useEffect(() => {
    if (!isMapboxConfigured() || !showRoute || childrenLocations.length === 0) {
      setRouteData(null);
      return;
    }

    const fetchRoute = async () => {
      setIsLoadingRoute(true);
      try {
        // Get route to the first child's location (closest stop)
        const destination = childrenLocations[0];
        const route = await getRoute(busLocation, destination);
        setRouteData(route);
      } catch (error) {
      } finally {
        setIsLoadingRoute(false);
      }
    };

    fetchRoute();
  }, [latitude, longitude, childrenLocations, showRoute]);

  // Create home icon for children locations
  const createHomeIcon = () => {
    return L.divIcon({
      className: 'custom-home-marker',
      html: `
        <div style="
          width: 32px;
          height: 32px;
          background: linear-gradient(135deg, #10b981 0%, #059669 100%);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
          border: 2px solid white;
        ">
          <svg width="18" height="18" viewBox="0 0 576 512" fill="white">
            <path d="M575.8 255.5c0 18-15 32.1-32 32.1h-32l.7 160.2c0 2.7-.2 5.4-.5 8.1V472c0 22.1-17.9 40-40 40H456c-1.1 0-2.2 0-3.3-.1c-1.4 .1-2.8 .1-4.2 .1H416 392c-22.1 0-40-17.9-40-40V448 384c0-17.7-14.3-32-32-32H256c-17.7 0-32 14.3-32 32v64 24c0 22.1-17.9 40-40 40H160 128.1c-1.5 0-3-.1-4.5-.2c-1.2 .1-2.4 .2-3.6 .2H104c-22.1 0-40-17.9-40-40V360c0-.9 0-1.9 .1-2.8V287.6H32c-18 0-32-14-32-32.1c0-9 3-17 10-24L266.4 8c7-7 15-8 22-8s15 2 21 7L564.8 231.5c8 7 12 15 11 24z"/>
          </svg>
        </div>
      `,
      iconSize: [32, 32],
      iconAnchor: [16, 16],
      popupAnchor: [0, -16],
    });
  };

  return (
    <div className="w-full h-96 rounded-lg overflow-hidden border border-slate-200">
      <MapContainer
        center={position}
        zoom={15}
        style={{ height: '100%', width: '100%' }}
        scrollWheelZoom={true}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        
        {/* Route Polyline */}
        {routeData && routeData.coordinates.length > 0 && (
          <Polyline
            positions={routeData.coordinates.map(coord => [coord[1], coord[0]] as [number, number])}
            color="#2563eb"
            weight={4}
            opacity={0.7}
            dashArray="10, 10"
          />
        )}

        {/* Bus Marker */}
        <Marker position={position} icon={createBusIcon()}>
          <Popup className="custom-popup" minWidth={200}>
            <div style={{ padding: '8px' }}>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                marginBottom: '12px',
                paddingBottom: '8px',
                borderBottom: '2px solid #e2e8f0'
              }}>
                <div style={{
                  width: '36px',
                  height: '36px',
                  background: 'linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%)',
                  borderRadius: '8px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <svg width="20" height="20" viewBox="0 0 576 512" fill="white">
                    <path d="M288 0C422.4 0 512 35.2 512 80V128C529.7 128 544 142.3 544 160V224C544 241.7 529.7 256 512 256L512 416C512 433.7 497.7 448 480 448V480C480 497.7 465.7 512 448 512H416C398.3 512 384 497.7 384 480V448H192V480C192 497.7 177.7 512 160 512H128C110.3 512 96 497.7 96 480V448C78.33 448 64 433.7 64 416L64 256C46.33 256 32 241.7 32 224V160C32 142.3 46.33 128 64 128V80C64 35.2 153.6 0 288 0zM128 256C128 273.7 142.3 288 160 288H416C433.7 288 448 273.7 448 256V128H128V256zM144 400C162.1 400 176 386.1 176 368C176 349.9 162.1 336 144 336C125.9 336 112 349.9 112 368C112 386.1 125.9 400 144 400zM432 400C450.1 400 464 386.1 464 368C464 349.9 450.1 336 432 336C413.9 336 400 349.9 400 368C400 386.1 413.9 400 432 400z"/>
                  </svg>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: '600', fontSize: '16px', color: '#1e293b' }}>
                    {busNumber}
                  </div>
                  {route && (
                    <div style={{ fontSize: '12px', color: '#64748b' }}>
                      {route}
                    </div>
                  )}
                </div>
                <div style={{
                  width: '8px',
                  height: '8px',
                  background: '#22c55e',
                  borderRadius: '50%',
                  boxShadow: '0 0 8px rgba(34, 197, 94, 0.6)'
                }}></div>
              </div>

              <div style={{ fontSize: '13px', color: '#475569', marginBottom: '4px' }}>
                <strong>Location:</strong>
              </div>
              <div style={{
                fontSize: '12px',
                color: '#64748b',
                fontFamily: 'monospace',
                background: '#f1f5f9',
                padding: '6px 8px',
                borderRadius: '4px',
                marginBottom: '8px'
              }}>
                {latitude.toFixed(6)}, {longitude.toFixed(6)}
              </div>

              {snappedLocation && (
                <div style={{
                  fontSize: '11px',
                  color: '#10b981',
                  marginBottom: '8px',
                  padding: '4px 8px',
                  background: '#f0fdf4',
                  borderRadius: '4px',
                  border: '1px solid #86efac'
                }}>
                  📍 Snapped to road
                </div>
              )}

              {routeData && (
                <div style={{
                  fontSize: '12px',
                  color: '#475569',
                  marginTop: '8px',
                  padding: '6px 8px',
                  background: '#eff6ff',
                  borderRadius: '4px',
                  border: '1px solid #bfdbfe'
                }}>
                  <div><strong>ETA:</strong> {formatDuration(routeData.duration)}</div>
                  <div><strong>Distance:</strong> {formatDistance(routeData.distance)}</div>
                </div>
              )}

              {lastUpdate && (
                <div style={{ fontSize: '11px', color: '#94a3b8', textAlign: 'center', marginTop: '8px' }}>
                  Last updated: {new Date(lastUpdate).toLocaleTimeString()}
                </div>
              )}
            </div>
          </Popup>
        </Marker>

        {/* Children Home Markers */}
        {childrenLocations.map((child, index) => (
          <Marker
            key={index}
            position={[child.latitude, child.longitude]}
            icon={createHomeIcon()}
          >
            <Popup>
              <div style={{ padding: '6px' }}>
                <div style={{ fontWeight: '600', fontSize: '14px', marginBottom: '4px' }}>
                  {child.name}
                </div>
                <div style={{ fontSize: '12px', color: '#64748b' }}>
                  {child.address}
                </div>
              </div>
            </Popup>
          </Marker>
        ))}
        
        <MapUpdater latitude={displayLocation.latitude} longitude={displayLocation.longitude} recenterTrigger={recenterTrigger} />
      </MapContainer>
    </div>
  );
};

export default BusMap;
