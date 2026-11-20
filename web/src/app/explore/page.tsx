"use client";

// 탐색: 검색어와 테마를 주소의 쿼리(?q=&theme=)와 항상 맞춥니다.
// → 새로고침하거나 주소를 공유해도 같은 화면이 나옵니다.
import { Suspense } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { SearchBar } from "@/components/SearchBar";
import { SpotCard } from "@/components/SpotCard";
import { Empty, Loading } from "@/components/States";
import { ThemeChips } from "@/components/ThemeChips";
import { buildQuery } from "@/lib/format";
import { findSpots, THEMES } from "@/lib/spots";

// useSearchParams 를 쓰는 화면은 Suspense 로 감싸야 빌드가 통과합니다.
export default function ExplorePage() {
  return (
    <Suspense fallback={<Loading />}>
      <Explore />
    </Suspense>
  );
}

function Explore() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // 1) 주소에서 현재 검색어와 테마를 읽습니다.
  const q = searchParams.get("q") ?? "";
  const theme = searchParams.get("theme") ?? "";

  // 2) 바꾸면 주소를 바꿉니다.
  function update(changes: Record<string, string>) {
    router.replace(`${pathname}${buildQuery({ q, theme, ...changes })}`, { scroll: false });
  }

  // 3) 임시 데이터에서 화면 안에서 직접 걸러 냅니다. (3일차에 서버에 물어보는 것으로 바뀝니다)
  const spots = findSpots({ q, theme });

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-extrabold">탐색</h1>

      {/* key={q}: 주소의 q 가 바뀌면 입력창도 새로 만들어 글자를 맞춥니다 */}
      <SearchBar key={q} initial={q} onSearch={(text) => update({ q: text })} />

      <ThemeChips themes={THEMES} selected={theme} onSelect={(t) => update({ theme: t })} />

      {spots.length === 0 ? (
        <Empty title="조건에 맞는 장소가 없어요" hint="검색어나 테마를 바꿔 보세요." />
      ) : (
        <>
          <p className="text-sm text-muted">총 {spots.length}곳</p>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {spots.map((spot) => (
              <SpotCard key={spot.id} spot={spot} />
            ))}
          </div>
        </>
      )}
    </div>
  );
}
