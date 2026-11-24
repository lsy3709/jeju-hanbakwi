"use client";

// "use client" 는 이 파일이 브라우저에서 도는 컴포넌트라는 표시입니다. 클릭에 반응하거나 useState 로 값을 기억하려면 필요합니다.
// 쓰는 곳: SpotMapView.tsx 가 브라우저에서만 불러옵니다. 낱말 풀이: 마커 = 지도 위 핀, 팝업 = 핀을 누르면 뜨는 말풍선, 타일 = 지도 그림 조각입니다.
// 지도(Leaflet + OpenStreetMap). 브라우저에서만 동작하므로 SpotMapView 를 통해 불러옵니다.
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import Link from "next/link";
import { useEffect, useMemo } from "react";
import { MapContainer, Marker, Popup, TileLayer, useMap } from "react-leaflet";
import { withLocation, type MapSpot, type MaybeLocated } from "@/lib/mapSpots";

// Leaflet 기본 핀 이미지는 번들러에서 경로가 깨지기 쉬워서, CSS 로 직접 그린 핀(divIcon)을 씁니다.
const pin = L.divIcon({
  className: "", // Leaflet 기본 클래스(흰 네모)를 없앱니다
  html: '<div class="jeju-pin" style="width:26px;height:26px"></div>',
  iconSize: [26, 26],
  iconAnchor: [13, 26], // 핀 끝이 좌표를 가리키도록
  popupAnchor: [0, -26],
});

// 핀이 여러 개면 전부 보이도록 지도 범위를 맞춥니다.
// useMap() 으로 지도를 얻어, 핀이 둘 이상이면 전부 한 화면에 들어오게 지도 범위를 맞춥니다.
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

// default export 는 SpotMapView 의 dynamic(() => import(...)) 가 이름 없이 불러오려고 이렇게 합니다. spots 중 위치가 있는 곳만 그립니다.
export default function SpotMap({ spots: all, className = "" }: { spots: MaybeLocated[]; className?: string }) {
  // 위치가 없는 곳은 지도에 그릴 수 없으니 뺍니다(Leaflet 은 null 좌표에서 오류를 냅니다).
  const spots = useMemo(() => withLocation(all), [all]);
  const first = spots[0];
  // 핀이 있으면 첫 핀, 없으면 제주도 가운데를 지도 중심으로 합니다.
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
