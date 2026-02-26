import React, { useEffect, useRef, useCallback, useState } from 'react';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN as string;
const MAPBOX_STYLE = import.meta.env.VITE_MAPBOX_STYLE_ID as string;

export interface BusMapProps {
  latitude: number;
  longitude: number;
  busNumber?: string;
  route?: string;
  lastUpdate?: string;
  recenterTrigger?: number;
  childrenLocations?: Array<{
    latitude: number;
    longitude: number;
    name: string;
    address: string;
    /** Estimated road duration from bus (seconds) — shown as ETA badge on pin */
    duration?: number;
  }>;
  showRoute?: boolean;
  /** Called whenever the map resolves a human-readable place name for the bus position */
  onPlaceName?: (name: string) => void;
}

/** Format seconds → human-readable ETA string */
function formatEta(seconds: number): string {
  if (seconds < 60) return '< 1 min';
  if (seconds < 3600) return `${Math.round(seconds / 60)} min`;
  const h = Math.floor(seconds / 3600);
  const m = Math.round((seconds % 3600) / 60);
  return m === 0 ? `${h}h` : `${h}h ${m}m`;
}

/**
 * Query the already-loaded Mapbox vector tiles for the nearest road or place
 * name at a given pixel coordinate — no extra API calls needed.
 */
function queryPlaceName(
  map: mapboxgl.Map,
  point: mapboxgl.PointLike,
): string | null {
  // Layers that carry human-readable names in standard Mapbox styles
  const labelLayers = [
    'road-label',
    'road-label-simple',
    'road-label-navigation',
    'road-street-label',
    'road-secondary-tertiary-label',
    'road-primary-label',
    'road-motorway-trunk-label',
    'place-neighborhood-suburb-label',
    'place-city-label',
    'place-town-village-hamlet-label',
    'poi-label',
  ];

  // Widen the query radius so we always catch a nearby label
  const bbox: [mapboxgl.PointLike, mapboxgl.PointLike] = [
    [
      (point as [number, number])[0] - 60,
      (point as [number, number])[1] - 60,
    ],
    [
      (point as [number, number])[0] + 60,
      (point as [number, number])[1] + 60,
    ],
  ];

  const features = map.queryRenderedFeatures(bbox, { layers: labelLayers });

  if (!features.length) return null;

  // Prefer road labels over place labels
  const roadFeature = features.find((f) =>
    (f.layer.id ?? '').startsWith('road'),
  );
  const best = roadFeature ?? features[0];
  const name =
    (best.properties?.name as string | undefined) ??
    (best.properties?.name_en as string | undefined) ??
    null;
  return name;
}

/** Creates the Google Maps-style navigation arrow element for the bus marker. */
function createBusElement(busNumber: string): HTMLElement {
  const wrapper = document.createElement('div');
  wrapper.style.cssText = 'position:relative;width:52px;height:52px;';

  // Pulse ring
  const pulse = document.createElement('div');
  pulse.style.cssText = `
    position:absolute;top:50%;left:50%;
    transform:translate(-50%,-50%);
    width:72px;height:72px;
    background:rgba(66,133,244,0.18);
    border-radius:50%;
    animation:mapbox-pulse 2s ease-out infinite;
  `;

  // White border circle
  const border = document.createElement('div');
  border.style.cssText = `
    position:absolute;top:50%;left:50%;
    transform:translate(-50%,-50%);
    width:48px;height:48px;
    background:#fff;
    border-radius:50%;
    box-shadow:0 2px 10px rgba(0,0,0,0.3);
  `;

  // Blue circle with navigation arrow
  const circle = document.createElement('div');
  circle.style.cssText = `
    position:absolute;top:50%;left:50%;
    transform:translate(-50%,-50%);
    width:40px;height:40px;
    background:#4285F4;
    border-radius:50%;
    display:flex;align-items:center;justify-content:center;
  `;
  circle.innerHTML = `
    <svg width="18" height="18" viewBox="0 0 20 20" fill="none">
      <path d="M10 2 L17 16 L10 12 L3 16 Z" fill="white"/>
    </svg>
  `;

  // Bus number label
  const label = document.createElement('div');
  label.style.cssText = `
    position:absolute;bottom:-20px;left:50%;
    transform:translateX(-50%);
    background:rgba(26,26,46,0.9);
    color:#fff;font-size:10px;font-weight:600;
    padding:2px 6px;border-radius:4px;white-space:nowrap;
  `;
  label.textContent = busNumber;

  if (!document.getElementById('mapbox-pulse-style')) {
    const style = document.createElement('style');
    style.id = 'mapbox-pulse-style';
    style.textContent = `
      @keyframes mapbox-pulse {
        0%   { transform:translate(-50%,-50%) scale(0.8); opacity:0.8; }
        50%  { transform:translate(-50%,-50%) scale(1.3); opacity:0.3; }
        100% { transform:translate(-50%,-50%) scale(0.8); opacity:0.8; }
      }
    `;
    document.head.appendChild(style);
  }

  wrapper.appendChild(pulse);
  wrapper.appendChild(border);
  wrapper.appendChild(circle);
  wrapper.appendChild(label);
  return wrapper;
}

