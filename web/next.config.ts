import type { NextConfig } from "next";

// 교재용으로 설정을 최소로 유지합니다.
const nextConfig: NextConfig = {
  // 개발 서버(npm run dev)를 안드로이드 에뮬레이터의 웹뷰(주소 10.0.2.2)에서도 열 수 있게 허용합니다.
  // 앱이 3D 지도 화면(/embed/map3d)을 웹뷰로 띄울 때 필요합니다. 배포한 웹에는 영향이 없습니다.
  allowedDevOrigins: ["10.0.2.2"],
  // Tailwind CSS v4 를 Turbopack 에서 처리하는 설정 (create-next-app 이 만들어 준 그대로)
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
