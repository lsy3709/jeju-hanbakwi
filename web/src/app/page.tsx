"use client";

// 홈: 인사 + 검색바 → 테마 칩 → "지금 가기 좋은 곳"
import { useRouter } from "next/navigation";
import { SearchBar } from "@/components/SearchBar";
import { SpotCard } from "@/components/SpotCard";
import { ThemeChips } from "@/components/ThemeChips";
import { BRAND } from "@/lib/brand";
import { buildQuery } from "@/lib/format";
import { findSpots, THEMES } from "@/lib/spots";

export default function HomePage() {
  const router = useRouter();
  // 임시 데이터의 앞쪽 6건 (3일차에 서버에서 받아 옵니다)
  const recommended = findSpots().slice(0, 6);

  return (
    <div className="space-y-8">
      <section className="space-y-4 pt-2">
        <h1 className="text-3xl font-extrabold md:text-4xl">{BRAND.greeting}</h1>
        <SearchBar onSearch={(q) => router.push(`/explore${buildQuery({ q })}`)} />
      </section>

      <section aria-label="테마" className="space-y-3">
        <h2 className="text-lg font-bold">테마로 찾기</h2>
        <ThemeChips themes={THEMES} onSelect={(theme) => router.push(`/explore${buildQuery({ theme })}`)} />
      </section>

      <section aria-label="지금 가기 좋은 곳" className="space-y-3">
        <h2 className="text-lg font-bold">지금 가기 좋은 곳</h2>
        <div className="no-scrollbar -mx-4 flex snap-x gap-4 overflow-x-auto px-4 pb-2">
          {recommended.map((spot) => (
            <SpotCard key={spot.id} spot={spot} className="w-64 shrink-0 snap-start" />
          ))}
        </div>
      </section>
    </div>
  );
}
