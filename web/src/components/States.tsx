// 로딩 · 빈 결과 · 오류 — 모든 화면이 같은 모양으로 상태를 보여 주도록 모았습니다.
import { AlertCircle, Loader2, SearchX } from "lucide-react";
import { btnOutline } from "./ui";

export function Loading({ text = "불러오는 중이에요..." }: { text?: string }) {
  return (
    <div role="status" className="flex items-center justify-center gap-2 py-16 text-muted">
      <Loader2 className="animate-spin" size={20} aria-hidden="true" />
      {text}
    </div>
  );
}

export function Empty({ title, hint }: { title: string; hint?: string }) {
  return (
    <div className="flex flex-col items-center gap-2 py-16 text-center">
      <SearchX size={32} className="text-muted" aria-hidden="true" />
      <p className="font-semibold">{title}</p>
      {hint && <p className="text-sm text-muted">{hint}</p>}
    </div>
  );
}

export function ErrorBox({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div role="alert" className="flex flex-col items-center gap-3 rounded-card border border-line bg-surface px-4 py-10 text-center">
      <AlertCircle size={32} className="text-primary" aria-hidden="true" />
      <p className="font-semibold">불러오지 못했어요</p>
      <p className="text-sm text-muted">{message}</p>
      {onRetry && (
        <button type="button" onClick={onRetry} className={btnOutline}>
          다시 시도
        </button>
      )}
    </div>
  );
}
