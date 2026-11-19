"use client";

// 탐색: 필터 상태를 주소의 쿼리(?q=&theme=&area=&category=&indoor=&view=map)와 항상 맞춥니다.
// → 새로고침하거나 주소를 공유해도 같은 화면이 나옵니다.
import { Suspense, useEffect, useMemo, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { List, Map as MapIcon } from "lucide-react";
import { SearchBar } from "@/components/SearchBar";
import { SpotCard } from "@/components/SpotCard";
import { SpotMapView } from "@/components/SpotMapView";
import { Empty, ErrorBox, Loading } from "@/components/States";
import { ThemeChips } from "@/components/ThemeChips";
import { btnOutline, chip } from "@/components/ui";
import { errorMessage, getMeta, getSpots } from "@/lib/api";
import { buildQuery, spotsQuery } from "@/lib/format";
import type { Spot, SpotsParams } from "@/lib/types";
import { useAsync } from "@/lib/useAsync";

const PAGE_SIZE = 20;

// useSearchParams 를 쓰는 화면은 Suspense 로 감싸야 빌드가 통과합니다.
export default function ExplorePage() {
  return (
    <Suspense fallback={<Loading />}>
      <Explore />
    </Suspense>
  );
}

type Result = { key: string; items: Spot[]; total: number; page: number; error: string | null };

function Explore() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const meta = useAsync(getMeta);

  // 1) 주소에서 현재 필터를 읽습니다.
  const q = searchParams.get("q") ?? "";
  const theme = searchParams.get("theme") ?? "";
  const area = searchParams.get("area") ?? "";
  const category = searchParams.get("category") ?? "";
  const indoorText = searchParams.get("indoor") ?? ""; // "true" | "false" | ""
  const isMap = searchParams.get("view") === "map";

  const filters = useMemo<SpotsParams>(
    () => ({
      q: q || undefined,
      theme: theme || undefined,
      area: area || undefined,
      category: category || undefined,
      indoor: indoorText === "" ? undefined : indoorText === "true",
    }),
    [q, theme, area, category, indoorText],
  );
  const key = spotsQuery(filters); // 필터가 바뀌었는지 비교하는 용도

  // 2) 필터를 바꾸면 주소를 바꿉니다. (view 는 그대로 유지)
  function update(changes: Record<string, string>) {
    const next = { q, theme, area, category, indoor: indoorText, view: isMap ? "map" : "", ...changes };
    router.replace(`${pathname}${buildQuery(next)}`, { scroll: false });
  }

  // 3) 필터가 바뀌면 1쪽부터 다시 불러옵니다.
  const [result, setResult] = useState<Result | null>(null);
  const [reloadTick, setReloadTick] = useState(0);
  const [moreBusy, setMoreBusy] = useState(false);
  useEffect(() => {
    let cancelled = false;
    getSpots({ ...filters, page: 1, size: PAGE_SIZE }).then(
      (r) => !cancelled && setResult({ key, items: r.items, total: r.total, page: 1, error: null }),
      (e) => !cancelled && setResult({ key, items: [], total: 0, page: 1, error: errorMessage(e) }),
    );
    return () => {
      cancelled = true;
    };
  }, [filters, key, reloadTick]);

  // 지금 필터에 대한 결과만 보여 줍니다. 필터가 막 바뀌어 아직 안 왔으면 null(= 불러오는 중)
  const current = result !== null && result.key === key ? result : null;

  // 4) "더 보기": 다음 쪽을 받아 뒤에 이어 붙입니다.
  async function loadMore() {
    if (!result) return;
    setMoreBusy(true);
    try {
      const next = await getSpots({ ...filters, page: result.page + 1, size: PAGE_SIZE });
      setResult({ ...result, items: [...result.items, ...next.items], total: next.total, page: next.page });
    } catch (e) {
      setResult({ ...result, error: errorMessage(e) });
    } finally {
      setMoreBusy(false);
    }
  }

  const hasFilter = Object.values(filters).some((v) => v !== undefined);

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
        {hasFilter && (
          <button type="button" onClick={() => router.replace(pathname, { scroll: false })} className="text-sm text-muted underline">
            필터 지우기
          </button>
        )}
        <button
          type="button"
          onClick={() => update({ view: isMap ? "" : "map" })}
          className={`${btnOutline} ml-auto`}
        >
          {isMap ? <List size={18} aria-hidden="true" /> : <MapIcon size={18} aria-hidden="true" />}
          {isMap ? "목록 보기" : "지도 보기"}
        </button>
      </div>

      {current === null ? (
        <Loading />
      ) : current.error && current.items.length === 0 ? (
        <ErrorBox message={current.error} onRetry={() => setReloadTick((n) => n + 1)} />
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

function FilterSelect({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: string[];
  onChange: (value: string) => void;
}) {
  return (
    <label className="flex items-center gap-2 text-sm">
      <span className="text-muted">{label}</span>
      <select
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="rounded-pill border border-line bg-surface px-3 py-2 text-sm"
      >
        <option value="">전체</option>
        {options.map((option) => (
          <option key={option} value={option}>
            {option}
          </option>
        ))}
      </select>
    </label>
  );
}
