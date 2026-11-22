// 이 파일이 하는 일: 관리자 표의 "상태" 칸에 쓰는 작은 알약 표시. warn 이면 주황(정지·숨김), 아니면 틸(이용 중·보임).
import type { ReactNode } from "react";

export function StatusBadge({ warn, children }: { warn: boolean; children: ReactNode }) {
  return (
    <span
      className={`inline-flex whitespace-nowrap rounded-pill px-2.5 py-0.5 text-xs font-semibold ${
        warn ? "bg-primary/10 text-primary" : "bg-secondary/10 text-secondary"
      }`}
    >
      {children}
    </span>
  );
}
