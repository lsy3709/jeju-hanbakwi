"use client";

// 이 파일이 하는 일: AI 사용량을 보여 줍니다(기간 고르기 · 합계 카드 · 오늘 · 날짜별 표 · 사용자별 표).
// 설정 화면(내 것)과 관리자 화면(전체)이 함께 씁니다. 데이터는 hooks/useAiUsage.ts 가 불러옵니다.
import { RefreshCw } from "lucide-react";
import { ErrorBox, Loading } from "@/components/States";
import { btnSmall, card, chip } from "@/components/ui";
import { USAGE_PERIODS, useAiUsage } from "@/hooks/useAiUsage";
import { formatCount, usageCards, userLabel } from "@/lib/usage";

export function UsageView({ scope, token }: { scope: "me" | "admin"; token: string }) {
  const { days, setDays, report, loading, error, reload } = useAiUsage(scope, token);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-2">
        <div className="flex gap-2" role="group" aria-label="기간">
          {USAGE_PERIODS.map((period) => (
            <button key={period} type="button" aria-pressed={days === period} onClick={() => setDays(period)} className={chip(days === period)}>
              최근 {period}일
            </button>
          ))}
        </div>
        <button type="button" onClick={reload} className={`${btnSmall} ml-auto`}>
          <RefreshCw size={14} aria-hidden="true" />
          새로 고침
        </button>
      </div>

      {loading ? (
        <Loading />
      ) : error || !report ? (
        <ErrorBox message={error ?? "사용량을 불러오지 못했어요."} onRetry={reload} />
      ) : report.total.requests === 0 ? (
        <p className="py-8 text-center text-sm text-muted">이 기간에는 AI 플래너를 쓴 기록이 없어요.</p>
      ) : (
        <>
          <dl className="grid grid-cols-1 gap-3 sm:grid-cols-3">
            {usageCards(report.total).map((item) => (
              <div key={item.label} className={`${card} p-4`}>
                <dt className="text-sm text-muted">{item.label}</dt>
                <dd className="text-2xl font-extrabold">{item.value}</dd>
                <dd className="text-xs text-muted">{item.hint}</dd>
              </div>
            ))}
          </dl>
          <p className="text-sm text-muted">
            오늘: 요청 {formatCount(report.today.requests)}회 · 토큰 {formatCount(report.today.tokens_total)}
          </p>
          {report.truncated && (
            <p role="status" className="rounded-card bg-sand p-3 text-sm">
              기록이 많아 최근 1,000건만 더했어요. 기간을 줄이면 정확해져요.
            </p>
          )}

          {/* 표는 폰에서도 넘치지 않게 칸을 적게 둡니다(날짜 · 요청 · 토큰). */}
          <div className={`${card} overflow-hidden`}>
            <table className="w-full text-sm">
              <caption className="sr-only">날짜별 사용량</caption>
              <thead className="bg-sand text-left text-xs text-muted">
                <tr>
                  <th scope="col" className="px-3 py-2">날짜</th>
                  <th scope="col" className="px-3 py-2 text-right">요청</th>
                  <th scope="col" className="px-3 py-2 text-right">토큰</th>
                </tr>
              </thead>
              <tbody>
                {report.by_day.map((day) => (
                  <tr key={day.date} className="border-t border-line">
                    <td className="px-3 py-2">{day.date}</td>
                    <td className="px-3 py-2 text-right">
                      {formatCount(day.requests)}
                      <span className="block text-xs text-muted">AI {formatCount(day.ai_requests)}</span>
                    </td>
                    <td className="px-3 py-2 text-right">{formatCount(day.tokens_total)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {report.by_user && report.by_user.length > 0 && (
            <div className={`${card} overflow-hidden`}>
              <table className="w-full table-fixed text-sm">
                <caption className="sr-only">사용자별 사용량</caption>
                <thead className="bg-sand text-left text-xs text-muted">
                  <tr>
                    <th scope="col" className="px-3 py-2">사용자</th>
                    <th scope="col" className="w-16 px-3 py-2 text-right">요청</th>
                    <th scope="col" className="w-24 px-3 py-2 text-right">토큰</th>
                  </tr>
                </thead>
                <tbody>
                  {report.by_user.map((user) => (
                    <tr key={user.user_id ?? "anonymous"} className="border-t border-line">
                      <td className="break-all px-3 py-2">{userLabel(user)}</td>
                      <td className="px-3 py-2 text-right">{formatCount(user.requests)}</td>
                      <td className="px-3 py-2 text-right">
                        {formatCount(user.tokens_total)}
                        <span className="block text-xs text-muted">서버 키 {formatCount(user.server_tokens_total)}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </div>
  );
}
