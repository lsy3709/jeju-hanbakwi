import type { Metadata } from "next";

// 화면 파일(page.tsx)이 "use client" 라서, 제목·설명은 이 layout 에서 지정합니다.
export const metadata: Metadata = {
  title: "내 여행",
  description: "찜한 장소와 저장한 여행 일정을 한곳에서 확인하세요.",
};

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
