// 화면 어디서나 쓰는 "순수 함수"(같은 입력 → 같은 출력)를 모았습니다. 테스트하기 쉬워요.
import type { SpotsParams } from "./types";

/** 값이 있는 항목만 골라 "?a=1&b=2" 문자열을 만듭니다. 값이 하나도 없으면 빈 문자열. */
export function buildQuery(
  params: Record<string, string | number | boolean | undefined | null>,
): string {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === "") continue;
    search.set(key, String(value));
  }
  const text = search.toString();
  return text ? `?${text}` : "";
}

/** 탐색 화면의 필터 → /spots 쿼리 문자열. */
export function spotsQuery(params: SpotsParams): string {
  return buildQuery({ ...params });
}

export type FallbackTone = "sea" | "green" | "sand";

/** 사진이 없을 때 테마 태그로 대체 그림의 색 계열을 고릅니다. (바다=틸, 오름·숲=초록, 그 밖=오렌지·모래) */
export function pickFallbackTone(tags: string[]): FallbackTone {
  if (tags.some((t) => t === "바다" || t === "폭포")) return "sea";
  if (tags.some((t) => t === "오름" || t === "숲")) return "green";
  return "sand";
}

/** "2026-12-01" → "12월 1일 (화)". 날짜가 없거나 모양이 틀리면 null. */
export function formatDate(date: string | null): string | null {
  if (!date) return null;
  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(date);
  if (!match) return null;
  const y = Number(match[1]);
  const m = Number(match[2]);
  const d = Number(match[3]);
  // 시간대 때문에 하루가 밀리지 않도록 UTC 로 요일을 계산합니다.
  const weekday = ["일", "월", "화", "수", "목", "금", "토"][
    new Date(Date.UTC(y, m - 1, d)).getUTCDay()
  ];
  return `${m}월 ${d}일 (${weekday})`;
}

/** 일정 한 날의 제목: "1일차 · 12월 1일 (화)" (날짜가 없으면 "1일차"). */
export function dayTitle(day: number, date: string | null): string {
  const text = formatDate(date);
  return text ? `${day}일차 · ${text}` : `${day}일차`;
}

/**
 * 저장 시각(ISO) → "2026년 12월 1일". 잘못된 값이면 빈 문자열.
 * 서버는 세계 표준시(UTC)로 시각을 주므로, 사용자 컴퓨터의 시간대로 바꿔서 날짜를 냅니다.
 * (글자 앞 10자만 자르면 한국의 오전 9시 이전에 저장한 것이 하루 전으로 보입니다)
 */
export function formatSavedAt(iso: string): string {
  const saved = new Date(iso);
  if (Number.isNaN(saved.getTime())) return "";
  return `${saved.getFullYear()}년 ${saved.getMonth() + 1}월 ${saved.getDate()}일`;
}

/** 오늘 날짜를 "YYYY-MM-DD" 로(날짜 입력칸의 최소값용). 사용자 컴퓨터의 시간대 기준. */
export function todayString(now: Date = new Date()): string {
  const mm = String(now.getMonth() + 1).padStart(2, "0");
  const dd = String(now.getDate()).padStart(2, "0");
  return `${now.getFullYear()}-${mm}-${dd}`;
}
