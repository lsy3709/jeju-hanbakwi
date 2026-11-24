"use client";

// "use client" 는 이 파일이 브라우저에서 도는 컴포넌트라는 표시입니다. 클릭에 반응하거나 useState 로 값을 기억하려면 필요합니다.
// 이 파일이 하는 일: 상세 화면의 "찜하기" 하트 버튼. 로그인 전에 누르면 로그인 안내창을 띄웁니다.
// 보여 주기만 하는 컴포넌트가 아니라 "찜 추가·삭제 기능이 본질"인 예외라서 서버 함수(api.ts)를 직접 부릅니다.
import { useCallback, useState } from "react";
import { Heart } from "lucide-react";
import { addFavorite, errorMessage, isFavorite, removeFavorite } from "@/lib/api";
import { useAsync } from "@/hooks/useAsync";
import { useAuth } from "./AuthProvider";
import { LoginDialog } from "./LoginPanel";
import { btnOutline } from "./ui";

// 받는 값: spotId(찜할 여행지 번호). 누르면 찜을 더하거나 뺍니다.
export function FavoriteButton({ spotId }: { spotId: number }) {
  // 로그인하지 않았으면 token 이 null 이라, 누르는 순간 로그인 안내창을 띄웁니다.
  const { token } = useAuth();
  const [showLogin, setShowLogin] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // 서버에서 받은 찜 목록과, 이 화면에서 방금 바꾼 값(override)을 합쳐 현재 상태를 만듭니다.
  const [override, setOverride] = useState<boolean | null>(null);

  // 찜 목록은 커서로 나눠 오므로, 첫 묶음만 보면 뒤쪽에 있는 찜을 놓칩니다. 그래서 이 한 곳만 서버에 따로 묻습니다.
  // (불러오지 못하면 data 가 null → "찜하기"로 보입니다. 정지된 계정이면 서버가 403 을 줍니다)
  // 토큰이 있을 때만 서버에 묻고, 없으면 "찜 아님(false)"이라는 즉시 완료된 약속(Promise)을 돌려줍니다.
  const load = useCallback(() => (token ? isFavorite(token, spotId) : Promise.resolve(false)), [token, spotId]);
  const { data } = useAsync(load);
  const serverFavorite = data === true;
  const favorite = override ?? serverFavorite;

  // 서버에 찜 추가/삭제를 요청하고 성공하면 화면 값(override)을 바꿉니다. busy 동안 버튼을 막아 두 번 눌리는 것을 방지합니다.
  async function toggle() {
    if (!token) {
      setShowLogin(true);
      return;
    }
    setBusy(true);
    setError(null);
    try {
      if (favorite) await removeFavorite(token, spotId);
      else await addFavorite(token, spotId);
      setOverride(!favorite);
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  }

  // 버튼 아래에 오류 문구와 로그인 안내창(필요할 때만)을 함께 그립니다.
  return (
    <>
      <button type="button" onClick={toggle} disabled={busy} aria-pressed={favorite} className={btnOutline}>
        <Heart size={18} aria-hidden="true" className={favorite ? "fill-primary text-primary" : ""} />
        {favorite ? "찜한 곳" : "찜하기"}
      </button>
      {error && (
        <p role="alert" className="text-sm text-primary">
          {error}
        </p>
      )}
      {showLogin && <LoginDialog message="찜하려면 로그인이 필요해요." onClose={() => setShowLogin(false)} />}
    </>
  );
}
