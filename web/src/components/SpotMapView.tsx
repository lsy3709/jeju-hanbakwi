"use client";

// ssr: false 는 서버가 첫 화면을 만들 때 이 컴포넌트를 건너뛰라는 뜻입니다. 지도 라이브러리는 브라우저에만 있는 window 를 쓰기 때문입니다.
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
