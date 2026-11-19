"use client";

// 넓은 화면: 위쪽 메뉴 / 768px 미만: 아래쪽 탭 4개
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Compass, Heart, Home, Sparkles, type LucideIcon } from "lucide-react";
import { BRAND, NAV_ITEMS } from "@/lib/brand";

const ICONS: Record<(typeof NAV_ITEMS)[number]["icon"], LucideIcon> = {
  home: Home,
  compass: Compass,
  sparkles: Sparkles,
  heart: Heart,
};

// 지금 주소가 메뉴의 href 에 해당하는지("/" 는 정확히 같을 때만)
function isActive(pathname: string, href: string) {
  return href === "/" ? pathname === "/" : pathname === href || pathname.startsWith(href + "/");
}

export function Header() {
  const pathname = usePathname();

  return (
    <>
      <header className="sticky top-0 z-40 border-b border-line bg-surface/90 backdrop-blur">
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
          <Link href="/" className="text-lg font-extrabold text-primary">
            {BRAND.name}
          </Link>
          {/* 넓은 화면에서만 보이는 상단 메뉴 */}
          <nav aria-label="주요 메뉴" className="hidden gap-1 md:flex">
            {NAV_ITEMS.map((item) => {
              const active = isActive(pathname, item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  aria-current={active ? "page" : undefined}
                  className={`rounded-pill px-4 py-2 text-sm font-semibold transition-colors ${
                    active ? "bg-primary text-white" : "text-ink hover:bg-sand"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>
      </header>

      {/* 좁은 화면에서만 보이는 하단 탭 */}
      <nav
        aria-label="하단 메뉴"
        className="fixed inset-x-0 bottom-0 z-40 grid grid-cols-4 border-t border-line bg-surface md:hidden"
      >
        {NAV_ITEMS.map((item) => {
          const Icon = ICONS[item.icon];
          const active = isActive(pathname, item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              aria-current={active ? "page" : undefined}
              className={`flex flex-col items-center gap-0.5 py-2 text-xs font-semibold ${
                active ? "text-primary" : "text-muted"
              }`}
            >
              <Icon size={22} aria-hidden="true" />
              {item.label}
            </Link>
          );
        })}
      </nav>
    </>
  );
}
