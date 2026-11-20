"use client";

// 이 파일이 하는 일: AI 플래너 화면 조립(입력 폼 → 일정 짜기 → 설명 글 + 일자별 타임라인 → 내 여행에 저장).
// 상태는 hooks/usePlanner.ts, 화면 조각은 components/PlanForm.tsx · PlanResult.tsx 에 있습니다.
import { Suspense } from "react";
import { useSearchParams } from "next/navigation";
import { Sparkles } from "lucide-react";
import { PlanForm } from "@/components/PlanForm";
import { PlanResult } from "@/components/PlanResult";
import { Loading } from "@/components/States";
import { useHydrated } from "@/hooks/useHydrated";
import { usePlanner } from "@/hooks/usePlanner";

export default function PlannerPage() {
  return (
    <Suspense fallback={<Loading />}>
      <PlannerGate />
    </Suspense>
  );
}

// 왜 따로 두나: 로그인하고 돌아온 일정은 브라우저의 sessionStorage 에 있어서 서버는 읽을 수 없습니다.
// 서버가 만든 첫 화면과 달라서 생기는 하이드레이션 오류를 피하려고, 브라우저에서 이어 붙은 뒤에 그립니다.
function PlannerGate() {
  const hydrated = useHydrated();
  return hydrated ? <Planner /> : <Loading />;
}

function Planner() {
  // 상세 화면에서 넘어오면 ?q= 로 입력창이 미리 채워집니다.
  const searchParams = useSearchParams();
  const { input, changeInput, submit, planning, error, plan, save } = usePlanner(searchParams.get("q") ?? "");

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <h1 className="flex items-center gap-2 text-2xl font-extrabold">
        <Sparkles className="text-primary" aria-hidden="true" />
        AI 플래너
      </h1>

      <PlanForm input={input} onChange={changeInput} onSubmit={submit} planning={planning} />

      {planning && <Loading text="AI가 일정을 짜고 있어요. 잠시만 기다려 주세요..." />}

      {error && (
        <p role="alert" className="rounded-card border border-line bg-surface p-4 text-sm">
          일정을 만들지 못했어요. {error}
        </p>
      )}

      {plan && !planning && <PlanResult plan={plan} save={save} />}
    </div>
  );
}
