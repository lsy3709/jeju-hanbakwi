"use client";

// 이 파일이 하는 일: 이 브라우저에 보관한 내 AI 키를 읽고 · 저장하고 · 지우고 · 서버에 확인하는 훅.
// 보관 규칙은 lib/aiKey.ts, 서버 호출은 lib/api.ts 에 있습니다.
// 다른 탭이나 다른 컴포넌트에서 키가 바뀌어도 따라가도록 useSyncExternalStore 로 localStorage 를 구독합니다.
import { useCallback, useState, useSyncExternalStore } from "react";
import { checkAiKey, errorMessage } from "@/lib/api";
import { clearKey, loadKey, maskKey, saveKey, type SaveResult } from "@/lib/aiKey";

const CHANGED = "jeju-hanbakwi:ai-key-changed"; // 같은 탭 안에서 바뀐 것을 알리는 신호

function subscribe(onChange: () => void) {
  window.addEventListener("storage", onChange); // 다른 탭에서 바뀜
  window.addEventListener(CHANGED, onChange); // 이 탭에서 바뀜
  return () => {
    window.removeEventListener("storage", onChange);
    window.removeEventListener(CHANGED, onChange);
  };
}

export type KeyCheckState = { state: "idle" } | { state: "checking" } | { state: "done"; ok: boolean; message: string };

export function useAiKey() {
  // 서버가 만든 첫 화면에서는 null(키 없음)로 그립니다. 브라우저에서 이어 붙은 뒤 실제 값으로 바뀝니다.
  const key = useSyncExternalStore(
    subscribe,
    () => loadKey(window.localStorage),
    () => null,
  );
  const [check, setCheck] = useState<KeyCheckState>({ state: "idle" });

  const save = useCallback((raw: string): SaveResult => {
    const result = saveKey(window.localStorage, raw);
    if (result.ok) {
      setCheck({ state: "idle" });
      window.dispatchEvent(new Event(CHANGED));
    }
    return result;
  }, []);

  const clear = useCallback(() => {
    clearKey(window.localStorage);
    setCheck({ state: "idle" });
    window.dispatchEvent(new Event(CHANGED));
  }, []);

  /** 보관한 키가 쓸 수 있는 키인지 서버에 묻습니다. */
  const runCheck = useCallback(async () => {
    const current = loadKey(window.localStorage);
    if (!current) return;
    setCheck({ state: "checking" });
    try {
      const result = await checkAiKey(current);
      setCheck({ state: "done", ok: result.ok, message: result.message });
    } catch (e) {
      setCheck({ state: "done", ok: false, message: errorMessage(e) });
    }
  }, []);

  return { hasKey: key !== null, masked: key ? maskKey(key) : null, save, clear, check, runCheck };
}
