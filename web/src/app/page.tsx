"use client";

// 홈: 인사 + 검색바 → 날씨 배너 → 테마 칩 → "지금 가기 좋은 곳" → AI 플래너 안내
import Link from "next/link";
import { useCallback } from "react";
import { useRouter } from "next/navigation";
import { Sparkles } from "lucide-react";
import { SearchBar } from "@/components/SearchBar";
import { SpotCard } from "@/components/SpotCard";
import { ThemeChips } from "@/components/ThemeChips";
import { WeatherBanner } from "@/components/WeatherBanner";
import { ErrorBox, Loading } from "@/components/States";
import { btnPrimary } from "@/components/ui";
import { BRAND } from "@/lib/brand";
import { buildQuery } from "@/lib/format";
import { getMeta, getSpots, getWeather } from "@/lib/api";
import { useAsync } from "@/hooks/useAsync";

export default function HomePage() {
  const router = useRouter();
  const meta = useAsync(getMeta);
  const weather = useAsync(getWeather);

  return (
    <div className="space-y-8">
      <section className="space-y-4 pt-2">
        <h1 className="text-3xl font-extrabold md:text-4xl">{BRAND.greeting}</h1>
        <SearchBar onSearch={(q) => router.push(`/explore${buildQuery({ q })}`)} />
      </section>

      {weather.data ? (
        <WeatherBanner weather={weather.data} />
      ) : weather.error ? (
        <p role="status" className="rounded-card bg-sand px-4 py-3 text-sm text-muted">
          날씨를 불러오지 못했어요. ({weather.error})
        </p>
      ) : null}

      <section aria-label="테마" className="space-y-3">
        <h2 className="text-lg font-bold">테마로 찾기</h2>
        {meta.data && (
          <ThemeChips themes={meta.data.themes} onSelect={(theme) => router.push(`/explore${buildQuery({ theme })}`)} />
        )}
        {meta.loading && <Loading />}
        {meta.error && <ErrorBox message={meta.error} onRetry={meta.reload} />}
      </section>

      <section aria-label="지금 가기 좋은 곳" className="space-y-3">
        <h2 className="text-lg font-bold">지금 가기 좋은 곳</h2>
        {/* 날씨 확인이 끝난 뒤에 불러옵니다. 날씨를 못 불러오면 비 안 오는 것으로 보고 실외 장소를 보여 줍니다. */}
        {weather.loading ? <Loading /> : <Recommended indoor={weather.data?.rainy_today ?? false} />}
      </section>

      <section className="flex flex-col items-start gap-3 rounded-card bg-primary/10 p-6 md:flex-row md:items-center md:justify-between">
        <div className="space-y-1">
          <h2 className="flex items-center gap-2 text-lg font-bold">
            <Sparkles size={20} className="text-primary" aria-hidden="true" />
            AI에게 일정 맡기기
          </h2>
          <p className="text-sm text-muted">누구와, 며칠 가는지만 알려 주세요. 날씨까지 고려해 일정을 짜 드려요.</p>
        </div>
        <Link href="/planner" className={btnPrimary}>
          일정 짜러 가기
        </Link>
      </section>
    </div>
  );
}

// 비 오는 날은 실내(indoor=true), 아니면 실외(indoor=false) 장소 8개
function Recommended({ indoor }: { indoor: boolean }) {
  const load = useCallback(() => getSpots({ indoor, size: 8 }), [indoor]);
  const spots = useAsync(load);

  if (spots.loading) return <Loading />;
  if (spots.error) return <ErrorBox message={spots.error} onRetry={spots.reload} />;
  if (!spots.data || spots.data.items.length === 0) {
    return <p className="text-sm text-muted">추천할 장소가 아직 없어요.</p>;
  }
  // 어느 폭에서든 격자로 모두 보여 줍니다(폰 2칸 · 태블릿 3칸 · PC 4칸).
  // 옆으로 넘기는 한 줄은 마우스로 넘길 수 없고, 폰에서도 카드가 화면 끝에서 잘려 보여 쓰지 않습니다.
  return (
    <div className="grid grid-cols-2 gap-3 md:grid-cols-3 md:gap-4 lg:grid-cols-4">
      {spots.data.items.map((spot) => (
        <SpotCard key={spot.id} spot={spot} />
      ))}
    </div>
  );
}
