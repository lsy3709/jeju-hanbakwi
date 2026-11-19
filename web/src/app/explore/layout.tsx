import type { Metadata } from "next";

// 화면 파일(page.tsx)이 "use client" 라서, 제목·설명은 이 layout 에서 지정합니다.
export const metadata: Metadata = {
  title: "탐색",
  description: "테마·지역·실내외 필터로 제주 관광지를 찾아보세요.",
};

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
