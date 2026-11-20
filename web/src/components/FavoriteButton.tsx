"use client";

// 이 파일이 하는 일: 상세 화면의 "찜하기" 하트 버튼. 로그인 전에 누르면 로그인 안내창을 띄웁니다.
// 보여 주기만 하는 컴포넌트가 아니라 "찜 추가·삭제 기능이 본질"인 예외라서 서버 함수(api.ts)를 직접 부릅니다.
import { useCallback, useState } from "react";
import { Heart } from "lucide-react";
import { addFavorite, errorMessage, getFavorites, removeFavorite } from "@/lib/api";
import { useAsync } from "@/hooks/useAsync";
import { useAuth } from "./AuthProvider";
import { LoginDialog } from "./LoginPanel";
import { btnOutline } from "./ui";

export function FavoriteButton({ spotId }: { spotId: number }) {
  const { token } = useAuth();
  const [showLogin, setShowLogin] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // 서버에서 받은 찜 목록과, 이 화면에서 방금 바꾼 값(override)을 합쳐 현재 상태를 만듭니다.
  const [override, setOverride] = useState<boolean | null>(null);

  const load = useCallback(() => (token ? getFavorites(token) : Promise.resolve([])), [token]);
  const { data } = useAsync(load);
  const serverFavorite = Boolean(data?.some((spot) => spot.id === spotId));
  const favorite = override ?? serverFavorite;

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
