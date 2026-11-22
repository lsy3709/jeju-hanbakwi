"use client";

// 이 파일이 하는 일: AI 플래너 화면의 상태(입력값 · 일정 요청 · 저장 · 로그인 안내창)를 맡는 훅.
// 로그인하러 갔다가 돌아와도 일정이 남도록, 받은 일정을 sessionStorage 에 보관하고 처음 열 때 되살립니다(lib/planDraft.ts).
import { useState } from "react";
import { useAuth } from "@/components/AuthProvider";
import { loadKey } from "@/lib/aiKey";
import { errorMessage, planTrip, saveTrip } from "@/lib/api";
import { clearSessionDraft, loadSessionDraft, saveSessionDraft } from "@/lib/planDraft";
import type { PlanInput, PlanResponse } from "@/lib/types";

const EMPTY_INPUT: PlanInput = { message: "", days: 2, companions: "", startDate: "" };

/**
 * 브라우저에서만 부르세요(처음에 sessionStorage 를 읽습니다. page 에서 useHydrated 가 true 가 된 뒤에 그리면 안전합니다).
 * initialMessage: 상세 화면에서 ?q= 로 넘어온 글. 있으면 보관한 일정은 되살리지 않고 새로 시작합니다.
 */
export function usePlanner(initialMessage: string) {
  const { token } = useAuth();
  // 처음 한 번만 보관한 일정을 읽습니다.
  const [restored] = useState(() => (initialMessage ? null : loadSessionDraft()));

  const [input, setInput] = useState<PlanInput>(() => restored?.request ?? { ...EMPTY_INPUT, message: initialMessage });
  const [planning, setPlanning] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [plan, setPlan] = useState<PlanResponse | null>(restored?.plan ?? null);

  const [title, setTitle] = useState("");
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [loginOpen, setLoginOpen] = useState(false);

  /** 입력칸 하나(또는 몇 개)만 바꿉니다. */
  function changeInput(changes: Partial<PlanInput>) {
    setInput((prev) => ({ ...prev, ...changes }));
  }

  async function submit() {
    const request: PlanInput = { ...input, message: input.message.trim() };
    if (!request.message) return;
    setPlanning(true);
    setError(null);
    try {
      // 설정 화면에 넣어 둔 내 AI 키가 있으면 함께 보냅니다(없으면 서버의 기본 방식).
      const result = await planTrip(
        {
          message: request.message,
          days: request.days,
          companions: request.companions || undefined,
          start_date: request.startDate || undefined,
        },
        loadKey(window.localStorage),
      );
      setPlan(result);
      // 새 일정이니 저장 상태를 처음으로 되돌리고, 보관본도 새 것으로 바꿉니다.
      setTitle("");
      setSaved(false);
      setSaveError(null);
      saveSessionDraft(request, result);
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setPlanning(false);
    }
  }

  async function save() {
    if (!plan) return;
    if (!token) {
      setLoginOpen(true); // 로그인 전이면 안내창
      return;
    }
    setSaving(true);
    setSaveError(null);
    try {
      await saveTrip(token, title.trim(), plan.itinerary);
      setSaved(true);
      clearSessionDraft(); // 저장했으니 보관본은 더 필요 없습니다
    } catch (e) {
      setSaveError(errorMessage(e));
    } finally {
      setSaving(false);
    }
  }

  return {
    input,
    changeInput,
    submit,
    planning,
    error,
    plan,
    save: { title, setTitle, saving, saved, saveError, run: save, loginOpen, closeLogin: () => setLoginOpen(false) },
  };
}
