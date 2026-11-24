"use client";

// "use client" 는 이 화면이 브라우저에서 도는 컴포넌트라는 표시입니다. 클릭에 반응하고 useState·useEffect 같은 훅을 쓰려면 필요합니다.
// 층: 이 화면(app/) → hooks/ → lib/api.ts. 화면 파일은 fetch 를 직접 부르지 않습니다. page.tsx 는 폴더 이름에 해당하는 주소의 화면입니다.
// 이 파일이 하는 일: 관리자 화면 조립. 로그인 · 관리자 여부를 확인한 뒤 "사용자" / "여행지" / "AI 사용량" 탭을 보여 줍니다.
// 화면에서 막는 것은 안내일 뿐이고, 진짜로 막는 일은 서버가 합니다(관리자가 아니면 /admin 주소가 403).
// 데이터는 hooks/useAdminUsers.ts · useAdminSpots.ts, 표와 폼은 components/admin/ 에 있습니다.
import { useState } from "react";
import { ShieldAlert } from "lucide-react";
import { useAuth } from "@/components/AuthProvider";
import { LoginPanel } from "@/components/LoginPanel";
import { MoreButton } from "@/components/MoreButton";
import { SearchBar } from "@/components/SearchBar";
import { UsageView } from "@/components/UsageView";
import { Empty, ErrorBox, Loading } from "@/components/States";
import { AdminSpotTable } from "@/components/admin/AdminSpotTable";
import { AdminUserTable } from "@/components/admin/AdminUserTable";
import { SpotForm } from "@/components/admin/SpotForm";
import { btnPrimary, chip } from "@/components/ui";
import { useAdminSpots, type HiddenFilter } from "@/hooks/useAdminSpots";
import { useAdminUsers } from "@/hooks/useAdminUsers";
import { useAsync } from "@/hooks/useAsync";
import { getMeta } from "@/lib/api";
import type { AdminSpot } from "@/lib/types";

// 로그인 확인 → /me 확인 → 관리자 여부 순으로 걸러 낸 뒤에만 관리자 화면(AdminContent)을 그립니다.
export default function AdminPage() {
  const { loading, token, me, meLoading, meError, reloadMe } = useAuth();

  if (loading || meLoading) return <Loading />;

  if (!token) {
    return (
      <Notice title="관리자" text="관리자 화면을 보려면 먼저 로그인해 주세요.">
        <LoginPanel next="/admin" />
      </Notice>
    );
  }
  // 로그인은 했는데 /me 를 못 받았으면(서버가 꺼짐 등) 관리자인지 알 수 없으므로 다시 시도를 보여 줍니다.
  if (!me) return <ErrorBox message={meError ?? "내 정보를 불러오지 못했어요."} onRetry={reloadMe} />;
  if (!me.is_admin) return <Notice title="관리자" text="관리자만 볼 수 있는 화면입니다." />;

  return <AdminContent token={token} myId={me.id} />;
}

// 안내 문구 한 덩어리입니다. children 이 있으면(예: 로그인 버튼) 아래에 함께 보입니다.
function Notice({ title, text, children }: { title: string; text: string; children?: React.ReactNode }) {
  return (
    <div className="mx-auto max-w-md space-y-4 py-10 text-center">
      <ShieldAlert size={32} className="mx-auto text-primary" aria-hidden="true" />
      <h1 className="text-2xl font-extrabold">{title}</h1>
      <p className="text-muted">{text}</p>
      {children && <div className="flex justify-center">{children}</div>}
    </div>
  );
}

// 탭(사용자·여행지·AI 사용량)을 고르는 화면입니다. 고른 탭만 그려서, 그 탭의 데이터만 서버에서 불러옵니다.
function AdminContent({ token, myId }: { token: string; myId: string }) {
  const [tab, setTab] = useState<"users" | "spots" | "usage">("users");

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-extrabold">관리자</h1>
      <div className="flex gap-2" role="tablist" aria-label="관리자 보기">
        <button type="button" role="tab" aria-selected={tab === "users"} onClick={() => setTab("users")} className={chip(tab === "users")}>
          사용자
        </button>
        <button type="button" role="tab" aria-selected={tab === "spots"} onClick={() => setTab("spots")} className={chip(tab === "spots")}>
          여행지
        </button>
        <button type="button" role="tab" aria-selected={tab === "usage"} onClick={() => setTab("usage")} className={chip(tab === "usage")}>
          AI 사용량
        </button>
      </div>
      {/* 탭을 열 때만 데이터를 불러오도록 탭마다 작은 함수로 나눴습니다. */}
      {tab === "users" ? (
        <UsersTab token={token} myId={myId} />
      ) : tab === "spots" ? (
        <SpotsTab token={token} />
      ) : (
        <section aria-label="AI 사용량">
          <UsageView scope="admin" token={token} />
        </section>
      )}
    </div>
  );
}

// ---------------------------------------------------------------- 사용자 탭

