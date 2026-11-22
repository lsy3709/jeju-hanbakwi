// 관광지 카드 한 장. 홈·탐색·내 여행에서 같이 씁니다.
import Link from "next/link";
import type { ReactNode } from "react";
import type { Spot } from "@/lib/types";
import { SpotImage } from "./SpotImage";

export function IndoorBadge({ indoor }: { indoor: boolean }) {
  return (
    <span className="whitespace-nowrap rounded-pill bg-teal-50 px-2.5 py-0.5 text-xs font-semibold text-secondary">
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
        {/* 폰에서는 카드가 두 칸으로 좁아지므로 안쪽 여백을 줄이고, 분류 줄은 글자가 세로로 쪼개지지 않게 통째로 줄을 바꿉니다. */}
        <div className="space-y-1.5 p-3 sm:p-4">
          <div className="flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-muted">
            <span className="whitespace-nowrap">
              {spot.category} <span aria-hidden="true">·</span> {spot.area}
            </span>
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
