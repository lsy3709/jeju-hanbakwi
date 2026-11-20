"use client";

// 이 파일이 하는 일: 내 여행 화면 조립. 로그인 전엔 안내 + 로그인 버튼, 로그인 후엔 찜한 곳.
// 데이터는 hooks/useFavorites.ts, 목록 화면은 components/FavoriteList.tsx 에 있습니다.
import { LogOut } from "lucide-react";
import { useAuth } from "@/components/AuthProvider";
import { FavoriteList } from "@/components/FavoriteList";
import { LoginPanel } from "@/components/LoginPanel";
import { Loading } from "@/components/States";
import { btnOutline } from "@/components/ui";
import { useFavorites } from "@/hooks/useFavorites";

export default function MyPage() {
  const { loading, token, email, signOut } = useAuth();

  if (loading) return <Loading />;

  if (!token) {
    return (
      <div className="mx-auto max-w-md space-y-4 py-10 text-center">
        <h1 className="text-2xl font-extrabold">내 여행</h1>
        <p className="text-muted">로그인하면 마음에 든 장소를 찜해 둘 수 있어요.</p>
        <div className="flex justify-center">
          <LoginPanel />
        </div>
      </div>
    );
  }

  return <MyContent token={token} email={email} onSignOut={signOut} />;
}

function MyContent({ token, email, onSignOut }: { token: string; email: string | null; onSignOut: () => void }) {
  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-extrabold">내 여행</h1>
          {email && <p className="text-sm text-muted">{email}</p>}
        </div>
        <button type="button" onClick={onSignOut} className={btnOutline}>
          <LogOut size={16} aria-hidden="true" />
          로그아웃
        </button>
      </div>

      <FavoritesTab token={token} />
    </div>
  );
}

// 훅 이름이 곧 props 이름이라 그대로 넘깁니다.
function FavoritesTab({ token }: { token: string }) {
  const favorites = useFavorites(token);
  return <FavoriteList {...favorites} />;
}
