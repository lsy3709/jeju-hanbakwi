// 사용자가 설정 화면에 넣은 자기 AI(Gemini) 키를 이 브라우저에 보관하는 순수 함수입니다.
// 키는 이 브라우저의 localStorage 에만 두고, 일정 요청 때 X-Gemini-Key 헤더로 서버에 보냅니다.
// 서버는 그 요청에만 쓰고 저장하지 않습니다(docs/api.md). 저장소는 인자로 받아 테스트에서 가짜를 넣습니다.

// 쓰는 곳: hooks/useAiKey.ts. 동작 확인은 aiKey.test.ts 입니다.
// 낱말 풀이: localStorage = 브라우저가 이 사이트용으로 글자를 보관해 두는 작은 창고입니다(탭을 닫아도 남습니다).
/** localStorage 중 이 파일이 쓰는 3가지 함수만 요구합니다. */
export type KeyStorage = Pick<Storage, "getItem" | "setItem" | "removeItem">;

export const AI_KEY_STORAGE = "jeju-hanbakwi:ai-key";

/** 서버가 받는 모양과 같습니다: 영문 · 숫자 · _ · - · . 20~200자(마침표는 새 형식의 키에 들어 있습니다). 맞는 키인지는 "확인" 단추가 서버에 묻습니다. */
export function isKeyShape(key: string): boolean {
  // 정규식으로 "허용 글자만 20~200자"인지 검사합니다. 틀린 키는 서버에 보내기 전에 화면에서 먼저 걸러 냅니다.
  return /^[A-Za-z0-9_.-]{20,200}$/.test(key);
}

/** 화면에 보여 줄 때는 앞 4자와 뒤 4자만. 키 전체를 화면에 다시 그리지 않습니다. */
export function maskKey(key: string): string {
  return key.length >= 12 ? `${key.slice(0, 4)}…${key.slice(-4)}` : "…";
}

/** 보관한 키를 읽습니다. 없거나, 모양이 틀렸거나, 저장소를 쓸 수 없으면 null. */
export function loadKey(storage: KeyStorage): string | null {
  try {
    const value = storage.getItem(AI_KEY_STORAGE);
    return value && isKeyShape(value) ? value : null;
  // localStorage 는 사생활 보호 창 등에서 막혀 오류를 던질 수 있어서, 막혀 있으면 "키 없음"으로 취급합니다.
  } catch {
    return null;
  }
}

export type SaveResult = { ok: true } | { ok: false; message: string };

/** 앞뒤 공백을 떼고 보관합니다. 모양이 틀리면 보관하지 않고 까닭을 돌려줍니다. */
export function saveKey(storage: KeyStorage, raw: string): SaveResult {
  const key = raw.trim();
  if (!key) return { ok: false, message: "키를 넣어 주세요." };
  if (!isKeyShape(key)) return { ok: false, message: "키 모양이 맞지 않아요. 공백 없이 통째로 붙여 넣었는지 확인해 주세요." };
  try {
    storage.setItem(AI_KEY_STORAGE, key);
    return { ok: true };
  } catch {
    return { ok: false, message: "이 브라우저에 저장할 수 없어요. 사생활 보호 창이면 일반 창에서 열어 주세요." };
  }
}

export function clearKey(storage: KeyStorage): void {
  try {
    storage.removeItem(AI_KEY_STORAGE);
  } catch {
    /* 저장소를 쓸 수 없으면 지울 것도 없습니다 */
  }
}