/** Creates a home pin for a child's location. */
function createHomeElement(name: string): HTMLElement {
  const el = document.createElement('div');
  el.style.cssText = `
    width:32px;height:32px;
    background:linear-gradient(135deg,#10b981,#059669);
    border-radius:50%;
    display:flex;align-items:center;justify-content:center;
    border:2px solid #fff;
    box-shadow:0 2px 8px rgba(0,0,0,0.3);
    cursor:pointer;
  `;
  el.innerHTML = `
    <svg width="16" height="16" viewBox="0 0 576 512" fill="white">
      <path d="M575.8 255.5c0 18-15 32.1-32 32.1h-32l.7 160.2c0 2.7-.2 5.4-.5 8.1V472c0 22.1-17.9 40-40 40H456c-1.1 0-2.2 0-3.3-.1c-1.4.1-2.8.1-4.2.1H416 392c-22.1 0-40-17.9-40-40V448 384c0-17.7-14.3-32-32-32H256c-17.7 0-32 14.3-32 32v64 24c0 22.1-17.9 40-40 40H160 128.1c-1.5 0-3-.1-4.5-.2c-1.2.1-2.4.2-3.6.2H104c-22.1 0-40-17.9-40-40V360c0-.9 0-1.9.1-2.8V287.6H32c-18 0-32-14-32-32.1c0-9 3-17 10-24L266.4 8c7-7 15-8 22-8s15 2 21 7L564.8 231.5c8 7 12 15 11 24z"/>
    </svg>
  `;
  el.title = name;
  return el;
}

