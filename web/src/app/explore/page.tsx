"use client";

// 이 파일이 하는 일: 탐색 화면 조립. 필터 상태는 주소의 쿼리(?q=&theme=&area=&category=&indoor=&view=map)와 항상 맞춥니다.
// → 새로고침하거나 주소를 공유해도 같은 화면이 나옵니다. (쿼리 ↔ 필터 변환은 lib/exploreFilters.ts, 검색 상태는 hooks/useSpotSearch.ts)
import { Suspense, useMemo } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { List, Map as MapIcon } from "lucide-react";
import { FilterSelect } from "@/components/FilterSelect";
import { SearchBar } from "@/components/SearchBar";
import { SpotCard } from "@/components/SpotCard";
import { SpotMapView } from "@/components/SpotMapView";
import { Empty, ErrorBox, Loading } from "@/components/States";
import { ThemeChips } from "@/components/ThemeChips";
import { btnOutline, chip } from "@/components/ui";
import { useAsync } from "@/hooks/useAsync";
import { useSpotSearch } from "@/hooks/useSpotSearch";
import { getMeta } from "@/lib/api";
import { exploreHref, hasActiveFilter, parseExploreQuery } from "@/lib/exploreFilters";

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
  const meta = useAsync(getMeta);

  // 주소가 바뀔 때만 필터를 새로 만듭니다(그래야 useSpotSearch 가 쓸데없이 다시 불러오지 않습니다).
  const state = useMemo(() => parseExploreQuery(searchParams), [searchParams]);
  const { q, theme, area, category, indoorText, isMap, filters } = state;
  const { current, loadMore, moreBusy, reload } = useSpotSearch(filters);

  // 필터를 바꾸면 주소를 바꿉니다. (view 는 그대로 유지)
  const update = (changes: Record<string, string>) =>
    router.replace(exploreHref(pathname, state, changes), { scroll: false });

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-extrabold">탐색</h1>

      {/* key={q}: 주소의 q 가 바뀌면 입력창도 새로 만들어 글자를 맞춥니다 */}
      <SearchBar key={q} initial={q} onSearch={(text) => update({ q: text })} />

      {meta.data && <ThemeChips themes={meta.data.themes} selected={theme} onSelect={(t) => update({ theme: t })} />}

      <div className="flex flex-wrap items-center gap-3">
        <FilterSelect label="지역" value={area} options={meta.data?.areas ?? []} onChange={(v) => update({ area: v })} />
        <FilterSelect label="분류" value={category} options={meta.data?.categories ?? []} onChange={(v) => update({ category: v })} />
        <div className="flex gap-2" role="group" aria-label="실내 실외">
          {[
            { label: "전체", value: "" },
            { label: "실내", value: "true" },
            { label: "실외", value: "false" },
          ].map((option) => (
            <button
              key={option.label}
              type="button"
              aria-pressed={indoorText === option.value}
              onClick={() => update({ indoor: option.value })}
              className={chip(indoorText === option.value)}
            >
              {option.label}
            </button>
          ))}
        </div>
        {hasActiveFilter(filters) && (
          <button type="button" onClick={() => router.replace(pathname, { scroll: false })} className="text-sm text-muted underline">
            필터 지우기
          </button>
        )}
        <button type="button" onClick={() => update({ view: isMap ? "" : "map" })} className={`${btnOutline} ml-auto`}>
          {isMap ? <List size={18} aria-hidden="true" /> : <MapIcon size={18} aria-hidden="true" />}
          {isMap ? "목록 보기" : "지도 보기"}
        </button>
      </div>

      {current === null ? (
        <Loading />
      ) : current.error && current.items.length === 0 ? (
        <ErrorBox message={current.error} onRetry={reload} />
      ) : current.items.length === 0 ? (
        <Empty title="조건에 맞는 장소가 없어요" hint="검색어나 필터를 바꿔 보세요." />
      ) : (
        <>
          <p className="text-sm text-muted">
            총 {current.total}곳 중 {current.items.length}곳을 보여 드려요
          </p>
          {isMap ? (
            <SpotMapView spots={current.items} className="h-[60vh] w-full rounded-card border border-line" />
          ) : (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {current.items.map((spot) => (
                <SpotCard key={spot.id} spot={spot} />
              ))}
            </div>
          )}
          {current.error && <ErrorBox message={current.error} />}
          {current.items.length < current.total && (
            <div className="flex justify-center">
              <button type="button" onClick={loadMore} disabled={moreBusy} className={btnOutline}>
                {moreBusy ? "불러오는 중..." : "더 보기"}
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
