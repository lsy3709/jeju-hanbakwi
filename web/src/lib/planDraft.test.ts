// 테스트 파일입니다. 화면 없이 planDraft.ts 의 함수 를 불러 결과가 맞는지 확인하며, `npm test`(vitest)가 실행합니다.
// "describe" 는 비슷한 테스트를 묶고, "it" 은 하나의 확인 항목, "expect(...).toBe(...)" 는 "이 값이 이것과 같아야 한다"는 뜻입니다.
import { describe, expect, it } from "vitest";
import { clearDraft, DRAFT_TTL_MS, loadDraft, saveDraft, type PlanDraft } from "./planDraft";

/** 테스트용 가짜 저장소 (sessionStorage 와 같은 3가지 함수만 흉내 냅니다) */
function fakeStorage(initial: Record<string, string> = {}) {
  const data = { ...initial };
  return {
    data,
    getItem: (key: string) => (key in data ? data[key] : null),
    setItem: (key: string, value: string) => {
      data[key] = value;
    },
    removeItem: (key: string) => {
      delete data[key];
    },
  };
}

const NOW = 1_800_000_000_000;
const draft: PlanDraft = {
  request: { message: "부모님과 제주", days: 2, companions: "부모님", startDate: "2026-12-01" },
  plan: {
    mode: "ai",
    answer: "추천 일정이에요",
    itinerary: [{ day: 1, date: "2026-12-01", weather: null, items: [{ time: "오전", spot_id: 1, title: "성산일출봉", reason: "일출" }] }],
    sources: [],
  },
  savedAt: NOW,
};

// 일정 임시 보관의 저장·불러오기·30분 지난 것 버리기·깨진 값 거르기를 확인합니다.
describe("planDraft", () => {
  it("저장한 것을 그대로 불러온다", () => {
    const storage = fakeStorage();
    saveDraft(storage, draft);
    expect(loadDraft(storage, NOW + 1000)).toEqual(draft);
  });
  it("아무것도 저장하지 않았으면 null", () => {
    expect(loadDraft(fakeStorage(), NOW)).toBeNull();
  });
  it("30분이 지나면 버린다(null) — 저장소에서도 지운다", () => {
    const storage = fakeStorage();
    saveDraft(storage, draft);
    expect(loadDraft(storage, NOW + DRAFT_TTL_MS - 1)).not.toBeNull();
    expect(loadDraft(storage, NOW + DRAFT_TTL_MS + 1)).toBeNull();
    expect(Object.keys(storage.data)).toHaveLength(0);
  });
  it("깨진 JSON 은 null", () => {
    const storage = fakeStorage();
    saveDraft(storage, draft);
    const key = Object.keys(storage.data)[0];
    storage.data[key] = "{깨진";
    expect(loadDraft(storage, NOW)).toBeNull();
  });
  it("모양이 다른 값은 null", () => {
    const storage = fakeStorage();
    saveDraft(storage, draft);
    const key = Object.keys(storage.data)[0];
    for (const bad of ['"문자열"', "123", "null", "{}", JSON.stringify({ ...draft, plan: { mode: "x" } }), JSON.stringify({ ...draft, savedAt: "어제" }), JSON.stringify({ ...draft, request: { message: 1 } })]) {
      storage.data[key] = bad;
      expect(loadDraft(storage, NOW)).toBeNull();
    }
  });
  it("지우면 불러올 수 없다", () => {
    const storage = fakeStorage();
    saveDraft(storage, draft);
    clearDraft(storage);
    expect(loadDraft(storage, NOW)).toBeNull();
  });
  it("저장소가 오류를 던져도(용량 초과·사생활 보호 모드) 화면이 죽지 않는다", () => {
    const broken = {
      getItem: () => {
        throw new Error("막힘");
      },
      setItem: () => {
        throw new Error("막힘");
      },
      removeItem: () => {
        throw new Error("막힘");
      },
    };
    expect(() => saveDraft(broken, draft)).not.toThrow();
    expect(loadDraft(broken, NOW)).toBeNull();
    expect(() => clearDraft(broken)).not.toThrow();
  });
});
