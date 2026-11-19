// 관광지 카드 한 장. 홈·탐색·내 여행에서 같이 씁니다.
import Link from "next/link";
import type { ReactNode } from "react";
import type { Spot } from "@/lib/types";
import { SpotImage } from "./SpotImage";

export function IndoorBadge({ indoor }: { indoor: boolean }) {
  return (
    <span className="rounded-pill bg-teal-50 px-2.5 py-0.5 text-xs font-semibold text-secondary">
      {indoor ? "실내" : "실외"}
    </span>
  );
}

type Props = {
  spot: Spot;
  className?: string;
  /** 카드 아래에 붙일 버튼 등(예: 찜 해제) */
  footer?: ReactNode;
};

export function SpotCard({ spot, className = "", footer }: Props) {
  return (
    <article className={`overflow-hidden rounded-card border border-line bg-surface ${className}`}>
      <Link href={`/spots/${spot.id}`} className="block">
        <SpotImage imageUrl={spot.image_url} title={spot.title} tags={spot.theme_tags} className="aspect-4/3 w-full" />
        <div className="space-y-1.5 p-4">
          <div className="flex items-center gap-2 text-xs text-muted">
            <span>{spot.category}</span>
            <span aria-hidden="true">·</span>
            <span>{spot.area}</span>
            <span className="ml-auto">
              <IndoorBadge indoor={spot.indoor} />
            </span>
          </div>
          <h3 className="font-bold">{spot.title}</h3>
          <p className="line-clamp-2 text-sm text-muted">{spot.one_liner}</p>
        </div>
      </Link>
      {footer && <div className="border-t border-line p-3">{footer}</div>}
    </article>
  );
}
