// 3D 지도(MapLibre GL JS)에 쓰는 계산과 설정을 모은 순수 함수입니다. 화면 없이 테스트할 수 있어요.
import type { StyleSpecification } from "maplibre-gl";
import type { MapSpot } from "./mapSpots";

/** 제주도 가운데 [경도, 위도]. MapLibre 는 Leaflet 과 반대로 경도가 먼저입니다. */
export const JEJU_CENTER: [number, number] = [126.55, 33.38];
/** 한라산 백록담. 블렌더에서 만든 모델(돌하르방)을 세워 두는 자리입니다. */
export const HALLASAN: [number, number] = [126.5332, 33.3617];
/** 땅의 높낮이를 실제보다 얼마나 과장해 보여 줄지. 제주는 완만해서 1.5배로 세웁니다. */
export const EXAGGERATION = 1.5;
/** 모델 파일 주소(web/public/models). `python tools/make_model.py` 또는 블렌더에서 내보낸 glb. */
export const MODEL_URL = "/models/dolhareubang.glb";

const EARTH_CIRCUMFERENCE = 40075016.686; // 적도 둘레(미터)

/** 핀을 모두 담는 범위 [[서, 남], [동, 북]]. 곳이 없으면 null. */
export function boundsOf(spots: MapSpot[]): [[number, number], [number, number]] | null {
  if (spots.length === 0) return null;
  const lngs = spots.map((s) => s.lng);
  const lats = spots.map((s) => s.lat);
  return [
    [Math.min(...lngs), Math.min(...lats)],
    [Math.max(...lngs), Math.max(...lats)],
  ];
}

/** 화면 1픽셀이 실제로 몇 미터인지. 확대(zoom)가 1 늘면 절반이 됩니다. (MapLibre 의 타일 한 장은 512픽셀) */
export function metersPerPixel(zoom: number, lat: number): number {
  return (EARTH_CIRCUMFERENCE * Math.cos((lat * Math.PI) / 180)) / (512 * 2 ** zoom);
}

/** 모델이 화면에서 늘 pixels 높이쯤으로 보이게 하려면 실제 높이를 몇 미터로 해야 하는지. */
export function modelHeightMeters(zoom: number, lat: number, pixels = 90): number {
  return metersPerPixel(zoom, lat) * pixels;
}

/** 땅의 높이 자료(AWS Terrain Tiles). 색으로 높이를 적어 둔 그림이라 encoding 을 알려 줘야 합니다. */
function heightSource(): StyleSpecification["sources"][string] {
  return {
    type: "raster-dem",
    tiles: ["https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png"],
    tileSize: 256,
    maxzoom: 13,
    encoding: "terrarium",
    attribution: '높이 자료 <a href="https://registry.opendata.aws/terrain-tiles/">AWS Terrain Tiles</a>',
  };
}

/**
 * 지도 모양 설정. 키가 필요 없는 무료 자료 두 가지를 씁니다.
 * - osm: 바탕 그림(OpenStreetMap)
 * - dem · shade: 땅의 높이 자료. dem 으로 땅을 세우고 shade 로 그림자를 그립니다.
 */
export function terrainStyle(): StyleSpecification {
  return {
    version: 8,
    sources: {
      osm: {
        type: "raster",
        tiles: ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
        tileSize: 256,
        maxzoom: 19,
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      },
      dem: heightSource(),
      // 그림자용으로 같은 자료를 한 번 더 둡니다(하나를 같이 쓰면 그림이 거칠어진다고 MapLibre 가 알려 줍니다).
      shade: heightSource(),
    },
    layers: [
      { id: "osm", type: "raster", source: "osm" },
      // 그림자를 넣어 산과 오름의 굴곡이 눈에 보이게 합니다.
      { id: "hills", type: "hillshade", source: "shade", paint: { "hillshade-exaggeration": 0.35 } },
    ],
    terrain: { source: "dem", exaggeration: EXAGGERATION },
  };
}
