"use client";

// 판타지 지도: 블렌더로 만든 제주도 모델(glb)을 Three.js 로 띄우고, 관광지를 그 위에 핀으로 세웁니다.
// 제주 시각에 따라 낮과 밤이 바뀝니다(밤에는 별이 뜨고 마을에 불이 켜짐). 낮밤 계산은 lib/fantasySky.ts.
// 실제 지도 타일을 쓰지 않고 모델 하나만 그립니다. 브라우저에서만 동작하므로 SpotMapFantasyView 를 통해 불러옵니다.
// 좌표 계산은 lib/fantasyMap.ts 에 있습니다.
import { Clock, Moon, Sun } from "lucide-react";
import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { cameraPullBack, FANTASY_MODEL_URL, inBounds, lngLatToModel } from "@/lib/fantasyMap";
import { daynessOf, mixColor, nextSkyMode, skyLabel, type SkyMode } from "@/lib/fantasySky";
import { withLocation, type MapSpot, type MaybeLocated } from "@/lib/mapSpots";

const PAPER = 0xf1e4c6; // 오래된 지도 종이 색(낮의 배경)
const NIGHT = 0x131d36; // 밤하늘 색(밤의 배경)
const SKY_ICONS = { auto: Clock, day: Sun, night: Moon };
const PIN = 0xf26b1d; // 감귤 오렌지(핀)

/** 핀 하나: 뒤집은 원뿔 위에 공. 눌렀을 때 어느 곳인지 알 수 있게 spot 을 달아 둡니다. */
function makePin(spot: MapSpot): THREE.Group {
  const paint = new THREE.MeshStandardMaterial({ color: PIN, roughness: 0.5 });
  const tip = new THREE.Mesh(new THREE.ConeGeometry(0.06, 0.2, 10), paint);
  tip.rotation.x = Math.PI; // 뾰족한 쪽이 아래로
  tip.position.y = 0.1;
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.085, 14, 10), paint);
  head.position.y = 0.26;
  const pin = new THREE.Group();
  pin.add(tip, head);
  pin.userData.spot = spot;
  return pin;
}

type Props = {
  spots: MaybeLocated[];
  className?: string;
  /** 고른 곳의 안내에 상세 화면 링크를 넣을지. 앱에 끼워 넣는 화면에서는 이름만 보여 줍니다. */
  linkToDetail?: boolean;
};

