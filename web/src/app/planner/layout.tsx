import type { Metadata } from "next";

// 화면 파일(page.tsx)이 "use client" 라서, 제목·설명은 이 layout 에서 지정합니다.
export const metadata: Metadata = {
  title: "AI 플래너",
  description: "하고 싶은 여행을 적으면 AI가 일자별 제주 여행 일정을 짜 드려요.",
};

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
