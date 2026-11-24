// 이 파일이 하는 일: 모든 화면을 감싸는 맨 바깥 틀(루트 layout)입니다. 글꼴 불러오기, 로그인 상태 공급(AuthProvider), 위쪽 메뉴(Header)를 한 번만 두고, 각 화면(page.tsx)은 children 자리에 들어옵니다.
// "use client" 가 없는 서버 컴포넌트라서 metadata 로 사이트 제목·설명을 지정할 수 있습니다.
import type { Metadata, Viewport } from "next";
import "./globals.css";
import { AuthProvider } from "@/components/AuthProvider";
import { Header } from "@/components/Header";
import { BRAND } from "@/lib/brand";

export const metadata: Metadata = {
  title: { default: `${BRAND.name} - ${BRAND.tagline}`, template: `%s | ${BRAND.name}` },
  description: BRAND.description,
};

export const viewport: Viewport = { themeColor: "#F26B1D" };

// children 은 지금 주소에 해당하는 화면입니다. Next.js 가 알아서 넣어 줍니다.
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <head>
        {/* Pretendard 글꼴. 불러오지 못하면 globals.css 의 시스템 글꼴로 대체됩니다. */}
        <link
          rel="stylesheet"
          href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css"
        />
      </head>
      <body className="min-h-screen antialiased">
        <AuthProvider>
          <Header />
          {/* 아래 pb-24 는 좁은 화면에서 하단 탭에 내용이 가리지 않게 하는 여백 */}
          <main className="mx-auto w-full max-w-6xl px-4 pb-24 pt-6 md:pb-12">{children}</main>
        </AuthProvider>
      </body>
    </html>
  );
}
