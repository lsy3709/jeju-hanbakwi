// 이 파일이 하는 일: "내 여행 > 찜한 곳" 탭 화면(불러오는 중 · 오류 · 빈 목록 · 카드 목록). 데이터와 동작은 위(useFavorites)에서 받습니다.
import { SpotCard } from "@/components/SpotCard";
import { Empty, ErrorBox, Loading } from "@/components/States";
import type { Spot } from "@/lib/types";

export function FavoriteList({
  spots,
  loading,
  error,
  actionError,
  onRetry,
  onUnfavorite,
}: {
  spots: Spot[] | null;
  loading: boolean;
  error: string | null;
  actionError: string | null;
  onRetry: () => void;
  onUnfavorite: (spotId: number) => void;
}) {
  if (loading) return <Loading />;
  if (error || !spots) return <ErrorBox message={error ?? "알 수 없는 오류"} onRetry={onRetry} />;
  if (spots.length === 0) return <Empty title="아직 찜한 곳이 없어요" hint="마음에 드는 장소의 하트를 눌러 보세요." />;

  return (
    <>
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
              <button type="button" onClick={() => onUnfavorite(spot.id)} className="text-sm font-semibold text-primary hover:underline">
                찜 해제
              </button>
            }
          />
        ))}
      </div>
    </>
  );
}