export default function SpotMapFantasy({ spots: all, className = "", linkToDetail = true }: Props) {
  const box = useRef<HTMLDivElement>(null);
  const [selected, setSelected] = useState<MapSpot | null>(null);
  const [ready, setReady] = useState(false);
  // 하늘: 지금 제주 시각을 따르거나(auto), 낮 · 밤으로 고정합니다. 그리는 쪽은 ref 로 최신 값을 읽습니다.
  const [sky, setSky] = useState<SkyMode>("auto");
  const skyRef = useRef<SkyMode>("auto");
  useEffect(() => {
    skyRef.current = sky;
  }, [sky]);
  // 모델 밖(제주 밖)의 곳과 위치가 없는 곳은 세울 수 없으니 뺍니다.
  const spots = useMemo(() => withLocation(all).filter((s) => inBounds(s.lng, s.lat)), [all]);

  useEffect(() => {
    const holder = box.current;
    if (!holder) return;

    const scene = new THREE.Scene();
    const paper = new THREE.Color(PAPER); // 배경 색. 낮밤에 따라 매 화면마다 바꿉니다
    const fog = new THREE.Fog(PAPER, 26, 46); // 멀리 있는 것은 배경 색으로 흐려집니다
    scene.background = paper;
    scene.fog = fog;

    const camera = new THREE.PerspectiveCamera(42, holder.clientWidth / holder.clientHeight, 0.1, 100);
    // 세로로 긴 화면(휴대폰)에서는 뒤로 물러나 섬 전체가 보이게 합니다.
    camera.position.set(0.4, 6.2, 7.9).multiplyScalar(cameraPullBack(holder.clientWidth / holder.clientHeight));

    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.setSize(holder.clientWidth, holder.clientHeight);
    holder.appendChild(renderer.domElement);

    // 빛: 하늘에서 고르게 내려오는 빛 + 한쪽에서 비추는 해
    const skyLight = new THREE.HemisphereLight(0xffffff, 0xb9a57c, 1.5);
    const sun = new THREE.DirectionalLight(0xfff3d6, 2.4); // 밤에는 푸른 달빛으로 바뀝니다
    sun.position.set(5, 9, 4);
    scene.add(skyLight, sun);

    // 밤하늘의 별: 섬을 둘러싼 둥근 하늘에 점 500개. 낮에는 투명하게 숨깁니다.
    // (지도를 위에서 내려다보기 때문에, 머리 위뿐 아니라 받침 둘레 아래쪽에도 별을 둡니다)
    const starSpots: number[] = [];
    for (let i = 0; i < 500; i++) {
      const around = Math.random() * Math.PI * 2;
      const up = -1.1 + Math.random() * 2.4; // 발아래부터 머리 위까지
      starSpots.push(34 * Math.cos(up) * Math.cos(around), 34 * Math.sin(up), 34 * Math.cos(up) * Math.sin(around));
    }
    const starShape = new THREE.BufferGeometry();
    starShape.setAttribute("position", new THREE.Float32BufferAttribute(starSpots, 3));
    const starPaint = new THREE.PointsMaterial({
      color: 0xffffff,
      size: 2.4, // 화면에서의 크기(픽셀). 멀리 있어도 작아지지 않게 합니다
      sizeAttenuation: false,
      transparent: true,
      opacity: 0,
      fog: false,
    });
    scene.add(new THREE.Points(starShape, starPaint));
    const windows: THREE.MeshStandardMaterial[] = []; // 마을 집의 벽 — 밤에 불빛이 새어 나오게 합니다
    let light = daynessOf(skyRef.current, new Date()); // 지금 얼마나 낮인지(0 밤 ~ 1 낮)

    // 마우스(손가락)로 돌리고 확대하기. 땅 밑으로 내려가거나 너무 멀어지지 않게 막습니다.
    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.target.set(0, 0.2, 0.3);
    controls.minDistance = 3;
    controls.maxDistance = 26;
    controls.maxPolarAngle = Math.PI / 2.25;

    const pins = new THREE.Group();
    scene.add(pins);
    let clouds: THREE.Object3D | null = null;
    let cancelled = false; // 모델을 받는 사이에 화면을 떠났으면 아무것도 하지 않습니다

    new GLTFLoader().load(FANTASY_MODEL_URL, (gltf) => {
      if (cancelled) return;
      scene.add(gltf.scene);
      clouds = gltf.scene.getObjectByName("clouds") ?? null;
      gltf.scene.traverse((part) => {
        if (part instanceof THREE.Mesh && part.material instanceof THREE.MeshStandardMaterial && part.material.name === "wall") {
          part.material.emissive.setHex(0xffb44d); // 따뜻한 등불 색
          windows.push(part.material);
        }
      });
      const terrain = gltf.scene.getObjectByName("terrain");
      // 땅의 면이 각지게 보이도록(종이를 접은 듯한 느낌)
      terrain?.traverse((part) => {
        if (part instanceof THREE.Mesh) (part.material as THREE.MeshStandardMaterial).flatShading = true;
      });
      // 핀 세우기: 위에서 아래로 선을 쏘아 그 자리의 땅 높이를 찾습니다.
      const down = new THREE.Raycaster();
      for (const spot of spots) {
        const { x, z } = lngLatToModel(spot.lng, spot.lat);
        down.set(new THREE.Vector3(x, 10, z), new THREE.Vector3(0, -1, 0));
        const ground = terrain ? down.intersectObject(terrain, true)[0]?.point.y : undefined;
        const pin = makePin(spot);
        pin.position.set(x, ground ?? 0.04, z);
        pins.add(pin);
      }
      setReady(true);
    });

    // 누른 자리에 핀이 있으면 그곳을 고릅니다.
    const pointer = new THREE.Raycaster();
    let downAt = { x: 0, y: 0 };
    const onDown = (e: PointerEvent) => (downAt = { x: e.clientX, y: e.clientY });
    const onUp = (e: PointerEvent) => {
      if (Math.hypot(e.clientX - downAt.x, e.clientY - downAt.y) > 6) return; // 끌어서 돌린 것은 누른 것으로 치지 않습니다
      const rect = renderer.domElement.getBoundingClientRect();
      const point = new THREE.Vector2(((e.clientX - rect.left) / rect.width) * 2 - 1, -((e.clientY - rect.top) / rect.height) * 2 + 1);
      pointer.setFromCamera(point, camera);
      const hit = pointer.intersectObjects(pins.children, true)[0];
      setSelected(hit ? ((hit.object.parent?.userData.spot as MapSpot) ?? null) : null);
    };
    renderer.domElement.addEventListener("pointerdown", onDown);
    renderer.domElement.addEventListener("pointerup", onUp);

    const onResize = () => {
      camera.aspect = holder.clientWidth / holder.clientHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(holder.clientWidth, holder.clientHeight);
    };
    const resizer = new ResizeObserver(onResize);
    resizer.observe(holder);

    // 매 화면마다: 낮밤을 맞추고, 구름을 천천히 흘리고, 핀을 살짝 통통 튀게 하고, 다시 그립니다.
    const clock = new THREE.Clock();
    renderer.setAnimationLoop(() => {
      const step = clock.getDelta(); // 앞 화면에서 지난 시간(초)
      const t = clock.elapsedTime;
      // 낮밤: 목표 값으로 조금씩 다가가서, 단추를 눌러도 하늘이 부드럽게(2초쯤에 걸쳐) 바뀝니다.
      light += (daynessOf(skyRef.current, new Date()) - light) * Math.min(1, step * 2.5);
      paper.setHex(mixColor(NIGHT, PAPER, light));
      fog.color.copy(paper);
      skyLight.intensity = 0.3 + 1.2 * light;
      sun.intensity = 0.55 + 1.85 * light;
      sun.color.setHex(mixColor(0x9bb3ff, 0xfff3d6, light));
      starPaint.opacity = 1 - light;
      windows.forEach((wall) => (wall.emissiveIntensity = (1 - light) * 1.4));
      if (clouds) clouds.position.x = Math.sin(t * 0.08) * 0.9;
      pins.children.forEach((pin, i) => (pin.scale.y = 1 + Math.sin(t * 2 + i) * 0.05));
      controls.update();
      renderer.render(scene, camera);
    });

    return () => {
      // 화면을 떠나면 그리기를 멈추고 그래픽 메모리를 돌려줍니다.
      cancelled = true;
      renderer.setAnimationLoop(null);
      resizer.disconnect();
      renderer.domElement.removeEventListener("pointerdown", onDown);
      renderer.domElement.removeEventListener("pointerup", onUp);
      controls.dispose();
      scene.traverse((part) => {
        if (part instanceof THREE.Mesh) {
          part.geometry.dispose();
          (Array.isArray(part.material) ? part.material : [part.material]).forEach((m) => m.dispose());
        }
      });
      starShape.dispose();
      starPaint.dispose();
      renderer.dispose();
      holder.removeChild(renderer.domElement);
    };
  }, [spots]);

  const SkyIcon = SKY_ICONS[sky];
  return (
    <div className={`relative z-0 overflow-hidden ${className}`}>
      <div ref={box} className="h-full w-full touch-none" aria-label="판타지 지도" />
      {!ready && (
        <p role="status" className="absolute inset-0 flex items-center justify-center text-sm text-muted">
          판타지 지도를 펼치는 중이에요...
        </p>
      )}
      <p className="pointer-events-none absolute left-3 top-3 rounded-pill bg-surface/85 px-3 py-1 text-xs text-muted">
        끌어서 돌리고, 핀을 눌러 보세요
      </p>
      <button
        type="button"
        onClick={() => setSky(nextSkyMode)}
        aria-label={`하늘: ${skyLabel(sky)} (누르면 바뀝니다)`}
        className="absolute right-3 top-3 inline-flex items-center gap-1 rounded-pill border border-line bg-surface/90 px-3 py-1.5 text-xs font-semibold text-ink"
      >
        <SkyIcon size={14} aria-hidden="true" />
        {skyLabel(sky)}
      </button>
      {selected && (
        <div className="absolute bottom-6 left-3 right-3 flex items-center justify-between gap-3 rounded-card border border-line bg-surface px-4 py-3 shadow-md sm:left-auto sm:w-80">
          <strong className="truncate">{selected.title}</strong>
          {linkToDetail && (
            <Link href={`/spots/${selected.id}`} className="shrink-0 font-semibold text-secondary underline">
              자세히
            </Link>
          )}
        </div>
      )}
      <p className="pointer-events-none absolute bottom-1 left-3 rounded-pill bg-surface/70 px-2 text-[10px] text-muted">높이 자료 AWS Terrain Tiles · 모델 Blender</p>
    </div>
  );
}
