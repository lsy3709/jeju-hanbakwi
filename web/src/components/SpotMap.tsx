"use client";

// 지도(Leaflet + OpenStreetMap). 브라우저에서만 동작하므로 SpotMapView 를 통해 불러옵니다.
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import Link from "next/link";
import { useEffect } from "react";
import { MapContainer, Marker, Popup, TileLayer, useMap } from "react-leaflet";

export type MapSpot = { id: number; title: string; lat: number; lng: number };

// Leaflet 기본 핀 이미지는 번들러에서 경로가 깨지기 쉬워서, CSS 로 직접 그린 핀(divIcon)을 씁니다.
const pin = L.divIcon({
  className: "", // Leaflet 기본 클래스(흰 네모)를 없앱니다
  html: '<div class="jeju-pin" style="width:26px;height:26px"></div>',
  iconSize: [26, 26],
  iconAnchor: [13, 26], // 핀 끝이 좌표를 가리키도록
  popupAnchor: [0, -26],
});

// 핀이 여러 개면 전부 보이도록 지도 범위를 맞춥니다.
function FitBounds({ spots }: { spots: MapSpot[] }) {
  const map = useMap();
  useEffect(() => {
    if (spots.length > 1) {
      map.fitBounds(
        spots.map((s) => [s.lat, s.lng] as [number, number]),
        { padding: [30, 30], maxZoom: 13 },
      );
    }
  }, [map, spots]);
  return null;
}

export default function SpotMap({ spots, className = "" }: { spots: MapSpot[]; className?: string }) {
  const first = spots[0];
  const center: [number, number] = first ? [first.lat, first.lng] : [33.38, 126.55]; // 제주도 가운데
  const zoom = spots.length === 1 ? 14 : 9;

  return (
    <MapContainer center={center} zoom={zoom} scrollWheelZoom={false} className={`z-0 ${className}`}>
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <FitBounds spots={spots} />
      {spots.map((spot) => (
        <Marker key={spot.id} position={[spot.lat, spot.lng]} icon={pin} title={spot.title}>
          <Popup>
            <strong>{spot.title}</strong>
            <br />
            <Link href={`/spots/${spot.id}`} className="text-secondary underline">
              자세히
            </Link>
          </Popup>
        </Marker>
      ))}
    </MapContainer>
  );
}
