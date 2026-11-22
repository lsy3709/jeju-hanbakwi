import type { Metadata } from "next";

// 화면 파일(page.tsx)이 "use client" 라서, 제목·설명은 이 layout 에서 지정합니다.
export const metadata: Metadata = {
  title: "관리자",
  description: "사용자 이용 정지와 여행지 추가·수정·숨김을 관리합니다.",
  robots: { index: false }, // 검색 결과에 나올 필요가 없는 화면
};

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
