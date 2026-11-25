"use client";

// 이 파일이 하는 일: 탐색 화면 조립. 필터 상태는 주소의 쿼리(?q=&theme=&area=&category=&indoor=&view=map|3d)와 항상 맞춥니다.
// → 새로고침하거나 주소를 공유해도 같은 화면이 나옵니다. (쿼리 ↔ 필터 변환은 lib/exploreFilters.ts, 검색 상태는 hooks/useSpotSearch.ts)
import { Suspense, useMemo } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { List, Map as MapIcon, Mountain } from "lucide-react";
import { FilterSelect } from "@/components/FilterSelect";
import { MoreButton } from "@/components/MoreButton";
import { SearchBar } from "@/components/SearchBar";
import { SpotCard } from "@/components/SpotCard";
import { SpotMap3DView } from "@/components/SpotMap3DView";
import { SpotMapView } from "@/components/SpotMapView";
import { Empty, ErrorBox, Loading } from "@/components/States";
import { ThemeChips } from "@/components/ThemeChips";
import { chip } from "@/components/ui";
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
  const { q, theme, area, category, indoorText, view, filters } = state;
  const { list: current, hasMore, loadMore, moreBusy, reload } = useSpotSearch(filters);

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
        {/* 보는 방식 세 가지: 목록 · 지도 · 3D 지도. 주소의 view 값으로 기억합니다. */}
        <div className="ml-auto flex gap-2" role="group" aria-label="보는 방식">
          {[
            { label: "목록", value: "", icon: List },
            { label: "지도", value: "map", icon: MapIcon },
            { label: "3D 지도", value: "3d", icon: Mountain },
          ].map((option) => (
            <button
              key={option.label}
              type="button"
              aria-pressed={view === option.value}
              onClick={() => update({ view: option.value })}
              className={chip(view === option.value)}
            >
              <option.icon size={16} aria-hidden="true" className="mr-1 inline" />
              {option.label}
            </button>
          ))}
        </div>
      </div>

      {current === null ? (
        <Loading />
      ) : current.error && current.items.length === 0 ? (
        <ErrorBox message={current.error} onRetry={reload} />
      ) : current.items.length === 0 ? (
        <Empty title="조건에 맞는 장소가 없어요" hint="검색어나 필터를 바꿔 보세요." />
      ) : (
        <>
          {/* total 은 첫 묶음에서만 오므로 useCursorList 가 기억해 둔 값을 씁니다 */}
          <p className="text-sm text-muted">
            {current.total !== null
              ? `총 ${current.total}곳 중 ${current.items.length}곳을 보여 드려요`
              : `${current.items.length}곳을 보여 드려요`}
          </p>
          {view === "3d" ? (
            <SpotMap3DView spots={current.items} className="h-[60vh] w-full rounded-card border border-line" />
          ) : view === "map" ? (
            <SpotMapView spots={current.items} className="h-[60vh] w-full rounded-card border border-line" />
          ) : (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {current.items.map((spot) => (
                <SpotCard key={spot.id} spot={spot} />
              ))}
            </div>
          )}
          {current.error && <ErrorBox message={current.error} />}
          {/* 다음 묶음이 남았을 때(next_cursor 가 null 이 아닐 때)만 버튼이 보입니다 */}
          <MoreButton hasMore={hasMore} busy={moreBusy} onMore={loadMore} />
        </>
      )}
    </div>
  );
}
