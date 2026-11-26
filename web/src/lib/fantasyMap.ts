// 판타지 지도(블렌더로 만든 제주도 모델)에 쓰는 계산을 모은 순수 함수입니다.
// 아래 숫자는 모델을 만드는 tools/make_jeju_heightmap.py · make_fantasy_jeju.py 와 같아야 핀이 제자리에 섭니다.

/** 모델이 담고 있는 네모(우도 · 마라도 포함). */
export const BOUNDS = { west: 126.08, east: 127.02, south: 33.1, north: 33.62 };
/** 모델의 가로(동서) 길이. */
export const SIZE_X = 10;
/** 모델의 세로(남북) 길이 — 실제 거리 비율대로 줄였습니다. */
export const SIZE_Z =
  (SIZE_X * ((BOUNDS.north - BOUNDS.south) * 110.9)) /
  ((BOUNDS.east - BOUNDS.west) * 111.32 * Math.cos((((BOUNDS.south + BOUNDS.north) / 2) * Math.PI) / 180));
/** 모델 파일 주소(web/public/models). 블렌더에서 만들어 glb 로 내보낸 것입니다. */
export const FANTASY_MODEL_URL = "/models/fantasy_jeju.glb";

/** 경도 · 위도 → 모델 안의 자리. 동쪽이 +x, 북쪽이 -z 입니다(Three.js 에서 -z 가 화면 안쪽). */
export function lngLatToModel(lng: number, lat: number): { x: number; z: number } {
  const x = ((lng - BOUNDS.west) / (BOUNDS.east - BOUNDS.west) - 0.5) * SIZE_X;
  const north = ((lat - BOUNDS.south) / (BOUNDS.north - BOUNDS.south) - 0.5) * SIZE_Z;
  return { x, z: north === 0 ? 0 : -north };
}

/**
 * 화면 비율(가로 ÷ 세로)에 따라 카메라를 얼마나 뒤로 뺄지(배수).
 * 섬은 가로로 길어서, 휴대폰처럼 세로로 긴 화면에서는 뒤로 물러나야 섬 전체가 들어옵니다.
 */
export function cameraPullBack(aspect: number): number {
  return Math.min(2.4, Math.max(1, 1.2 / aspect));
}

/** 모델이 담고 있는 네모 안의 곳인지. 밖의 곳은 핀을 세우지 않습니다. */
export function inBounds(lng: number, lat: number): boolean {
  return lng >= BOUNDS.west && lng <= BOUNDS.east && lat >= BOUNDS.south && lat <= BOUNDS.north;
}
