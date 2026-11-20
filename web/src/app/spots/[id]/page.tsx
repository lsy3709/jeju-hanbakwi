"use client";

// 상세: 큰 사진 → 분류·지역 → 제목 → 한 줄 소개 → 태그 → 실내/실외 → 소개 글 → 주소
import Link from "next/link";
import { useParams } from "next/navigation";
import { MapPin } from "lucide-react";
import { SpotImage } from "@/components/SpotImage";
import { IndoorBadge } from "@/components/SpotCard";
import { Empty } from "@/components/States";
import { buildQuery } from "@/lib/format";
import { getSpot } from "@/lib/spots";

export default function SpotDetailPage() {
  const params = useParams<{ id: string }>();
  // 임시 데이터에서 찾습니다. (3일차에 서버에 물어보는 것으로 바뀝니다)
  const spot = getSpot(params.id);

  if (!spot) {
    return <Empty title="이 장소를 찾을 수 없어요" hint="주소가 틀렸거나 사라진 장소일 수 있어요." />;
  }

  return (
    <article className="mx-auto max-w-3xl space-y-5">
      <SpotImage imageUrl={spot.image_url} title={spot.title} tags={spot.theme_tags} className="aspect-16/9 w-full rounded-card" />

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
                className="rounded-pill bg-teal-50 px-3 py-1 text-sm font-medium text-secondary hover:underline"
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
    </article>
  );
}
