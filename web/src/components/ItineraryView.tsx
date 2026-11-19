// 일자별 일정 타임라인. AI 플래너 결과와 "내 여행"의 저장한 일정에서 같이 씁니다.
import Link from "next/link";
import { CloudSun } from "lucide-react";
import { dayTitle } from "@/lib/format";
import type { Itinerary } from "@/lib/types";

export function ItineraryView({ itinerary }: { itinerary: Itinerary }) {
  return (
    <div className="space-y-4">
      {itinerary.map((day) => (
        <section key={day.day} className="rounded-card border border-line bg-surface p-5">
          <header className="mb-4 flex flex-wrap items-center gap-2">
            <h3 className="text-lg font-bold">{dayTitle(day.day, day.date)}</h3>
            {day.weather && (
              <span className="inline-flex items-center gap-1 rounded-pill bg-teal-50 px-2.5 py-0.5 text-xs font-semibold text-secondary">
                <CloudSun size={14} aria-hidden="true" />
                {day.weather}
              </span>
            )}
          </header>
          <ol className="space-y-4 border-l-2 border-line pl-5">
            {day.items.map((item, index) => (
              <li key={`${item.spot_id}-${index}`} className="relative">
                {/* 타임라인 점 */}
                <span className="absolute -left-[27px] top-1.5 h-3 w-3 rounded-full bg-primary" aria-hidden="true" />
                <p className="text-xs font-semibold text-primary">{item.time}</p>
                <Link href={`/spots/${item.spot_id}`} className="font-bold hover:text-secondary hover:underline">
                  {item.title}
                </Link>
                <p className="text-sm text-muted">{item.reason}</p>
              </li>
            ))}
          </ol>
        </section>
      ))}
    </div>
  );
}
