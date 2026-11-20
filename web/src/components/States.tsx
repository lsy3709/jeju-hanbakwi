// 로딩 · 빈 결과 — 모든 화면이 같은 모양으로 상태를 보여 주도록 모았습니다.
import { Loader2, SearchX } from "lucide-react";

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
