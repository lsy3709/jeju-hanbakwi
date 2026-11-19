"use client";

// 지도 컴포넌트를 "브라우저에서만" 불러오는 얇은 껍데기. (Leaflet 은 서버에서 실행하면 오류가 납니다)
import dynamic from "next/dynamic";

export const SpotMapView = dynamic(() => import("./SpotMap"), {
  ssr: false,
  loading: () => (
    <div role="status" className="flex h-full min-h-48 items-center justify-center rounded-card bg-sand text-sm text-muted">
      지도를 불러오는 중이에요...
    </div>
  ),
});
