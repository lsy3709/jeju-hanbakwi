// 이 파일은 같은 폴더의 page.tsx 를 감싸는 layout 입니다. page.tsx 는 "use client" 라서 제목·설명(metadata)을 직접 지정할 수 없어, 이 파일이 대신 지정합니다.
// 화면에는 아무것도 더하지 않고 children(= page.tsx 가 그린 내용)을 그대로 돌려줍니다.
import type { Metadata } from "next";

// 화면 파일(page.tsx)이 "use client" 라서, 제목·설명은 이 layout 에서 지정합니다.
export const metadata: Metadata = {
  title: "AI 플래너",
  description: "하고 싶은 여행을 적으면 AI가 일자별 제주 여행 일정을 짜 드려요.",
};

export default function Layout({ children }: { children: React.ReactNode }) {
  return children;
}
