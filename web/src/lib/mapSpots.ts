// 지도에 그릴 수 있는 곳만 고르는 계산. 관리자가 위치 없이 추가한 여행지는 lat · lng 가 null 입니다.

export type MaybeLocated = { id: number; title: string; lat: number | null; lng: number | null };
export type MapSpot = { id: number; title: string; lat: number; lng: number };

/** 위치(lat · lng)가 둘 다 있는 곳만 남깁니다. 0 도 숫자이므로 null 인지로만 가립니다. */
export function withLocation(spots: MaybeLocated[]): MapSpot[] {
  return spots.flatMap((s) => (s.lat !== null && s.lng !== null ? [{ id: s.id, title: s.title, lat: s.lat, lng: s.lng }] : []));
}
