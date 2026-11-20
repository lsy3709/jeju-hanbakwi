"use client";

// 이 파일이 하는 일: "내 여행 > 저장한 일정" 탭 화면(목록 · 펼쳐 보기 · 삭제 버튼). 데이터와 삭제 동작은 위(useTrips)에서 받습니다.
// 어느 일정을 펼쳤는지(openId)는 화면에서만 쓰는 값이라 여기서 들고 있습니다.
import { useState } from "react";
import { ChevronDown, ChevronUp, Trash2 } from "lucide-react";
import { ItineraryView } from "@/components/ItineraryView";
import { Empty, ErrorBox, Loading } from "@/components/States";
import { btnOutline } from "@/components/ui";
import { formatSavedAt } from "@/lib/format";
import type { Trip } from "@/lib/types";

export function TripList({
  trips,
  loading,
  error,
  actionError,
  onRetry,
  onRemove,
}: {
  trips: Trip[] | null;
  loading: boolean;
  error: string | null;
  actionError: string | null;
  onRetry: () => void;
  onRemove: (id: number) => void;
}) {
  const [openId, setOpenId] = useState<number | null>(null); // 펼쳐 둔 일정

  if (loading) return <Loading />;
  if (error || !trips) return <ErrorBox message={error ?? "알 수 없는 오류"} onRetry={onRetry} />;
  if (trips.length === 0) return <Empty title="저장한 일정이 없어요" hint="AI 플래너에서 일정을 짠 뒤 저장해 보세요." />;

  return (
    <ul className="space-y-3">
      {actionError && (
        <li role="alert" className="text-sm text-primary">
          {actionError}
        </li>
      )}
      {trips.map((trip) => {
        const open = openId === trip.id;
        return (
          <li key={trip.id} className="rounded-card border border-line bg-surface p-4">
            <div className="flex items-center justify-between gap-3">
              <div>
                <h2 className="font-bold">{trip.title}</h2>
                <p className="text-xs text-muted">{formatSavedAt(trip.created_at)} 저장</p>
              </div>
              <div className="flex items-center gap-2">
                <button type="button" aria-expanded={open} onClick={() => setOpenId(open ? null : trip.id)} className={btnOutline}>
                  {open ? <ChevronUp size={16} aria-hidden="true" /> : <ChevronDown size={16} aria-hidden="true" />}
                  {open ? "접기" : "펼쳐 보기"}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    if (window.confirm(`"${trip.title}" 일정을 삭제할까요?`)) onRemove(trip.id);
                  }}
                  aria-label={`${trip.title} 삭제`}
                  className="rounded-pill p-2 text-muted hover:bg-sand hover:text-primary"
                >
                  <Trash2 size={18} aria-hidden="true" />
                </button>
              </div>
            </div>
            {open && (
              <div className="mt-4">
                <ItineraryView itinerary={trip.itinerary} />
              </div>
            )}
          </li>
        );
      })}
    </ul>
  );
}
