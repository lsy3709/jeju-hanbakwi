import type { NextConfig } from "next";

// 교재용으로 설정을 최소로 유지합니다.
const nextConfig: NextConfig = {
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
