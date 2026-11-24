"use client";

// "use client" 는 이 화면이 브라우저에서 도는 컴포넌트라는 표시입니다. 데이터를 useAsync 로 불러오고 검색·클릭에 반응하기 때문입니다.
// 층: 이 화면(app/) → hooks/useAsync → lib/api.ts. 화면 파일은 fetch 를 직접 부르지 않습니다.
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

// default export 는 Next.js 가 "주소 "/" 의 화면"으로 쓰는 약속된 이름입니다. useAsync 는 불러오는 중 / 오류 / 결과 상태를 돌려줍니다.
export default function HomePage() {
  // router.push 는 화면을 새로고침하지 않고 다른 주소로 옮기는 함수입니다. 검색어·테마는 주소의 쿼리(?q=, ?theme=)에 담아 탐색 화면으로 넘깁니다.
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
// "Recommended" 는 이 파일 안에서만 쓰는 작은 컴포넌트입니다. indoor 값이 바뀔 때만(useCallback) 서버에서 8곳을 다시 받습니다.
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
