// AI 사용량을 화면에 보여 줄 글자로 바꾸는 순수 함수입니다. (서버 응답 모양은 docs/api.md 의 "AI 사용량")
// 쓰는 곳: components/UsageView.tsx. 서버가 준 숫자를 카드·표에 넣을 글자로 바꿉니다. 테스트는 usage.test.ts 입니다.
import type { UsageSummary, UsageUser } from "./types";

/** 세 자리마다 쉼표를 찍습니다. */
export function formatCount(value: number): string {
  return value.toLocaleString("en-US");
}

export type UsageCard = { label: string; value: string; hint: string };

/** 합계를 카드 세 장으로: 요청 수 / 토큰 수 / 서버 키로 쓴 토큰(서비스가 내는 몫). */
export function usageCards(s: UsageSummary): UsageCard[] {
  return [
    { label: "요청", value: formatCount(s.requests), hint: `AI ${formatCount(s.ai_requests)} · 간단 추천 ${formatCount(s.rule_requests)}` },
    { label: "토큰", value: formatCount(s.tokens_total), hint: `보낸 것 ${formatCount(s.tokens_in)} · 받은 것 ${formatCount(s.tokens_out)}` },
    {
      label: "서버 키로 쓴 토큰",
      value: formatCount(s.server_tokens_total),
      hint: `서버 키 ${formatCount(s.server_key_requests)}회 · 내 키 ${formatCount(s.user_key_requests)}회`,
    },
  ];
}

/** 사용자별 표의 이름 칸. 로그인하지 않은 요청은 한 줄로 묶여 옵니다. */
export function userLabel(user: Pick<UsageUser, "user_id" | "email">): string {
  if (user.email) return user.email;
  return user.user_id === null ? "로그인하지 않은 요청" : "(탈퇴했거나 알 수 없는 사용자)";
}
