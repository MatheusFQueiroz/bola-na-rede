'use client';

import { useEffect, useRef } from 'react';
import 'leaflet/dist/leaflet.css';

interface Props {
  lat: number;
  lng: number;
}

export default function MapPreview({ lat, lng }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    let cancelled = false;
    let leafletMap: import('leaflet').Map | null = null;

    void import('leaflet').then(L => {
      if (cancelled || !containerRef.current) return;

      const pin = L.divIcon({
        className: '',
        html: '<div style="width:14px;height:14px;border-radius:50%;background:#16a34a;border:2.5px solid white;box-shadow:0 2px 6px rgba(0,0,0,0.35)"></div>',
        iconSize: [14, 14],
        iconAnchor: [7, 7],
      });

      leafletMap = L.map(containerRef.current, {
        center: [lat, lng],
        zoom: 16,
        zoomControl: false,
        dragging: false,
        touchZoom: false,
        scrollWheelZoom: false,
        doubleClickZoom: false,
        boxZoom: false,
        keyboard: false,
        attributionControl: true,
      });

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a>',
        maxZoom: 19,
      }).addTo(leafletMap);

      L.marker([lat, lng], { icon: pin }).addTo(leafletMap);
    });

    return () => {
      cancelled = true;
      leafletMap?.remove();
    };
  }, [lat, lng]);

  return <div ref={containerRef} style={{ height: '160px', width: '100%' }} />;
}