// 이메일 검색어(q)가 바뀌면 훅이 처음부터 다시 불러옵니다.
function UsersTab({ token, myId }: { token: string; myId: string }) {
  const [q, setQ] = useState("");
  const users = useAdminUsers(token, q);
  const list = users.list;

  return (
    <section className="space-y-4" aria-label="사용자">
      <SearchBar initial={q} onSearch={setQ} placeholder="이메일 일부로 찾기" label="사용자 이메일 검색" />
      {list === null ? (
        <Loading />
      ) : list.error && list.items.length === 0 ? (
        <ErrorBox message={list.error} onRetry={users.reload} />
      ) : list.items.length === 0 ? (
        <Empty title="조건에 맞는 사용자가 없어요" hint={q ? "검색어를 바꿔 보세요." : undefined} />
      ) : (
        <>
          {users.actionError && (
            <p role="alert" className="text-sm text-primary">
              {users.actionError}
            </p>
          )}
          <AdminUserTable users={list.items} myId={myId} busyId={users.busyId} onSuspend={users.setSuspended} />
          {list.error && <ErrorBox message={list.error} />}
          <MoreButton hasMore={users.hasMore} busy={users.moreBusy} onMore={users.loadMore} />
        </>
      )}
    </section>
  );
}

// ---------------------------------------------------------------- 여행지 탭

// "보기" 단추에 보일 선택지입니다. value 는 서버 쿼리(hidden)와 같은 뜻입니다.
const HIDDEN_OPTIONS: { label: string; value: HiddenFilter }[] = [
  { label: "전체", value: "" },
  { label: "보이는 곳", value: "false" },
  { label: "숨긴 곳", value: "true" },
];

// 여행지 탭입니다. editing 값으로 폼을 열고 닫습니다: null = 닫힘, "new" = 추가, 여행지 = 그 여행지 수정.
function SpotsTab({ token }: { token: string }) {
  const [q, setQ] = useState("");
  const [hidden, setHidden] = useState<HiddenFilter>("");
  // 폼: null = 닫힘, "new" = 추가, AdminSpot = 그 여행지 수정
  const [editing, setEditing] = useState<AdminSpot | "new" | null>(null);
  const spots = useAdminSpots(token, q, hidden);
  const meta = useAsync(getMeta); // 분류·지역·테마 선택지
  const list = spots.list;

  return (
    <section className="space-y-4" aria-label="여행지">
      <SearchBar initial={q} onSearch={setQ} placeholder="여행지 이름으로 찾기" label="여행지 이름 검색" />

      <div className="flex flex-wrap items-center gap-2">
        <div className="flex gap-2" role="group" aria-label="보기">
          {HIDDEN_OPTIONS.map((option) => (
            <button
              key={option.label}
              type="button"
              aria-pressed={hidden === option.value}
              onClick={() => setHidden(option.value)}
              className={chip(hidden === option.value)}
            >
              {option.label}
            </button>
          ))}
        </div>
        {/* 선택지(/meta)를 받아야 폼을 그릴 수 있어서, 받기 전에는 누를 수 없게 합니다. */}
        <button type="button" disabled={!meta.data} onClick={() => setEditing("new")} className={`${btnPrimary} ml-auto`}>
          여행지 추가
        </button>
      </div>
      {meta.error && <ErrorBox message={`선택지를 불러오지 못해 추가·수정을 할 수 없어요. (${meta.error})`} onRetry={meta.reload} />}

      {list === null ? (
        <Loading />
      ) : list.error && list.items.length === 0 ? (
        <ErrorBox message={list.error} onRetry={spots.reload} />
      ) : list.items.length === 0 ? (
        <Empty title="조건에 맞는 여행지가 없어요" hint="검색어나 보기 필터를 바꿔 보세요." />
      ) : (
        <>
          {/* total 은 첫 묶음에서만 오므로 useCursorList 가 기억해 둔 값입니다 */}
          {list.total !== null && <p className="text-sm text-muted">전체 {list.total}곳 · {list.items.length}곳을 보여 드려요</p>}
          {spots.actionError && (
            <p role="alert" className="text-sm text-primary">
              {spots.actionError}
            </p>
          )}
          <AdminSpotTable
            spots={list.items}
            busyId={spots.busyId}
            onEdit={(spot) => setEditing(spot)}
            onSetHidden={spots.setHidden}
          />
          {list.error && <ErrorBox message={list.error} />}
          <MoreButton hasMore={spots.hasMore} busy={spots.moreBusy} onMore={spots.loadMore} />
        </>
      )}

      {editing !== null && meta.data && (
        <SpotForm
          // key: 다른 여행지를 열면 폼의 입력값을 새로 채웁니다.
          key={editing === "new" ? "new" : editing.id}
          meta={meta.data}
          spot={editing === "new" ? null : editing}
          onSubmit={(values) => spots.saveSpot(editing === "new" ? null : editing, values)}
          onClose={() => setEditing(null)}
        />
      )}
    </section>
  );
}
