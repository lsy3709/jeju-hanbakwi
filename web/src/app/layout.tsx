import type { Metadata, Viewport } from "next";
import "./globals.css";
import { Header } from "@/components/Header";
import { BRAND } from "@/lib/brand";

export const metadata: Metadata = {
  title: { default: `${BRAND.name} - ${BRAND.tagline}`, template: `%s | ${BRAND.name}` },
  description: BRAND.description,
};

export const viewport: Viewport = { themeColor: "#F26B1D" };

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
        <Header />
        {/* 아래 pb-24 는 좁은 화면에서 하단 탭에 내용이 가리지 않게 하는 여백 */}
        <main className="mx-auto w-full max-w-6xl px-4 pb-24 pt-6 md:pb-12">{children}</main>
      </body>
    </html>
  );
}
