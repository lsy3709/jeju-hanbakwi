"use client";

// 이 파일이 하는 일: 관리자 "여행지" 탭의 표(번호 · 이름 · 분류 · 지역 · 실내외 · 출처 · 상태 · 수정/숨김 버튼). 데이터와 동작은 위(useAdminSpots)에서 받습니다.
// 폰 폭: 넓은 표를 가로로 밀게 하면 폰 브라우저가 화면 전체를 넓혀 아래 탭까지 밀려납니다(실측).
// 그래서 폰에서는 덜 중요한 칸을 숨기고(hidden md:table-cell) 그 내용을 첫 칸 아래 한 줄로 보여 줍니다.
import { SpotImage } from "@/components/SpotImage";
import { btnSmall } from "@/components/ui";
import type { AdminSpot } from "@/lib/types";
import { StatusBadge } from "./StatusBadge";

// 서버의 source 값 → 사람이 읽는 이름. 모르는 값이 오면 그대로 보여 줍니다.
const SOURCE_LABELS: Record<string, string> = { sample: "샘플", tourapi: "관광공사", admin: "관리자" };

export function AdminSpotTable({
  spots,
  busyId,
  onEdit,
  onSetHidden,
}: {
  spots: AdminSpot[];
  busyId: number | null;
  onEdit: (spot: AdminSpot) => void;
  onSetHidden: (spot: AdminSpot, hidden: boolean) => void;
}) {
  return (
    <div className="overflow-x-auto rounded-card border border-line bg-surface">
      <table className="w-full text-left text-sm">
        <thead className="border-b border-line text-xs text-muted">
          <tr>
            <th scope="col" className="hidden px-4 py-3 font-semibold md:table-cell">번호</th>
            <th scope="col" className="py-3 pl-4 font-semibold">사진</th>
            <th scope="col" className="px-4 py-3 font-semibold">이름</th>
            <th scope="col" className="hidden px-4 py-3 font-semibold md:table-cell">분류</th>
            <th scope="col" className="hidden px-4 py-3 font-semibold md:table-cell">지역</th>
            <th scope="col" className="hidden px-4 py-3 font-semibold md:table-cell">실내외</th>
            <th scope="col" className="hidden px-4 py-3 font-semibold md:table-cell">출처</th>
            <th scope="col" className="px-4 py-3 font-semibold">상태</th>
            <th scope="col" className="px-4 py-3 font-semibold">
              <span className="sr-only">동작</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {spots.map((spot) => (
            <tr key={spot.id} className="border-b border-line last:border-b-0">
              <td className="hidden px-4 py-3 text-muted md:table-cell">{spot.id}</td>
              {/* 작은 사진: 어느 곳의 사진을 바꿔야 할지 표에서 바로 보입니다. 누르면 수정 폼이 열립니다. */}
              <td className="py-2 pl-4">
                <button type="button" onClick={() => onEdit(spot)} aria-label={`${spot.title} 사진 바꾸기`} className="block overflow-hidden rounded-lg border border-line">
                  <SpotImage imageUrl={spot.image_url} title={spot.title} tags={spot.theme_tags} className="h-10 w-14" />
                </button>
              </td>
              <td className="px-4 py-3 font-medium">
                {spot.title}
                {/* 폰에서만: 숨긴 칸(번호 · 분류 · 지역 · 실내외 · 출처)을 한 줄로 */}
                <span className="mt-0.5 block text-xs font-normal text-muted md:hidden">
                  {spot.id}번 · {spot.category} · {spot.area} · {spot.indoor ? "실내" : "실외"} · {SOURCE_LABELS[spot.source] ?? spot.source}
                </span>
              </td>
              <td className="hidden whitespace-nowrap px-4 py-3 md:table-cell">{spot.category}</td>
              <td className="hidden whitespace-nowrap px-4 py-3 md:table-cell">{spot.area}</td>
              <td className="hidden whitespace-nowrap px-4 py-3 md:table-cell">{spot.indoor ? "실내" : "실외"}</td>
              <td className="hidden whitespace-nowrap px-4 py-3 text-muted md:table-cell">{SOURCE_LABELS[spot.source] ?? spot.source}</td>
              <td className="whitespace-nowrap px-2 py-3 md:px-4">
                <StatusBadge warn={spot.hidden}>{spot.hidden ? "숨김" : "보임"}</StatusBadge>
              </td>
              <td className="py-3 pr-4 md:px-4">
                {/* 폰에서는 버튼 둘을 위아래로 쌓아 폭을 아낍니다 */}
                <div className="flex flex-col items-end gap-1.5 md:flex-row md:justify-end md:gap-2">
                  <button type="button" onClick={() => onEdit(spot)} className={btnSmall}>
                    수정
                  </button>
                  {/* 지우지 않고 숨깁니다. 숨긴 곳은 탐색·상세에 나오지 않고, 언제든 다시 보이게 할 수 있습니다. */}
                  <button
                    type="button"
                    disabled={busyId === spot.id}
                    onClick={() => onSetHidden(spot, !spot.hidden)}
                    className={btnSmall}
                  >
                    {spot.hidden ? "다시 보이기" : "숨김"}
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
