// 이 파일이 하는 일: 커서 목록 아래의 "더 보기" 버튼. 탐색 · 내 여행 · 관리자 화면이 같은 모양을 씁니다.
// 다음 묶음이 없으면(next_cursor 가 null) 아무것도 그리지 않습니다.
import { btnOutline } from "./ui";

export function MoreButton({ hasMore, busy, onMore }: { hasMore: boolean; busy: boolean; onMore: () => void }) {
  if (!hasMore) return null;
  return (
    <div className="flex justify-center">
      <button type="button" onClick={onMore} disabled={busy} className={btnOutline}>
        {busy ? "불러오는 중..." : "더 보기"}
      </button>
    </div>
  );
}
