"use client";

// 3D 지도(MapLibre GL JS + Three.js). 땅의 높낮이를 세워 보여 주고, 한라산에 블렌더 모델(돌하르방)을 올립니다.
// 브라우저에서만 동작하므로 SpotMap3DView 를 통해 불러옵니다. 계산과 지도 설정은 lib/map3d.ts 에 있습니다.
import "maplibre-gl/dist/maplibre-gl.css";
import { Map as MapLibreMap, Marker, MercatorCoordinate, NavigationControl, Popup, type CustomLayerInterface } from "maplibre-gl";
import { useEffect, useMemo, useRef } from "react";
import * as THREE from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { boundsOf, HALLASAN, JEJU_CENTER, MODEL_URL, modelHeightMeters, terrainStyle } from "@/lib/map3d";
import { withLocation, type MaybeLocated } from "@/lib/mapSpots";

/**
 * Three.js 로 그린 모델을 지도 위에 얹는 "사용자 레이어".
 * MapLibre 가 화면을 그릴 때마다 render 를 부르고, 우리는 지도와 같은 카메라로 모델을 한 번 더 그립니다.
 */
function modelLayer(map: MapLibreMap): CustomLayerInterface {
  const scene = new THREE.Scene();
  const camera = new THREE.Camera();
  let renderer: THREE.WebGLRenderer | null = null;

  // 빛이 없으면 모델이 검게 보입니다. 전체를 밝히는 빛 + 한쪽에서 비추는 빛.
  scene.add(new THREE.AmbientLight(0xffffff, 1.6));
  const sun = new THREE.DirectionalLight(0xffffff, 2.2);
  sun.position.set(1, 2, 1);
  scene.add(sun);

  return {
    id: "model",
    type: "custom",
    renderingMode: "3d",
    onAdd(_map, gl) {
      // 지도가 쓰는 캔버스와 그리기 도구(gl)를 그대로 빌려 씁니다. 그래서 지도 위에 겹쳐 그려집니다.
      renderer = new THREE.WebGLRenderer({ canvas: map.getCanvas(), context: gl, antialias: true });
      renderer.autoClear = false; // 지도가 그린 것을 지우지 않습니다
      new GLTFLoader().load(MODEL_URL, (gltf) => {
        scene.add(gltf.scene);
        map.triggerRepaint();
      });
    },
    render(_gl, args) {
      if (!renderer) return;
      // 모델을 세울 자리: 한라산의 경도·위도 + 그 자리의 땅 높이
      const ground = map.queryTerrainElevation(HALLASAN) ?? 0;
      const origin = MercatorCoordinate.fromLngLat(HALLASAN, ground);
      // 모델은 높이 1미터로 만들었습니다. 확대 정도에 맞춰 키워, 화면에서 늘 비슷한 크기로 보이게 합니다.
      const meters = modelHeightMeters(map.getZoom(), HALLASAN[1]);
      const scale = origin.meterInMercatorCoordinateUnits() * meters;
      // 지도 좌표 → 모델 좌표: 자리로 옮기고, 크기를 맞추고, 누워 있는 모델을 세웁니다(모델은 Y 가 위, 지도는 Z 가 위).
      const place = new THREE.Matrix4()
        .makeTranslation(origin.x, origin.y, origin.z)
        .scale(new THREE.Vector3(scale, -scale, scale))
        .multiply(new THREE.Matrix4().makeRotationX(Math.PI / 2));
      camera.projectionMatrix = new THREE.Matrix4().fromArray(args.defaultProjectionData.mainMatrix).multiply(place);
      renderer.resetState();
      renderer.render(scene, camera);
    },
    onRemove() {
      renderer?.dispose();
      renderer = null;
    },
  };
}

export default function SpotMap3D({ spots: all, className = "" }: { spots: MaybeLocated[]; className?: string }) {
  const box = useRef<HTMLDivElement>(null);
  const spots = useMemo(() => withLocation(all), [all]);

  useEffect(() => {
    if (!box.current) return;
    const map = new MapLibreMap({
      container: box.current,
      style: terrainStyle(),
      center: JEJU_CENTER,
      zoom: 9.2,
      pitch: 60, // 지도를 눕혀 비스듬히 내려다봅니다
      bearing: -15,
      maxPitch: 80,
      cooperativeGestures: true, // 휴대폰에서 화면을 내리다 지도가 대신 움직이는 일을 막습니다(두 손가락으로 움직임)
      locale: {
        "CooperativeGesturesHandler.WindowsHelpText": "Ctrl 을 누른 채 스크롤하면 지도가 확대돼요",
        "CooperativeGesturesHandler.MacHelpText": "⌘ 을 누른 채 스크롤하면 지도가 확대돼요",
        "CooperativeGesturesHandler.MobileHelpText": "두 손가락으로 지도를 움직여요",
      },
    });
    map.addControl(new NavigationControl({ visualizePitch: true }), "top-right");
    map.on("load", () => map.addLayer(modelLayer(map)));

    // 핀은 평면 지도와 같은 모양(.jeju-pin)을 씁니다.
    for (const spot of spots) {
      const pin = document.createElement("div");
      pin.innerHTML = '<div class="jeju-pin" style="width:22px;height:22px"></div>';
      pin.title = spot.title;
      const link = document.createElement("a");
      link.href = `/spots/${spot.id}`;
      link.textContent = `${spot.title} · 자세히`;
      link.className = "font-semibold text-secondary underline";
      new Marker({ element: pin, anchor: "bottom" })
        .setLngLat([spot.lng, spot.lat])
        .setPopup(new Popup({ offset: 24 }).setDOMContent(link))
        .addTo(map);
    }
    const bounds = boundsOf(spots);
    if (bounds && spots.length > 1) map.fitBounds(bounds, { padding: 60, maxZoom: 12, pitch: 60, bearing: -15, duration: 0 });
    if (spots.length === 1) map.jumpTo({ center: [spots[0].lng, spots[0].lat], zoom: 12.5 });

    return () => map.remove(); // 화면을 떠나면 지도를 치웁니다(그래픽 메모리 반납)
  }, [spots]);

  return <div ref={box} className={`z-0 overflow-hidden ${className}`} aria-label="3D 지도" />;
}
