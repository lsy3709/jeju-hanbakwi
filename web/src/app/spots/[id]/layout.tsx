import type { Metadata } from "next";

// 화면 파일(page.tsx)이 "use client" 라서, 제목·설명은 이 layout 에서 지정합니다.
export const metadata: Metadata = {
  title: "관광지 상세",
  description: "제주 관광지의 사진, 소개, 위치를 확인하세요.",
};

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
