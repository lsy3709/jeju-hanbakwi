"use client";

// 넓은 화면: 위쪽 메뉴 / 768px 미만: 아래쪽 탭 4개 (관리자면 "관리자"가 하나 더 붙어 5개)
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Compass,
  Heart,
  Home,
  Settings,
  Shield,
  Sparkles,
  type LucideIcon,
} from "lucide-react";
import { ADMIN_NAV_ITEM, BRAND, NAV_ITEMS } from "@/lib/brand";
import { useAuth } from "./AuthProvider";

type NavItem = (typeof NAV_ITEMS)[number] | typeof ADMIN_NAV_ITEM;

const ICONS: Record<NavItem["icon"], LucideIcon> = {
  home: Home,
  compass: Compass,
  sparkles: Sparkles,
  heart: Heart,
  shield: Shield,
};

// 지금 주소가 메뉴의 href 에 해당하는지("/" 는 정확히 같을 때만)
function isActive(pathname: string, href: string) {
  return href === "/"
    ? pathname === "/"
    : pathname === href || pathname.startsWith(href + "/");
}

export function Header() {
  const pathname = usePathname();
  const { me } = useAuth();
  // /me 가 관리자라고 알려 줄 때만 "관리자" 메뉴를 더합니다(로그인 전·확인 전에는 보이지 않음).
  const items: readonly NavItem[] = me?.is_admin
    ? [...NAV_ITEMS, ADMIN_NAV_ITEM]
    : NAV_ITEMS;

  return (
    <>
      <header className="sticky top-0 z-40 border-b border-line bg-surface/90 backdrop-blur">
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
          <Link href="/" className="text-lg font-extrabold text-primary">
            {BRAND.name}
          </Link>
          <div className="flex items-center gap-1">
            {/* 넓은 화면에서만 보이는 상단 메뉴 */}
            <nav aria-label="주요 메뉴" className="hidden gap-1 md:flex">
              {items.map((item) => {
                const active = isActive(pathname, item.href);
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    aria-current={active ? "page" : undefined}
                    className={`rounded-pill px-4 py-2 text-sm font-semibold transition-colors ${
                      active
                        ? "bg-primary text-white"
                        : "text-ink hover:bg-sand"
                    }`}
                  >
                    {item.label}
                  </Link>
                );
              })}
            </nav>
            {/* 설정은 모든 폭에서 오른쪽 위 톱니바퀴로 엽니다(아래 탭의 칸 수를 늘리지 않으려고). */}
            <Link
              href="/settings"
              aria-label="설정"
              aria-current={
                isActive(pathname, "/settings") ? "page" : undefined
              }
              className={`inline-flex h-10 w-10 items-center justify-center rounded-pill transition-colors ${
                isActive(pathname, "/settings")
                  ? "bg-primary text-white"
                  : "text-ink hover:bg-sand"
              }`}
            >
              <Settings size={20} aria-hidden="true" />
            </Link>
          </div>
        </div>
      </header>

      {/* 좁은 화면에서만 보이는 하단 탭. Tailwind 는 글자 그대로 적힌 클래스만 만들므로 grid-cols-5 / grid-cols-4 를 통째로 고릅니다. */}
      <nav
        aria-label="하단 메뉴"
        className={`fixed inset-x-0 bottom-0 z-40 grid border-t border-line bg-surface md:hidden ${
          items.length === 5 ? "grid-cols-5" : "grid-cols-4"
        }`}
      >
        {items.map((item) => {
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
