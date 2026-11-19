"use client";

// 구글 로그인 버튼. Supabase 설정이 비어 있으면 버튼 대신 안내 문구를 보여 줍니다.
import { Info, LogIn, X } from "lucide-react";
import { useAuth } from "./AuthProvider";
import { btnPrimary, btnOutline } from "./ui";

export function LoginPanel() {
  const { configured, signInWithGoogle } = useAuth();

  if (!configured) {
    return (
      <p className="flex items-start gap-2 rounded-card bg-sand p-4 text-sm text-muted">
        <Info size={18} className="mt-0.5 shrink-0" aria-hidden="true" />
        <span>
          로그인 설정이 아직 없어요. <code>web/.env.local</code> 에 Supabase 주소와 키를 넣으면 로그인할 수 있어요.
        </span>
      </p>
    );
  }
  return (
    <button type="button" onClick={signInWithGoogle} className={btnPrimary}>
      <LogIn size={18} aria-hidden="true" />
      구글로 로그인
    </button>
  );
}

/** 로그인이 필요한 버튼(찜·저장)을 로그인 전에 눌렀을 때 띄우는 안내창 */
export function LoginDialog({ message, onClose }: { message: string; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div
        role="dialog"
        aria-modal="true"
        aria-label="로그인 안내"
        onClick={(event) => event.stopPropagation()} // 창 안쪽을 눌렀을 때는 닫히지 않게
        className="w-full max-w-sm space-y-4 rounded-card bg-surface p-6"
      >
        <div className="flex items-start justify-between gap-4">
          <p className="font-semibold">{message}</p>
          <button type="button" onClick={onClose} aria-label="닫기" className="text-muted hover:text-ink">
            <X size={20} aria-hidden="true" />
          </button>
        </div>
        <LoginPanel />
        <button type="button" onClick={onClose} className={`${btnOutline} w-full`}>
          나중에 할게요
        </button>
      </div>
    </div>
  );
}
