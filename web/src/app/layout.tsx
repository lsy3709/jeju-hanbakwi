import type { Metadata, Viewport } from "next";
import "./globals.css";
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
        <header className="border-b border-line bg-surface">
          <div className="mx-auto flex h-14 max-w-6xl items-center px-4">
            <span className="text-lg font-extrabold text-primary">{BRAND.name}</span>
          </div>
        </header>
        <main className="mx-auto w-full max-w-6xl px-4 pb-12 pt-6">{children}</main>
      </body>
    </html>
  );
}
