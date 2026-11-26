"use client";

// 판타지 지도를 "브라우저에서만" 불러오는 얇은 껍데기. (Three.js 와 모델 파일은 용량이 커서 필요할 때만 받습니다)
import dynamic from "next/dynamic";

export const SpotMapFantasyView = dynamic(() => import("./SpotMapFantasy"), {
  ssr: false,
  loading: () => (
    <div role="status" className="flex h-full min-h-48 items-center justify-center rounded-card bg-sand text-sm text-muted">
      판타지 지도를 불러오는 중이에요...
    </div>
  ),
});
