"use client";

// 내 여행: 로그인 전엔 안내 + 로그인 버튼, 로그인 후엔 "찜한 곳" / "저장한 일정" 탭
import { useCallback, useState } from "react";
import { ChevronDown, ChevronUp, LogOut, Trash2 } from "lucide-react";
import { useAuth } from "@/components/AuthProvider";
import { ItineraryView } from "@/components/ItineraryView";
import { LoginPanel } from "@/components/LoginPanel";
import { SpotCard } from "@/components/SpotCard";
import { Empty, ErrorBox, Loading } from "@/components/States";
import { btnOutline, chip } from "@/components/ui";
import { deleteTrip, errorMessage, getFavorites, getTrips, removeFavorite } from "@/lib/api";
import { formatSavedAt } from "@/lib/format";
import { useAsync } from "@/lib/useAsync";

export default function MyPage() {
  const { loading, token, email, signOut } = useAuth();

  if (loading) return <Loading />;

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

  return <MyContent token={token} email={email} onSignOut={signOut} />;
}

function MyContent({ token, email, onSignOut }: { token: string; email: string | null; onSignOut: () => void }) {
  const [tab, setTab] = useState<"favorites" | "trips">("favorites");

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

      <div className="flex gap-2" role="tablist" aria-label="내 여행 보기">
        <button type="button" role="tab" aria-selected={tab === "favorites"} onClick={() => setTab("favorites")} className={chip(tab === "favorites")}>
          찜한 곳
        </button>
        <button type="button" role="tab" aria-selected={tab === "trips"} onClick={() => setTab("trips")} className={chip(tab === "trips")}>
          저장한 일정
        </button>
      </div>

      {tab === "favorites" ? <Favorites token={token} /> : <Trips token={token} />}
    </div>
  );
}

function Favorites({ token }: { token: string }) {
  const load = useCallback(() => getFavorites(token), [token]);
  const { data, loading, error, reload } = useAsync(load);
  const [removed, setRemoved] = useState<number[]>([]); // 방금 찜 해제한 장소 id (화면에서 바로 숨김)
  const [actionError, setActionError] = useState<string | null>(null);

  async function unfavorite(spotId: number) {
    setActionError(null);
    try {
      await removeFavorite(token, spotId);
      setRemoved((ids) => [...ids, spotId]);
    } catch (e) {
      setActionError(errorMessage(e));
    }
  }

  if (loading) return <Loading />;
  if (error || !data) return <ErrorBox message={error ?? "알 수 없는 오류"} onRetry={reload} />;

  const spots = data.filter((spot) => !removed.includes(spot.id));
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
              <button type="button" onClick={() => unfavorite(spot.id)} className="text-sm font-semibold text-primary hover:underline">
                찜 해제
              </button>
            }
          />
        ))}
      </div>
    </>
  );
}

function Trips({ token }: { token: string }) {
  const load = useCallback(() => getTrips(token), [token]);
  const { data, loading, error, reload } = useAsync(load);
  const [removed, setRemoved] = useState<number[]>([]);
  const [openId, setOpenId] = useState<number | null>(null); // 펼쳐 둔 일정
  const [actionError, setActionError] = useState<string | null>(null);

  async function remove(id: number, title: string) {
    if (!window.confirm(`"${title}" 일정을 삭제할까요?`)) return;
    setActionError(null);
    try {
      await deleteTrip(token, id);
      setRemoved((ids) => [...ids, id]);
    } catch (e) {
      setActionError(errorMessage(e));
    }
  }

  if (loading) return <Loading />;
  if (error || !data) return <ErrorBox message={error ?? "알 수 없는 오류"} onRetry={reload} />;

  const trips = data.filter((trip) => !removed.includes(trip.id));
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
                <button
                  type="button"
                  aria-expanded={open}
                  onClick={() => setOpenId(open ? null : trip.id)}
                  className={btnOutline}
                >
                  {open ? <ChevronUp size={16} aria-hidden="true" /> : <ChevronDown size={16} aria-hidden="true" />}
                  {open ? "접기" : "펼쳐 보기"}
                </button>
                <button
                  type="button"
                  onClick={() => remove(trip.id, trip.title)}
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
