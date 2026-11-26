"use client";

// 상세 화면의 "근처 추천 식당". 이 장소에서 직선 거리로 가까운 식당을 몇 곳 보여 줍니다.
// 식당 데이터가 없거나(빈 목록) 옛 서버라 주소가 없으면(오류) 아무것도 그리지 않습니다 — 상세의 다른 부분은 그대로 보여야 하니까요.
import Link from "next/link";
import { useCallback } from "react";
import { Utensils } from "lucide-react";
import { SpotImage } from "@/components/SpotImage";
import { getNearbyRestaurants } from "@/lib/api";
import { distanceText } from "@/lib/format";
import { useAsync } from "@/hooks/useAsync";

export function NearbyRestaurants({ spotId }: { spotId: number }) {
  const load = useCallback(() => getNearbyRestaurants(spotId, 4), [spotId]);
  const { data } = useAsync(load);
  if (!data || data.length === 0) return null;

  return (
    <section aria-labelledby="nearby-food" className="space-y-3">
      <h2 id="nearby-food" className="flex items-center gap-2 text-xl font-bold">
        <Utensils size={20} aria-hidden="true" />
        근처 추천 식당
      </h2>
      <ul className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {data.map((food) => (
          <li key={food.id}>
            <Link href={`/spots/${food.id}`} className="block overflow-hidden rounded-card border border-line bg-surface">
              <SpotImage imageUrl={food.image_url} title={food.title} tags={food.theme_tags} className="aspect-4/3 w-full" />
              <div className="space-y-1 p-3">
                <p className="text-xs text-muted">
                  {food.category} <span aria-hidden="true">·</span> {distanceText(food.distance_km)}
                </p>
                <p className="line-clamp-2 text-sm font-bold">{food.title}</p>
              </div>
            </Link>
          </li>
        ))}
      </ul>
      <p className="text-xs text-muted">직선 거리가 가까운 순서입니다. 사진은 분류를 대표하는 예시 사진입니다.</p>
    </section>
  );
}
