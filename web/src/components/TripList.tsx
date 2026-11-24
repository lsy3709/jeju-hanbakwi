"use client";

// "use client" 는 이 파일이 브라우저에서 도는 컴포넌트라는 표시입니다. 클릭에 반응하거나 useState 로 값을 기억하려면 필요합니다.
// 이 파일이 하는 일: "내 여행 > 저장한 일정" 탭 화면(목록 · 펼쳐 보기 · 삭제 버튼). 데이터와 삭제 동작은 위(useTrips)에서 받습니다.
// 어느 일정을 펼쳤는지(openId)는 화면에서만 쓰는 값이라 여기서 들고 있습니다.
import { useState } from "react";
import { ChevronDown, ChevronUp, Trash2 } from "lucide-react";
import { ItineraryView } from "@/components/ItineraryView";
import { MoreButton } from "@/components/MoreButton";
import { Empty, ErrorBox, Loading } from "@/components/States";
import { btnOutline } from "@/components/ui";
import { formatSavedAt } from "@/lib/format";
import type { Trip } from "@/lib/types";

// 중괄호 안의 이름들(props)은 부르는 쪽이 넘겨 주는 값입니다. 목록·오류·동작은 모두 useTrips 훅이 만들어 넘기고, 이 컴포넌트는 그립니다.
export function TripList({
  trips,
  loading,
  error,
  actionError,
  hasMore,
  moreBusy,
  onMore,
  onRetry,
  onRemove,
}: {
  trips: Trip[] | null;
  loading: boolean;
  error: string | null;
  actionError: string | null;
  hasMore: boolean;
  moreBusy: boolean;
  onMore: () => void;
  onRetry: () => void;
  onRemove: (id: number) => void;
}) {
  const [openId, setOpenId] = useState<number | null>(null); // 펼쳐 둔 일정

  // 불러오는 중 → 첫 불러오기 오류 → 빈 목록 → 일정 목록 순서로 상태를 확인합니다.
  if (loading || !trips) return <Loading />;
  // 받은 것이 하나도 없는데 오류가 있으면 첫 묶음부터 실패한 것 → 큰 오류 상자 + 다시 시도
  if (error && trips.length === 0 && !hasMore) return <ErrorBox message={error} onRetry={onRetry} />;
  // 남은 묶음이 있으면 "비었다"고 하지 않습니다(받아 둔 것을 모두 지운 경우).
  if (trips.length === 0 && !hasMore) return <Empty title="저장한 일정이 없어요" hint="AI 플래너에서 일정을 짠 뒤 저장해 보세요." />;

  return (
    <div className="space-y-4">
      {actionError && (
        <p role="alert" className="text-sm text-primary">
          {actionError}
        </p>
      )}
      <ul className="space-y-3">
        {trips.map((trip) => {
          const open = openId === trip.id;
          return (
            <li key={trip.id} className="rounded-card border border-line bg-surface p-4">
              <div className="flex items-center justify-between gap-3">
                <div className="min-w-0">
                  <h2 className="break-words font-bold">{trip.title}</h2>
                  <p className="text-xs text-muted">{formatSavedAt(trip.created_at)} 저장</p>
                </div>
                <div className="flex shrink-0 items-center gap-2">
                  <button type="button" aria-expanded={open} onClick={() => setOpenId(open ? null : trip.id)} className={btnOutline}>
                    {open ? <ChevronUp size={16} aria-hidden="true" /> : <ChevronDown size={16} aria-hidden="true" />}
                    {open ? "접기" : "펼쳐 보기"}
                  </button>
                  <button
                    type="button"
                    // 실수로 지우지 않게 확인창(window.confirm)에서 "확인"을 눌러야 삭제를 요청합니다.
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
      {/* "더 보기"가 실패한 경우: 받아 둔 일정은 두고 문구만 보여 줍니다. 버튼을 다시 누르면 다시 시도합니다. */}
      {error && <ErrorBox message={error} />}
      <MoreButton hasMore={hasMore} busy={moreBusy} onMore={onMore} />
    </div>
  );
}
