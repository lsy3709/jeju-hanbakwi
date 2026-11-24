// 로딩 · 빈 결과 · 오류 — 모든 화면이 같은 모양으로 상태를 보여 주도록 모았습니다.
// 쓰는 곳: 목록·상세 화면들. 컴포넌트 = 화면 조각을 그려 돌려주는 함수이고, 중괄호 안의 이름(props)은 부르는 쪽이 넘겨 주는 값입니다.
//  role="status"/"alert" 는 화면 낭독기에게 "상태 안내"라고 알려 주는 표시입니다.
import { AlertCircle, Loader2, SearchX } from "lucide-react";
import { btnOutline } from "./ui";

// 서버 응답을 기다리는 동안 보이는 안내입니다. text 를 안 넘기면 기본 문구를 씁니다.
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

// onRetry 가 있으면 "다시 시도" 버튼을 함께 보입니다. "{onRetry && (...)}" 는 값이 있을 때만 그리라는 뜻입니다.
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
