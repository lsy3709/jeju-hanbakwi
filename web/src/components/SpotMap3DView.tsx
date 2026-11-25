"use client";

// 3D 지도를 "브라우저에서만" 불러오는 얇은 껍데기. (MapLibre · Three.js 는 서버에서 실행할 수 없고, 용량도 커서 필요할 때만 받습니다)
import dynamic from "next/dynamic";

export const SpotMap3DView = dynamic(() => import("./SpotMap3D"), {
  ssr: false,
  loading: () => (
    <div role="status" className="flex h-full min-h-48 items-center justify-center rounded-card bg-sand text-sm text-muted">
      3D 지도를 불러오는 중이에요...
    </div>
  ),
});
