"use client";

// 이 파일이 하는 일: AI 플래너 화면의 상태(입력값 · 일정 요청 · 저장 · 로그인 안내창)를 맡는 훅.
// 로그인하러 갔다가 돌아와도 일정이 남도록, 받은 일정을 sessionStorage 에 보관하고 처음 열 때 되살립니다(lib/planDraft.ts).
// 일정 짜기는 십몇 초가 걸립니다. 그 사이 다른 메뉴에 다녀와도 이어서 보이도록, 진행 중인 요청을 이 파일(모듈)에 붙들어 둡니다.
import { useEffect, useState } from "react";
import { useAuth } from "@/components/AuthProvider";
import { loadKey } from "@/lib/aiKey";
import { errorMessage, planTrip, saveTrip } from "@/lib/api";
import { clearSessionDraft, loadSessionDraft, saveSessionDraft } from "@/lib/planDraft";
import type { PlanInput, PlanResponse } from "@/lib/types";

const EMPTY_INPUT: PlanInput = { message: "", days: 2, companions: "", startDate: "" };

// 진행 중인 일정 요청. 화면(컴포넌트)이 사라져도 이 값은 남아서, 돌아온 화면이 같은 요청을 이어받습니다.
// (메뉴를 오가는 동안에만 남습니다. 새로 고치거나 탭을 닫으면 사라집니다)
let inflight: { request: PlanInput; promise: Promise<PlanResponse> } | null = null;

/**
 * 브라우저에서만 부르세요(처음에 sessionStorage 를 읽습니다. page 에서 useHydrated 가 true 가 된 뒤에 그리면 안전합니다).
 * initialMessage: 상세 화면에서 ?q= 로 넘어온 글. 있으면 보관한 일정은 되살리지 않고 새로 시작합니다.
 */
export function usePlanner(initialMessage: string) {
  const { token } = useAuth();
  // 처음 한 번만: 진행 중인 요청이 있으면 그것을, 없으면 보관한 일정을 읽습니다.
  const [pending] = useState(() => (initialMessage ? null : inflight));
  const [restored] = useState(() => (initialMessage || pending ? null : loadSessionDraft()));

  const [input, setInput] = useState<PlanInput>(
    () => pending?.request ?? restored?.request ?? { ...EMPTY_INPUT, message: initialMessage },
  );
  const [planning, setPlanning] = useState(pending !== null);
  const [error, setError] = useState<string | null>(null);
  const [plan, setPlan] = useState<PlanResponse | null>(restored?.plan ?? null);

  const [title, setTitle] = useState("");
  const [saving, setSaving] = useState(false);
  // 서버가 자동으로 저장해 준 일정(saved_trip)이면 처음부터 "저장됨"입니다.
  const [saved, setSaved] = useState(Boolean(restored?.plan.saved_trip));
  const [saveError, setSaveError] = useState<string | null>(null);
  const [loginOpen, setLoginOpen] = useState(false);

  // 지금 이 화면이 결과를 기다리는 요청. 처음에는 다녀온 사이에도 진행 중이던 요청(있으면)을 이어받습니다.
  const [tracked, setTracked] = useState<Promise<PlanResponse> | null>(pending?.promise ?? null);

  // 기다리던 요청이 끝나면 화면에 반영합니다. 화면이 사라진 뒤에 끝나면 아무것도 하지 않습니다.
  useEffect(() => {
    if (!tracked) return;
    let mounted = true;
    tracked
      .then((result) => {
        if (!mounted) return;
        setPlan(result);
        // 새 일정이니 저장 상태를 처음으로 되돌립니다. 자동 저장됐으면 바로 "저장됨".
        setTitle("");
        setSaved(Boolean(result.saved_trip));
        setSaveError(null);
      })
      .catch((e) => {
        if (mounted) setError(errorMessage(e));
      })
      .finally(() => {
        if (mounted) setPlanning(false);
      });
    return () => {
      mounted = false;
    };
  }, [tracked]);

  /** 입력칸 하나(또는 몇 개)만 바꿉니다. */
  function changeInput(changes: Partial<PlanInput>) {
    setInput((prev) => ({ ...prev, ...changes }));
  }

  function submit() {
    const request: PlanInput = { ...input, message: input.message.trim() };
    if (!request.message || inflight) return; // 진행 중이면 또 보내지 않습니다
    setPlanning(true);
    setError(null);
    // 설정 화면에 넣어 둔 내 AI 키와 로그인 토큰이 있으면 함께 보냅니다(토큰이 있으면 서버가 자동으로 저장).
    const promise = planTrip(
      {
        message: request.message,
        days: request.days,
        companions: request.companions || undefined,
        start_date: request.startDate || undefined,
      },
      { aiKey: loadKey(window.localStorage), token },
    );
    const mine = { request, promise };
    inflight = mine;
    // 화면이 사라져도 꼭 하는 일: 보관본을 새 것으로 바꾸고, 진행 중 표시를 지웁니다.
    promise
      .then((result) => saveSessionDraft(request, result))
      .catch(() => {})
      .finally(() => {
        if (inflight === mine) inflight = null;
      });
    setTracked(promise); // 이 화면에 반영하는 일은 위의 useEffect 가 맡습니다
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
