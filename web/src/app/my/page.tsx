"use client";

// 이 파일이 하는 일: 내 여행 화면 조립. 로그인 전엔 안내 + 로그인 버튼, 로그인 후엔 "찜한 곳" / "저장한 일정" 탭.
// 데이터는 hooks/useFavorites.ts · useTrips.ts, 목록 화면은 components/FavoriteList.tsx · TripList.tsx 에 있습니다.
import { useState } from "react";
import { Ban, LogOut } from "lucide-react";
import { useAuth } from "@/components/AuthProvider";
import { FavoriteList } from "@/components/FavoriteList";
import { LoginPanel } from "@/components/LoginPanel";
import { Loading } from "@/components/States";
import { TripList } from "@/components/TripList";
import { btnOutline, chip } from "@/components/ui";
import { useFavorites } from "@/hooks/useFavorites";
import { useTrips } from "@/hooks/useTrips";

export default function MyPage() {
  const { loading, token, email, me, meLoading, signOut } = useAuth();

  // /me 까지 받은 뒤에 그립니다. 정지된 계정인지 모른 채 탭을 열면 찜·일정 주소가 403 을 주어 오류 상자가 먼저 떴다 사라집니다.
  if (loading || meLoading) return <Loading />;

  if (!token) {
    return (
      <div className="mx-auto max-w-md space-y-4 py-10 text-center">
        <h1 className="text-2xl font-extrabold">내 여행</h1>
        <p className="text-muted">로그인하면 마음에 든 장소를 찜하고, AI가 짠 일정을 저장해 둘 수 있어요.</p>
        <div className="flex justify-center">
          <LoginPanel />
        </div>
      </div>
    );
  }

  // /me 를 못 받았으면(서버가 꺼짐 등) me 는 null 입니다. 그때는 정지가 아닌 것으로 보고 탭을 그대로 보여 줍니다
  // (탭이 각자 오류 상자와 "다시 시도"를 보여 줍니다).
  return <MyContent token={token} email={email} suspended={me?.suspended ?? false} onSignOut={signOut} />;
}

function MyContent({
  token,
  email,
  suspended,
  onSignOut,
}: {
  token: string;
  email: string | null;
  suspended: boolean;
  onSignOut: () => void;
}) {
  const [tab, setTab] = useState<"favorites" | "trips">("favorites");

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="min-w-0">
          <h1 className="text-2xl font-extrabold">내 여행</h1>
          {email && <p className="break-all text-sm text-muted">{email}</p>}
        </div>
        <button type="button" onClick={onSignOut} className={btnOutline}>
          <LogOut size={16} aria-hidden="true" />
          로그아웃
        </button>
      </div>

      {/* 정지된 계정은 찜·일정 주소가 모두 403 이라, 탭을 열지 않고(= 요청을 보내지 않고) 안내 한 줄만 보여 줍니다. */}
      {suspended ? <SuspendedNotice /> : <MyTabs token={token} tab={tab} onTab={setTab} />}
    </div>
  );
}

function SuspendedNotice() {
  return (
    <p role="alert" className="flex items-start gap-2 rounded-card border border-line bg-surface p-4 text-sm">
      <Ban size={18} className="mt-0.5 shrink-0 text-primary" aria-hidden="true" />
      이용이 정지된 계정입니다. 관리자에게 문의해 주세요.
    </p>
  );
}

function MyTabs({
  token,
  tab,
  onTab: setTab,
}: {
  token: string;
  tab: "favorites" | "trips";
  onTab: (tab: "favorites" | "trips") => void;
}) {
  return (
    <>
      <div className="flex gap-2" role="tablist" aria-label="내 여행 보기">
        <button type="button" role="tab" aria-selected={tab === "favorites"} onClick={() => setTab("favorites")} className={chip(tab === "favorites")}>
          찜한 곳
        </button>
        <button type="button" role="tab" aria-selected={tab === "trips"} onClick={() => setTab("trips")} className={chip(tab === "trips")}>
          저장한 일정
        </button>
      </div>

      {tab === "favorites" ? <FavoritesTab token={token} /> : <TripsTab token={token} />}
    </>
  );
}

// 탭을 열 때만 데이터를 불러오도록 탭마다 작은 함수로 나눴습니다. (훅 이름이 곧 props 이름이라 그대로 넘깁니다)
function FavoritesTab({ token }: { token: string }) {
  const favorites = useFavorites(token);
  return <FavoriteList {...favorites} />;
}

function TripsTab({ token }: { token: string }) {
  const trips = useTrips(token);
  return <TripList {...trips} />;
}
