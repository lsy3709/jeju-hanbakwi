"use client";

// "use client" 는 이 파일이 브라우저에서 도는 컴포넌트라는 표시입니다. 클릭에 반응하거나 useState 로 값을 기억하려면 필요합니다.
// 이 파일이 하는 일: 관리자 "사용자" 탭의 표(이메일 · 가입일 · 찜 수 · 일정 수 · 상태 · 정지 버튼). 데이터와 동작은 위(useAdminUsers)에서 받습니다.
// 폰 폭: 넓은 표를 가로로 밀게 하면 폰 브라우저가 화면 전체를 넓혀 아래 탭까지 밀려납니다(실측).
// 그래서 폰에서는 덜 중요한 칸을 숨기고(hidden md:table-cell) 그 내용을 첫 칸 아래 한 줄로 보여 줍니다.
import { btnSmall } from "@/components/ui";
import { formatSavedAt } from "@/lib/format";
import type { AdminUser } from "@/lib/types";
import { StatusBadge } from "./StatusBadge";

// 컴포넌트 = 화면 조각을 그려 돌려주는 함수입니다. 중괄호 안의 이름들(props)은 부르는 쪽이 넘겨 주는 값입니다.
// 받는 값: users(표에 그릴 줄), myId(로그인한 관리자 자신의 id), busyId(요청 중인 줄), onSuspend(정지/해제 단추를 누르면 부를 함수).
export function AdminUserTable({
  users,
  myId,
  busyId,
  onSuspend,
}: {
  users: AdminUser[];
  myId: string;
  busyId: string | null;
  onSuspend: (user: AdminUser, suspended: boolean) => void;
}) {
  return (
    <div className="overflow-x-auto rounded-card border border-line bg-surface">
      <table className="w-full text-left text-sm">
        <thead className="border-b border-line text-xs text-muted">
          <tr>
            <th scope="col" className="px-4 py-3 font-semibold">이메일</th>
            <th scope="col" className="hidden px-4 py-3 font-semibold md:table-cell">가입일</th>
            <th scope="col" className="hidden px-4 py-3 text-right font-semibold md:table-cell">찜 수</th>
            <th scope="col" className="hidden px-4 py-3 text-right font-semibold md:table-cell">일정 수</th>
            <th scope="col" className="px-4 py-3 font-semibold">상태</th>
            <th scope="col" className="px-4 py-3 font-semibold">
              <span className="sr-only">동작</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {users.map((user) => {
            // 자기 자신의 줄이면 정지 단추를 막으려고 구분합니다.
            const isMe = user.id === myId;
            const email = user.email ?? "(이메일 없음)";
            return (
              <tr key={user.id} className="border-b border-line last:border-b-0">
                <td className="px-4 py-3 font-medium">
                  <span className="break-all">{email}</span>
                  {isMe && <span className="ml-1 text-xs text-muted">(나)</span>}
                  {/* 폰에서만: 숨긴 칸(가입일 · 찜 · 일정)을 한 줄로 */}
                  <span className="mt-0.5 block text-xs font-normal text-muted md:hidden">
                    {formatSavedAt(user.created_at)} · 찜 {user.favorite_count} · 일정 {user.trip_count}
                  </span>
                </td>
                <td className="hidden whitespace-nowrap px-4 py-3 text-muted md:table-cell">{formatSavedAt(user.created_at)}</td>
                <td className="hidden px-4 py-3 text-right md:table-cell">{user.favorite_count}</td>
                <td className="hidden px-4 py-3 text-right md:table-cell">{user.trip_count}</td>
                <td className="whitespace-nowrap px-2 py-3 md:px-4">
                  <StatusBadge warn={user.suspended}>{user.suspended ? "정지" : "이용 중"}</StatusBadge>
                </td>
                <td className="whitespace-nowrap py-3 pr-4 text-right md:px-4">
                  {user.suspended ? (
                    <button type="button" disabled={busyId === user.id} onClick={() => onSuspend(user, false)} className={btnSmall}>
                      정지 해제
                    </button>
                  ) : (
                    <button
                      type="button"
                      // 자기 자신을 정지하면 풀어 줄 사람이 없을 수 있어 서버도 막습니다(400). 화면에서도 미리 막아 둡니다.
                      disabled={isMe || busyId === user.id}
                      title={isMe ? "자기 자신은 정지할 수 없어요" : undefined}
                      onClick={() => {
                        // 정지는 그 사람이 바로 찜·일정을 못 쓰게 되므로 한 번 더 묻습니다.
                        if (window.confirm(`${email} 계정을 이용 정지할까요?`)) onSuspend(user, true);
                      }}
                      className={btnSmall}
                    >
                      정지
                    </button>
                  )}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
