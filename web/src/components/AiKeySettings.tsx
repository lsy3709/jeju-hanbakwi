"use client";

// 이 파일이 하는 일: 설정 화면의 "내 AI 키" 묶음(안내 · 입력 · 저장 · 확인 · 지우기).
// 키를 다루는 일은 hooks/useAiKey.ts 가 하고, 여기는 그리기만 합니다. 저장한 키는 화면에 다시 그리지 않고 앞뒤 4자만 보여 줍니다.
import { useState } from "react";
import { CheckCircle2, KeyRound, ShieldAlert, Trash2 } from "lucide-react";
import { btnOutline, btnPrimary, card, inputClass } from "@/components/ui";
import { useAiKey } from "@/hooks/useAiKey";

export function AiKeySettings() {
  const { hasKey, masked, save, clear, check, runCheck } = useAiKey();
  const [draft, setDraft] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [savedNow, setSavedNow] = useState(false);

  function submit() {
    const result = save(draft);
    if (result.ok) {
      setDraft(""); // 저장한 키는 입력칸에 남기지 않습니다
      setError(null);
      setSavedNow(true);
    } else {
      setError(result.message);
      setSavedNow(false);
    }
  }

  return (
    <section aria-labelledby="ai-key-title" className={`${card} space-y-4 p-5`}>
      <h2 id="ai-key-title" className="flex items-center gap-2 text-lg font-bold">
        <KeyRound size={20} className="text-primary" aria-hidden="true" />
        내 AI 키
      </h2>

      <div className="space-y-1 text-sm text-muted">
        <p>내 Gemini 키를 넣으면 AI 플래너가 그 키로 일정을 짭니다. 넣지 않으면 지금처럼 서비스의 기본 방식으로 짭니다.</p>
        <p>키는 <b>이 브라우저에만</b> 저장되고, 일정을 짤 때만 서버로 보내집니다. 서버는 키를 저장하지 않습니다.</p>
        <p>키는 Google AI Studio 의 API keys 화면에서 만들 수 있습니다.</p>
      </div>

      <p className="flex items-start gap-2 rounded-card bg-sand p-3 text-sm">
        <ShieldAlert size={18} className="mt-0.5 shrink-0 text-primary" aria-hidden="true" />
        <span>여럿이 쓰는 PC 에서는 넣지 마세요. 넣었다면 다 쓴 뒤 꼭 지워 주세요.</span>
      </p>

      {hasKey ? (
        <div className="space-y-3">
          <p className="text-sm">
            저장된 키: <code className="rounded bg-sand px-2 py-0.5">{masked}</code>
          </p>
          <div className="flex flex-wrap gap-2">
            <button type="button" onClick={runCheck} disabled={check.state === "checking"} className={btnOutline}>
              <CheckCircle2 size={18} aria-hidden="true" />
              {check.state === "checking" ? "확인하는 중..." : "키 확인"}
            </button>
            <button
              type="button"
              onClick={() => {
                clear();
                setSavedNow(false);
              }}
              className={btnOutline}
            >
              <Trash2 size={18} aria-hidden="true" />
              키 지우기
            </button>
          </div>
          {savedNow && check.state === "idle" && <p role="status" className="text-sm text-secondary">저장했어요. 키 확인을 누르면 쓸 수 있는 키인지 볼 수 있어요.</p>}
          {check.state === "done" && (
            <p role="status" className={`text-sm ${check.ok ? "text-secondary" : "text-primary"}`}>
              {check.message}
            </p>
          )}
        </div>
      ) : (
        <form
          onSubmit={(event) => {
            event.preventDefault();
            submit();
          }}
          className="space-y-3"
        >
          <label className="block space-y-2">
            <span className="text-sm font-semibold">Gemini API 키</span>
            {/* 화면에 글자가 보이지 않게 password 로 두고, 브라우저가 기억하지 않게 합니다. */}
            <input
              type="password"
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              autoComplete="off"
              spellCheck={false}
              placeholder="AIza..."
              className={inputClass}
            />
          </label>
          {error && (
            <p role="alert" className="text-sm text-primary">
              {error}
            </p>
          )}
          <button type="submit" disabled={!draft.trim()} className={btnPrimary}>
            저장
          </button>
        </form>
      )}
    </section>
  );
}
