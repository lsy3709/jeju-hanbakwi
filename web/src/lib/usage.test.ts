// 테스트 파일입니다. 화면 없이 usage.ts 의 함수 를 불러 결과가 맞는지 확인하며, `npm test`(vitest)가 실행합니다.
// "describe" 는 비슷한 테스트를 묶고, "it" 은 하나의 확인 항목, "expect(...).toBe(...)" 는 "이 값이 이것과 같아야 한다"는 뜻입니다.
import { describe, expect, it } from "vitest";
import { formatCount, usageCards, userLabel } from "./usage";
import type { UsageSummary } from "./types";

const summary: UsageSummary = {
  requests: 12,
  ai_requests: 10,
  rule_requests: 2,
  user_key_requests: 3,
  server_key_requests: 7,
  tokens_in: 41200,
  tokens_out: 5300,
  tokens_total: 46500,
  server_tokens_total: 31000,
};

// 숫자 쉼표 표시를 확인합니다.
describe("formatCount", () => {
  it("세 자리마다 쉼표", () => {
    expect(formatCount(0)).toBe("0");
    expect(formatCount(46500)).toBe("46,500");
    expect(formatCount(1234567)).toBe("1,234,567");
  });
});

// 요청·토큰 카드 글자가 맞게 만들어지는지 확인합니다.
describe("usageCards", () => {
  it("요청 · 토큰 · 서버 키 몫을 카드로 만든다", () => {
    const cards = usageCards(summary);
    expect(cards.map((c) => c.label)).toEqual(["요청", "토큰", "서버 키로 쓴 토큰"]);
    expect(cards[0]).toMatchObject({ value: "12", hint: "AI 10 · 간단 추천 2" });
    expect(cards[1]).toMatchObject({ value: "46,500", hint: "보낸 것 41,200 · 받은 것 5,300" });
    expect(cards[2]).toMatchObject({ value: "31,000", hint: "서버 키 7회 · 내 키 3회" });
  });
});

// 사용자 이름 칸 글자를 확인합니다.
describe("userLabel", () => {
  it("이메일이 있으면 이메일, 로그인하지 않은 줄은 따로 적는다", () => {
    expect(userLabel({ user_id: "u1", email: "a@example.com" })).toBe("a@example.com");
    expect(userLabel({ user_id: null, email: null })).toBe("로그인하지 않은 요청");
    expect(userLabel({ user_id: "u2", email: null })).toBe("(탈퇴했거나 알 수 없는 사용자)");
  });
});
