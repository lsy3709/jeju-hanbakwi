import { describe, expect, it } from "vitest";
import { AI_KEY_STORAGE, clearKey, isKeyShape, loadKey, maskKey, saveKey, type KeyStorage } from "./aiKey";

const GOOD = "AIzaUserKey_1234567890-abcdefghij";

function fakeStorage(initial: Record<string, string> = {}): KeyStorage & { data: Record<string, string> } {
  const data = { ...initial };
  return {
    data,
    getItem: (k) => (k in data ? data[k] : null),
    setItem: (k, v) => {
      data[k] = v;
    },
    removeItem: (k) => {
      delete data[k];
    },
  };
}

describe("isKeyShape", () => {
  it("영문 · 숫자 · _ · - · . 20~200자만 통과", () => {
    expect(isKeyShape(GOOD)).toBe(true);
    expect(isKeyShape("AQ.fake-key-for-tests_0000000000.abcdef")).toBe(true); // 마침표가 든 새 형식의 키
    expect(isKeyShape("short")).toBe(false);
    expect(isKeyShape("has space in the key 1234567890")).toBe(false);
    expect(isKeyShape("한글이들어간키1234567890abcdefgh")).toBe(false);
    expect(isKeyShape("x".repeat(201))).toBe(false);
  });
});

describe("maskKey", () => {
  it("앞 4자와 뒤 4자만 보여 준다", () => {
    expect(maskKey(GOOD)).toBe("AIza…ghij");
    expect(maskKey(GOOD)).not.toContain("UserKey");
  });
  it("짧은 값은 통째로 가린다", () => {
    expect(maskKey("abcd1234")).toBe("…");
  });
});

describe("saveKey · loadKey · clearKey", () => {
  it("앞뒤 공백을 떼고 저장한 뒤 다시 읽는다", () => {
    const storage = fakeStorage();
    expect(saveKey(storage, `  ${GOOD}\n`)).toEqual({ ok: true });
    expect(storage.data[AI_KEY_STORAGE]).toBe(GOOD);
    expect(loadKey(storage)).toBe(GOOD);
  });

  it("모양이 틀리면 저장하지 않고 까닭을 알려 준다", () => {
    const storage = fakeStorage();
    const result = saveKey(storage, "틀린 키");
    expect(result.ok).toBe(false);
    expect(result.ok === false && result.message).toBeTruthy();
    expect(loadKey(storage)).toBeNull();
  });

  it("빈 값은 저장하지 않는다", () => {
    expect(saveKey(fakeStorage(), "   ").ok).toBe(false);
  });

  it("저장소에 모양이 틀린 값이 들어 있으면 없는 것으로 본다", () => {
    expect(loadKey(fakeStorage({ [AI_KEY_STORAGE]: "<script>" }))).toBeNull();
  });

  it("지우면 없어진다", () => {
    const storage = fakeStorage({ [AI_KEY_STORAGE]: GOOD });
    clearKey(storage);
    expect(loadKey(storage)).toBeNull();
  });

  it("저장소를 쓸 수 없어도(사생활 보호 창 등) 오류를 던지지 않는다", () => {
    const broken: KeyStorage = {
      getItem: () => {
        throw new Error("blocked");
      },
      setItem: () => {
        throw new Error("blocked");
      },
      removeItem: () => {
        throw new Error("blocked");
      },
    };
    expect(loadKey(broken)).toBeNull();
    expect(saveKey(broken, GOOD).ok).toBe(false);
    expect(() => clearKey(broken)).not.toThrow();
  });
});
