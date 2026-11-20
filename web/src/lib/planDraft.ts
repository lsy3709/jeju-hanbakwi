// 플래너에서 짠 일정을 브라우저 탭(sessionStorage)에 잠깐 보관하는 순수 함수입니다.
// 왜: 로그아웃 상태로 일정을 짜고 구글 로그인을 하면 페이지가 통째로 새로 열려 일정이 사라집니다.
//     돌아온 뒤에 되살려 "저장"을 누를 수 있게 합니다. 저장소는 인자로 받아 테스트에서 가짜를 넣습니다.
import type { PlanInput, PlanResponse } from "./types";

export type PlanDraft = { request: PlanInput; plan: PlanResponse; savedAt: number };

/** sessionStorage 중 이 파일이 쓰는 3가지 함수만 요구합니다(테스트에서 가짜를 넣기 쉽게). */
export type DraftStorage = Pick<Storage, "getItem" | "setItem" | "removeItem">;

export const DRAFT_KEY = "jeju-hanbakwi:plan-draft";
/** 30분. 왜: 오래된 일정이 어느 날 불쑥 나타나면 헷갈립니다. 로그인하고 돌아올 만큼만 보관합니다. */
export const DRAFT_TTL_MS = 30 * 60 * 1000;

const isRecord = (value: unknown): value is Record<string, unknown> => typeof value === "object" && value !== null;

/** 저장소에서 꺼낸 값이 PlanDraft 모양인지 확인합니다. (깨졌거나 옛 버전이 넣은 값을 걸러 내는 문)  */
function isDraft(value: unknown): value is PlanDraft {
  if (!isRecord(value) || !isRecord(value.request) || !isRecord(value.plan)) return false;
  const { request, plan } = value;
  return (
    typeof request.message === "string" &&
    typeof request.days === "number" &&
    typeof request.companions === "string" &&
    typeof request.startDate === "string" &&
    (plan.mode === "ai" || plan.mode === "rule") &&
    typeof plan.answer === "string" &&
    Array.isArray(plan.itinerary) &&
    Array.isArray(plan.sources) &&
    typeof value.savedAt === "number" &&
    Number.isFinite(value.savedAt)
  );
}

/** 일정을 보관합니다. 저장소가 막혀 있어도(용량 초과·사생활 보호 모드) 조용히 넘어갑니다 — 보관은 덤일 뿐이니까요. */
export function saveDraft(storage: DraftStorage, draft: PlanDraft): void {
  try {
    storage.setItem(DRAFT_KEY, JSON.stringify(draft));
  } catch {
    /* 보관하지 못해도 일정 짜기 자체는 계속 됩니다 */
  }
}

/** 보관한 일정을 꺼냅니다. 없거나 · 30분이 지났거나 · 깨졌으면 null (지난 것은 저장소에서도 지웁니다). */
export function loadDraft(storage: DraftStorage, now: number): PlanDraft | null {
  try {
    const raw = storage.getItem(DRAFT_KEY);
    if (raw === null) return null;
    const value: unknown = JSON.parse(raw);
    if (!isDraft(value)) return null;
    if (now - value.savedAt > DRAFT_TTL_MS) {
      clearDraft(storage);
      return null;
    }
    return value;
  } catch {
    return null;
  }
}

export function clearDraft(storage: DraftStorage): void {
  try {
    storage.removeItem(DRAFT_KEY);
  } catch {
    /* 지우지 못해도 어차피 30분 뒤엔 버려집니다 */
  }
}

// ---------- 브라우저의 sessionStorage 를 쓰는 얇은 껍데기 ----------
// sessionStorage 는 브라우저에만 있어서(서버 렌더링 때는 없음) 이벤트 핸들러·초기화 함수 안에서만 부르세요.

function browserStorage(): DraftStorage | null {
  try {
    return typeof window === "undefined" ? null : window.sessionStorage;
  } catch {
    return null; // 저장소 접근이 막힌 브라우저
  }
}

export function loadSessionDraft(): PlanDraft | null {
  const storage = browserStorage();
  return storage ? loadDraft(storage, Date.now()) : null;
}

export function saveSessionDraft(request: PlanInput, plan: PlanResponse): void {
  const storage = browserStorage();
  if (storage) saveDraft(storage, { request, plan, savedAt: Date.now() });
}

export function clearSessionDraft(): void {
  const storage = browserStorage();
  if (storage) clearDraft(storage);
}
