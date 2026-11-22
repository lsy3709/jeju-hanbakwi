// 이 파일이 하는 일: "내 여행 > 찜한 곳" 탭 화면(불러오는 중 · 오류 · 빈 목록 · 카드 목록 · 더 보기). 데이터와 동작은 위(useFavorites)에서 받습니다.
import { MoreButton } from "@/components/MoreButton";
import { SpotCard } from "@/components/SpotCard";
import { Empty, ErrorBox, Loading } from "@/components/States";
import type { Spot } from "@/lib/types";

export function FavoriteList({
  spots,
  loading,
  error,
  actionError,
  hasMore,
  moreBusy,
  onMore,
  onRetry,
  onUnfavorite,
}: {
  spots: Spot[] | null;
  loading: boolean;
  error: string | null;
  actionError: string | null;
  hasMore: boolean;
  moreBusy: boolean;
  onMore: () => void;
  onRetry: () => void;
  onUnfavorite: (spotId: number) => void;
}) {
  if (loading || !spots) return <Loading />;
  // 받은 것이 하나도 없는데 오류가 있으면 첫 묶음부터 실패한 것 → 큰 오류 상자 + 다시 시도
  if (error && spots.length === 0 && !hasMore) return <ErrorBox message={error} onRetry={onRetry} />;
  // 남은 묶음이 있으면 "비었다"고 하지 않습니다(받아 둔 것을 모두 찜 해제한 경우).
  if (spots.length === 0 && !hasMore) return <Empty title="아직 찜한 곳이 없어요" hint="마음에 드는 장소의 하트를 눌러 보세요." />;

  return (
    <div className="space-y-4">
      {actionError && (
        <p role="alert" className="text-sm text-primary">
          {actionError}
        </p>
      )}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {spots.map((spot) => (
          <SpotCard
            key={spot.id}
            spot={spot}
            footer={
              <button type="button" onClick={() => onUnfavorite(spot.id)} className="-my-1.5 inline-flex min-h-9 items-center text-sm font-semibold text-primary hover:underline">
                찜 해제
              </button>
            }
          />
        ))}
      </div>
      {/* "더 보기"가 실패한 경우: 받아 둔 카드는 두고 문구만 보여 줍니다. 버튼을 다시 누르면 다시 시도합니다. */}
      {error && <ErrorBox message={error} />}
      <MoreButton hasMore={hasMore} busy={moreBusy} onMore={onMore} />
    </div>
  );
}