const BusMap: React.FC<BusMapProps> = ({
  latitude,
  longitude,
  busNumber = 'Bus',
  route = '',
  lastUpdate,
  recenterTrigger,
  childrenLocations = [],
  onPlaceName,
}) => {
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<mapboxgl.Map | null>(null);
  const busMarker = useRef<mapboxgl.Marker | null>(null);
  const busPopupRef = useRef<mapboxgl.Popup | null>(null);
  const homeMarkers = useRef<mapboxgl.Marker[]>([]);
  const routeLayerAdded = useRef(false);
  const [placeName, setPlaceName] = useState<string | null>(null);

  /** Project bus coords to screen pixels, query vector tile labels; falls back to geocoding API. */
  const refreshPlaceName = useCallback(async () => {
    const m = map.current;
    if (!m || !m.isStyleLoaded()) return;

    const pixel = m.project([longitude, latitude]);
    const name = queryPlaceName(m, [pixel.x, pixel.y]);
    if (name) {
      setPlaceName(name);
      onPlaceName?.(name);
      return;
    }

    // Fallback: Mapbox Reverse Geocoding API
    try {
      const res = await fetch(
        `https://api.mapbox.com/geocoding/v5/mapbox.places/${longitude},${latitude}.json` +
          `?types=neighborhood,locality,place,address&limit=1&access_token=${MAPBOX_TOKEN}`,
      );
      if (!res.ok) return;
      const data = await res.json();
      const geoName: string | undefined = data.features?.[0]?.text;
      if (geoName) {
        setPlaceName(geoName);
        onPlaceName?.(geoName);
      }
    } catch (_) {}
  }, [latitude, longitude, onPlaceName]);

  // ── Initialise map (once) ───────────────────────────────────────────────────
  useEffect(() => {
    if (!mapContainer.current || map.current) return;

    mapboxgl.accessToken = MAPBOX_TOKEN;

    map.current = new mapboxgl.Map({
      container: mapContainer.current,
      style: `mapbox://styles/${MAPBOX_STYLE}`,
      center: [longitude, latitude],
      zoom: 15,
    });

    map.current.addControl(
      new mapboxgl.NavigationControl({ visualizePitch: false }),
      'bottom-right',
    );

    // Resize to fill container (important when rendered inside a modal)
    map.current.once('load', () => map.current?.resize());

    // After tiles finish loading, query for the place name
    map.current.once('idle', refreshPlaceName);

    // Bus marker
    const busEl = createBusElement(busNumber);
    const popup = new mapboxgl.Popup({
      offset: 30,
      closeButton: false,
      className: 'apobasi-bus-popup',
    });
    busPopupRef.current = popup;

    busMarker.current = new mapboxgl.Marker({ element: busEl, anchor: 'center' })
      .setLngLat([longitude, latitude])
      .setPopup(popup)
      .addTo(map.current);

    return () => {
      map.current?.remove();
      map.current = null;
      busMarker.current = null;
      busPopupRef.current = null;
      homeMarkers.current = [];
      routeLayerAdded.current = false;
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Sync popup content with latest place name ────────────────────────────────
  useEffect(() => {
    const displayLocation = placeName ?? `${latitude.toFixed(5)}, ${longitude.toFixed(5)}`;
    busPopupRef.current?.setHTML(`
      <div style="padding:8px;min-width:180px">
        <div style="font-weight:700;font-size:14px;margin-bottom:4px">${busNumber}</div>
        ${route ? `<div style="color:#64748b;font-size:12px;margin-bottom:4px">${route}</div>` : ''}
        <div style="display:flex;align-items:center;gap:4px;color:#374151;font-size:12px;margin-top:6px">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#4285F4" stroke-width="2">
            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/>
            <circle cx="12" cy="9" r="2.5"/>
          </svg>
          <span>${displayLocation}</span>
        </div>
        ${lastUpdate ? `<div style="color:#94a3b8;font-size:11px;margin-top:4px">Updated: ${new Date(lastUpdate).toLocaleTimeString()}</div>` : ''}
      </div>
    `);
  }, [placeName, busNumber, route, lastUpdate, latitude, longitude]);

  // ── Update bus position + re-query place name ────────────────────────────────
  useEffect(() => {
    busMarker.current?.setLngLat([longitude, latitude]);
    if (map.current && !map.current.isMoving()) {
      map.current.setCenter([longitude, latitude]);
    }
    // Re-query after move settles
    map.current?.once('idle', refreshPlaceName);
  }, [latitude, longitude, refreshPlaceName]);

  // ── Recenter trigger ─────────────────────────────────────────────────────────
  useEffect(() => {
    if (recenterTrigger && map.current) {
      map.current.flyTo({ center: [longitude, latitude], zoom: 16, duration: 600 });
      map.current.once('idle', refreshPlaceName);
    }
  }, [recenterTrigger]); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Route + children markers ─────────────────────────────────────────────────
  const updateRoute = useCallback(async () => {
    const m = map.current;
    if (!m || !m.isStyleLoaded()) return;

    if (childrenLocations.length < 1) {
      if (routeLayerAdded.current) {
        if (m.getLayer('route-line')) m.removeLayer('route-line');
        if (m.getSource('route')) m.removeSource('route');
        routeLayerAdded.current = false;
      }
      return;
    }

    try {
      const waypoints = [
        [longitude, latitude],
        ...childrenLocations.map((c) => [c.longitude, c.latitude]),
      ]
        .slice(0, 25)
        .map((p) => p.join(','))
        .join(';');

      const res = await fetch(
        `https://api.mapbox.com/directions/v5/mapbox/driving/${waypoints}` +
          `?geometries=geojson&overview=full&access_token=${MAPBOX_TOKEN}`,
      );
      if (!res.ok) return;
      const data = await res.json();
      if (!data.routes?.[0]) return;

      const geojson: GeoJSON.Feature = {
        type: 'Feature',
        properties: {},
        geometry: data.routes[0].geometry,
      };

      if (m.getSource('route')) {
        (m.getSource('route') as mapboxgl.GeoJSONSource).setData(geojson);
      } else {
        m.addSource('route', { type: 'geojson', data: geojson });
        m.addLayer({
          id: 'route-line',
          type: 'line',
          source: 'route',
          layout: { 'line-join': 'round', 'line-cap': 'round' },
          paint: {
            'line-color': '#4285F4',
            'line-width': 4,
            'line-opacity': 0.75,
            'line-dasharray': [2, 1],
          },
        });
        routeLayerAdded.current = true;
      }
    } catch (_) {}
  }, [latitude, longitude, childrenLocations]);

  useEffect(() => {
    const m = map.current;
    if (!m) return;

    homeMarkers.current.forEach((mk) => mk.remove());
    homeMarkers.current = [];

    childrenLocations.forEach((child, idx) => {
      const el = createHomeElement(child.name);
      const etaLabel = child.duration != null ? formatEta(child.duration) : null;
      const popup = new mapboxgl.Popup({ offset: 20, closeButton: false }).setHTML(`
        <div style="padding:6px;min-width:140px">
          <div style="display:flex;align-items:center;justify-content:space-between;gap:8px">
            <div style="font-weight:600;font-size:13px">${child.name}</div>
            <div style="font-size:10px;font-weight:600;background:#eef2ff;color:#4338ca;padding:2px 6px;border-radius:4px;white-space:nowrap">
              Stop ${idx + 1}
            </div>
          </div>
          ${child.address ? `<div style="color:#64748b;font-size:11px;margin-top:2px">${child.address}</div>` : ''}
          ${etaLabel ? `<div style="margin-top:4px;font-size:11px;color:#059669;font-weight:600">⏱ ETA: ${etaLabel}</div>` : ''}
        </div>
      `);
      const marker = new mapboxgl.Marker({ element: el, anchor: 'center' })
        .setLngLat([child.longitude, child.latitude])
        .setPopup(popup)
        .addTo(m);
      homeMarkers.current.push(marker);
    });

    if (m.isStyleLoaded()) {
      updateRoute();
    } else {
      m.once('load', updateRoute);
    }
  }, [childrenLocations, updateRoute]);

  return (
    <div className="w-full h-96 rounded-lg overflow-hidden border border-slate-200 relative">
      <div ref={mapContainer} style={{ width: '100%', height: '100%' }} />
      {/* Place name overlay badge */}
      {placeName && (
        <div
          style={{
            position: 'absolute',
            bottom: 36,
            left: '50%',
            transform: 'translateX(-50%)',
            background: 'rgba(26,26,46,0.88)',
            color: '#fff',
            fontSize: '12px',
            fontWeight: 600,
            padding: '4px 10px',
            borderRadius: 6,
            pointerEvents: 'none',
            whiteSpace: 'nowrap',
            maxWidth: '80%',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
          }}
        >
          📍 {placeName}
        </div>
      )}
    </div>
  );
};

export default BusMap;
