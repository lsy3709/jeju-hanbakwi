"use client";

// "use client" 는 이 파일이 브라우저에서 도는 컴포넌트라는 표시입니다. 클릭에 반응하거나 useState 로 값을 기억하려면 필요합니다. 로그인 정보(useAuth)를 쓰기 때문에도 필요합니다.
// 이 파일이 하는 일: 설정 화면의 "내 AI 사용량" 묶음. 로그인한 사람에게만 사용량을 보여 줍니다.
import { BarChart3 } from "lucide-react";
import { useAuth } from "@/components/AuthProvider";
import { UsageView } from "@/components/UsageView";
import { card } from "@/components/ui";

// 로그인 확인이 끝나기 전(loading)에는 안내를 비우고, 토큰이 있으면 사용량을, 없으면 로그인 안내를 보입니다.
export function MyUsageSettings() {
  const { loading, token } = useAuth();

  return (
    <section aria-labelledby="my-usage-title" className={`${card} space-y-4 p-5`}>
      <h2 id="my-usage-title" className="flex items-center gap-2 text-lg font-bold">
        <BarChart3 size={20} className="text-primary" aria-hidden="true" />
        내 AI 사용량
      </h2>
      <p className="text-sm text-muted">
        로그인한 채로 AI 플래너를 쓴 횟수와 토큰 수입니다. 요청한 글이나 일정 내용은 기록하지 않습니다.
      </p>
      {loading ? null : token ? (
        <UsageView scope="me" token={token} />
      ) : (
        <p className="rounded-card bg-sand p-3 text-sm">로그인하면 내 사용량을 볼 수 있어요. (내 여행 메뉴에서 로그인)</p>
      )}
    </section>
  );
}
