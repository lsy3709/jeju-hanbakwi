// 이 파일이 하는 일: AI 플래너의 결과 영역(설명 글 + 일자별 일정 + "간단 추천" 표시 + 내 여행에 저장 폼 + 로그인 안내창).
// 서버 호출은 하지 않고, 저장 동작은 위(usePlanner)에서 받습니다.
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

export function PlanResult({ plan, save }: { plan: PlanResponse; save: PlanSave }) {
  return (
    <section aria-label="추천 일정" className="space-y-4">
      <div className="space-y-2 rounded-card bg-primary/10 p-5">
        {plan.mode === "rule" && (
          <span className="inline-block rounded-pill bg-surface px-3 py-0.5 text-xs font-semibold text-primary">
            간단 추천
          </span>
        )}
        <p className="whitespace-pre-line leading-relaxed">{plan.answer}</p>
      </div>

      <ItineraryView itinerary={plan.itinerary} />

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
        <button type="submit" disabled={save.saving || save.saved || !save.title.trim()} className={save.saved ? btnOutline : btnPrimary}>
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
