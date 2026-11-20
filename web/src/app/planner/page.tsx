"use client";

// AI 플래너: 입력 → "일정 짜기" → 설명 글 + 일자별 타임라인 → 내 여행에 저장
import { Suspense, useState } from "react";
import { useSearchParams } from "next/navigation";
import { Loader2, Save, Sparkles } from "lucide-react";
import { useAuth } from "@/components/AuthProvider";
import { ItineraryView } from "@/components/ItineraryView";
import { LoginDialog } from "@/components/LoginPanel";
import { Loading } from "@/components/States";
import { btnOutline, btnPrimary, chip, inputClass } from "@/components/ui";
import { errorMessage, planTrip, saveTrip } from "@/lib/api";
import { todayString } from "@/lib/format";
import type { PlanResponse } from "@/lib/types";

const COMPANIONS = ["혼자", "친구", "연인", "아이와", "부모님"];

export default function PlannerPage() {
  return (
    <Suspense fallback={<Loading />}>
      <Planner />
    </Suspense>
  );
}

function Planner() {
  const { token } = useAuth();
  // 상세 화면에서 넘어오면 ?q= 로 입력창이 미리 채워집니다.
  const searchParams = useSearchParams();
  const [message, setMessage] = useState(searchParams.get("q") ?? "");
  const [days, setDays] = useState(2);
  const [companions, setCompanions] = useState(""); // 선택 사항: 같은 칩을 다시 누르면 해제
  const [startDate, setStartDate] = useState("");

  const [planning, setPlanning] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [plan, setPlan] = useState<PlanResponse | null>(null);

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    if (!message.trim()) return;
    setPlanning(true);
    setError(null);
    try {
      const result = await planTrip({
        message: message.trim(),
        days,
        companions: companions || undefined,
        start_date: startDate || undefined,
      });
      setPlan(result);
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setPlanning(false);
    }
  }

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <h1 className="flex items-center gap-2 text-2xl font-extrabold">
        <Sparkles className="text-primary" aria-hidden="true" />
        AI 플래너
      </h1>

      <form onSubmit={submit} className="space-y-5 rounded-card border border-line bg-surface p-5">
        <label className="block space-y-2">
          <span className="font-semibold">하고 싶은 여행</span>
          <textarea
            value={message}
            onChange={(event) => setMessage(event.target.value)}
            maxLength={500}
            rows={3}
            required
            placeholder="예) 부모님과 많이 걷지 않는 코스로 다녀오고 싶어요"
            className="w-full rounded-card border border-line bg-surface px-4 py-3 text-sm placeholder:text-muted"
          />
        </label>

        <fieldset className="space-y-2">
          <legend className="font-semibold">며칠 가나요?</legend>
          <div className="flex gap-2">
            {[1, 2, 3].map((n) => (
              <button key={n} type="button" aria-pressed={days === n} onClick={() => setDays(n)} className={chip(days === n)}>
                {n}일
              </button>
            ))}
          </div>
        </fieldset>

        <fieldset className="space-y-2">
          <legend className="font-semibold">누구와 가나요? (선택)</legend>
          <div className="flex flex-wrap gap-2">
            {COMPANIONS.map((name) => (
              <button
                key={name}
                type="button"
                aria-pressed={companions === name}
                onClick={() => setCompanions(companions === name ? "" : name)}
                className={chip(companions === name)}
              >
                {name}
              </button>
            ))}
          </div>
        </fieldset>

        <label className="block space-y-2">
          <span className="font-semibold">시작 날짜 (선택)</span>
          <input
            type="date"
            value={startDate}
            min={todayString()}
            onChange={(event) => setStartDate(event.target.value)}
            className={`${inputClass} sm:w-56`}
          />
        </label>

        <button type="submit" disabled={planning || !message.trim()} className={btnPrimary}>
          {planning ? <Loader2 className="animate-spin" size={18} aria-hidden="true" /> : <Sparkles size={18} aria-hidden="true" />}
          {planning ? "일정을 짜는 중이에요..." : "일정 짜기"}
        </button>
      </form>

      {planning && <Loading text="AI가 일정을 짜고 있어요. 잠시만 기다려 주세요..." />}

      {error && (
        <p role="alert" className="rounded-card border border-line bg-surface p-4 text-sm">
          일정을 만들지 못했어요. {error}
        </p>
      )}

      {plan && !planning && <PlanResult plan={plan} token={token} />}
    </div>
  );
}

function PlanResult({ plan, token }: { plan: PlanResponse; token: string | null }) {
  const [title, setTitle] = useState("");
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [showLogin, setShowLogin] = useState(false);

  async function save(event: React.FormEvent) {
    event.preventDefault();
    if (!token) {
      setShowLogin(true); // 로그인 전이면 안내창
      return;
    }
    setSaving(true);
    setSaveError(null);
    try {
      await saveTrip(token, title.trim(), plan.itinerary);
      setSaved(true);
    } catch (e) {
      setSaveError(errorMessage(e));
    } finally {
      setSaving(false);
    }
  }

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

      <form onSubmit={save} className="flex flex-col gap-3 rounded-card border border-line bg-surface p-5 sm:flex-row sm:items-end">
        <label className="flex-1 space-y-2">
          <span className="font-semibold">내 여행에 저장</span>
          <input
            value={title}
            onChange={(event) => setTitle(event.target.value)}
            required
            maxLength={60}
            placeholder="일정 제목 (예: 부모님과 제주)"
            className={inputClass}
          />
        </label>
        <button type="submit" disabled={saving || saved || !title.trim()} className={saved ? btnOutline : btnPrimary}>
          <Save size={18} aria-hidden="true" />
          {saved ? "저장했어요" : saving ? "저장 중..." : "저장"}
        </button>
      </form>
      {saved && (
        <p role="status" className="text-sm text-secondary">
          저장했어요. &quot;내 여행&quot; 탭에서 볼 수 있어요.
        </p>
      )}
      {saveError && (
        <p role="alert" className="text-sm text-primary">
          저장하지 못했어요. {saveError}
        </p>
      )}
      {showLogin && <LoginDialog message="일정을 저장하려면 로그인이 필요해요. 로그인하면 「내 여행」 화면으로 이동하고, 지금 짠 일정은 사라져요. 로그인한 뒤에 다시 짜 주세요." onClose={() => setShowLogin(false)} />}
    </section>
  );
}
