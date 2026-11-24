// 이 파일이 하는 일: AI 플래너의 결과 영역(설명 글 + 일자별 일정 + "간단 추천" 표시 + 내 여행에 저장 폼 + 로그인 안내창).
// 서버 호출은 하지 않고, 저장 동작은 위(usePlanner)에서 받습니다.
// 컴포넌트 = 화면 조각을 그려 돌려주는 함수입니다. 중괄호 안의 이름들(props)은 부르는 쪽이 넘겨 주는 값입니다.
// 쓰는 곳: app/planner/page.tsx. 일정 짜기 결과를 그립니다.
import Link from "next/link";
import { Save } from "lucide-react";
import { ItineraryView } from "@/components/ItineraryView";
import { LoginDialog } from "@/components/LoginPanel";
import { btnOutline, btnPrimary, inputClass } from "@/components/ui";
import type { PlanResponse } from "@/lib/types";

/** usePlanner 의 save 묶음과 같은 모양입니다. */
export type PlanSave = {
  title: string;
  setTitle: (title: string) => void;
  saving: boolean;
  saved: boolean;
  saveError: string | null;
  run: () => void;
  loginOpen: boolean;
  closeLogin: () => void;
};

// plan 은 서버가 돌려준 일정, save 는 저장 관련 값과 동작 묶음입니다. 로그인했으면 서버가 이미 저장해 둬서(saved_trip) 저장 폼 대신 안내가 보입니다.
export function PlanResult({
  plan,
  save,
}: {
  plan: PlanResponse;
  save: PlanSave;
}) {
  return (
    <section aria-label="추천 일정" className="space-y-4">
      {/* 내 AI 키로 일정을 받지 못해 다른 방식으로 대신했을 때 서버가 보내는 안내 */}
      {plan.notice && (
        <p
          role="status"
          className="rounded-card border border-line bg-surface p-4 text-sm"
        >
          {plan.notice}{" "}
          <Link
            href="/settings"
            className="font-semibold text-primary underline"
          >
            설정 열기
          </Link>
        </p>
      )}
      <div className="space-y-2 rounded-card bg-primary/10 p-5">
        {plan.mode === "rule" && (
          <span className="inline-block rounded-pill bg-surface px-3 py-0.5 text-xs font-semibold text-primary">
            간단 추천
          </span>
        )}
        <p className="whitespace-pre-line leading-relaxed">{plan.answer}</p>
      </div>

      <ItineraryView itinerary={plan.itinerary} />

      {/* 로그인한 채로 짠 일정은 서버가 바로 저장해 줍니다. 그때는 저장 폼 대신 안내만 보여 줍니다. */}
      {plan.saved_trip ? (
        <p
          role="status"
          className="rounded-card border border-line bg-surface p-5 text-sm"
        >
          <b>내 여행에 자동으로 저장했어요.</b> 제목: {plan.saved_trip.title}{" "}
          <Link href="/my" className="font-semibold text-primary underline">
            내 여행 열기
          </Link>
        </p>
      ) : (
        <>
          <form
            onSubmit={(event) => {
              event.preventDefault();
              save.run();
            }}
            className="flex flex-col gap-3 rounded-card border border-line bg-surface p-5 sm:flex-row sm:items-end"
          >
            <label className="flex-1 space-y-2">
              <span className="font-semibold">내 여행에 저장</span>
              <input
                value={save.title}
                onChange={(event) => save.setTitle(event.target.value)}
                required
                maxLength={60}
                placeholder="일정 제목 (예: 부모님과 제주)"
                className={inputClass}
              />
            </label>
            <button
              type="submit"
              disabled={save.saving || save.saved || !save.title.trim()}
              className={save.saved ? btnOutline : btnPrimary}
            >
              <Save size={18} aria-hidden="true" />
              {save.saved ? "저장했어요" : save.saving ? "저장 중..." : "저장"}
            </button>
          </form>
          {save.saved && (
            <p role="status" className="text-sm text-secondary">
              저장했어요. &quot;내 여행&quot; 탭에서 볼 수 있어요.
            </p>
          )}
          {save.saveError && (
            <p role="alert" className="text-sm text-primary">
              저장하지 못했어요. {save.saveError}
            </p>
          )}
        </>
      )}
      {save.loginOpen && (
        <LoginDialog
          message="일정을 저장하려면 로그인이 필요해요. 로그인한 뒤 이 화면으로 돌아오면 지금 일정이 그대로 있어요. 그다음 저장을 눌러 주세요."
          next="/planner"
          onClose={save.closeLogin}
        />
      )}
    </section>
  );
}
