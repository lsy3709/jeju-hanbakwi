"use client";

// "use client" 는 이 화면이 브라우저에서 도는 컴포넌트라는 표시입니다. 클릭에 반응하고 useState·useEffect 같은 훅을 쓰려면 필요합니다.
// 층: 이 화면(app/) → hooks/ → lib/api.ts. 화면 파일은 fetch 를 직접 부르지 않습니다. page.tsx 는 폴더 이름에 해당하는 주소의 화면입니다.
// 폴더 이름 [id] 의 대괄호는 "주소의 이 자리가 바뀌는 값"이라는 뜻입니다(/spots/12 의 12). useParams 로 읽습니다.
// 상세: 큰 사진 → 분류·지역 → 제목 → 한 줄 소개 → 태그 → 실내/실외 → 소개 글 → 주소 → 지도 → 버튼 2개
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback } from "react";
import { MapPin, Sparkles } from "lucide-react";
import { FavoriteButton } from "@/components/FavoriteButton";
import { PhotoCredit } from "@/components/PhotoCredit";
import { SpotImage } from "@/components/SpotImage";
import { IndoorBadge } from "@/components/SpotCard";
import { SpotMapView } from "@/components/SpotMapView";
import { Empty, ErrorBox, Loading } from "@/components/States";
import { btnPrimary } from "@/components/ui";
import { getSpot } from "@/lib/api";
import { buildQuery } from "@/lib/format";
import { useAsync } from "@/hooks/useAsync";

export default function SpotDetailPage() {
  const params = useParams<{ id: string }>();
  const id = params.id;
  // id 가 바뀔 때만 새 함수를 만들어, 같은 여행지를 두 번 불러오지 않게 합니다.
  const load = useCallback(() => getSpot(id), [id]);
  const { data: spot, loading, error, status, reload } = useAsync(load);

  // 상태를 순서대로 확인합니다: 불러오는 중 → 없는 장소(404) → 오류 → 정상 화면. 서버가 꺼져 있어도 화면이 죽지 않습니다.
  if (loading) return <Loading />;
  // 서버가 404 를 주면 "없는 장소", 그 밖의 오류는 다시 시도 버튼
  if (status === 404) {
    return <Empty title="이 장소를 찾을 수 없어요" hint="주소가 틀렸거나 사라진 장소일 수 있어요." />;
  }
  if (error || !spot) return <ErrorBox message={error ?? "알 수 없는 오류"} onRetry={reload} />;

  return (
    <article className="mx-auto max-w-3xl space-y-5">
      <SpotImage imageUrl={spot.image_url} title={spot.title} tags={spot.theme_tags} className="aspect-16/9 w-full rounded-card" />
      <PhotoCredit spot={spot} />

      <div className="flex items-center gap-2 text-sm text-muted">
        <span>{spot.category}</span>
        <span aria-hidden="true">·</span>
        <span>{spot.area}</span>
        <IndoorBadge indoor={spot.indoor} />
      </div>

      <div className="space-y-2">
        <h1 className="text-3xl font-extrabold">{spot.title}</h1>
        <p className="text-lg text-muted">{spot.one_liner}</p>
      </div>

      {spot.theme_tags.length > 0 && (
        <ul className="flex flex-wrap gap-2" aria-label="테마 태그">
          {spot.theme_tags.map((tag) => (
            <li key={tag}>
              <Link
                href={`/explore${buildQuery({ theme: tag })}`}
                // inline-flex + min-h: 손가락으로 누르기에 충분한 높이(36px)를 줍니다
                className="inline-flex min-h-9 items-center rounded-pill bg-teal-50 px-3.5 text-sm font-medium text-secondary hover:underline"
              >
                #{tag}
              </Link>
            </li>
          ))}
        </ul>
      )}

      <p className="whitespace-pre-line leading-relaxed">{spot.overview}</p>

      <p className="flex items-start gap-2 text-sm text-muted">
        <MapPin size={18} className="mt-0.5 shrink-0" aria-hidden="true" />
        {spot.address}
      </p>

      {/* 위치가 없는 곳(관리자가 위치 없이 추가)은 지도를 그리지 않습니다. */}
      {spot.lat !== null && spot.lng !== null && (
        <SpotMapView
          spots={[{ id: spot.id, title: spot.title, lat: spot.lat, lng: spot.lng }]}
          className="h-64 w-full rounded-card border border-line"
        />
      )}

      <div className="flex flex-wrap items-center gap-3">
        <FavoriteButton spotId={spot.id} />
        <Link href={`/planner${buildQuery({ q: `${spot.title}을(를) 포함한 일정` })}`} className={btnPrimary}>
          <Sparkles size={18} aria-hidden="true" />
          이 장소로 일정 짜기
        </Link>
      </div>
    </article>
  );
}
