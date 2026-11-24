// 화면 어디서나 쓰는 "순수 함수"(같은 입력 → 같은 출력)를 모았습니다. 테스트하기 쉬워요.
// 쓰는 곳: api.ts(주소 뒤 쿼리 만들기)와 화면 컴포넌트(날짜·날씨 글자 만들기). 서버나 화면 상태를 부르지 않는 계산만 있습니다.
// 낱말 풀이: 쿼리 = 주소 뒤 "?theme=바다&area=제주시" 처럼 붙는 조건 묶음입니다.
import type { SpotsParams, WeatherDay } from "./types";

/** 값이 있는 항목만 골라 "?a=1&b=2" 문자열을 만듭니다. 값이 하나도 없으면 빈 문자열. */
export function buildQuery(
  params: Record<string, string | number | boolean | undefined | null>,
): string {
  const search = new URLSearchParams();
  // 값이 비어 있는 항목은 쿼리에 넣지 않아야 서버가 "조건 없음"으로 받습니다.
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

/**
 * 사진 아래에 보일 출처 글자("사진: 저작자 · 라이선스"). 보일 것이 없으면 null.
 * 공개 라이선스 사진은 출처를 밝혀야 쓸 수 있습니다. 사진이 없어 대체 그림이 나올 때는 밝힐 출처도 없습니다.
 */
export function photoCreditText(spot: { image_url: string | null; image_credit: string | null }): string | null {
  const credit = spot.image_credit?.trim();
  if (!spot.image_url || !credit) return null;
  return `사진: ${credit}`;
}

/** "2026-12-01" → "12월 1일 (화)". 날짜가 없거나 모양이 틀리면 null. */
export function formatDate(date: string | null): string | null {
  if (!date) return null;
  // 날짜 글자가 "숫자4-숫자2-숫자2" 모양인지 정규식(글자 모양을 적는 약속)으로 확인하고, 괄호 안 값을 뽑아냅니다.
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

/**
 * 날씨 한 줄 글자: "8° / 15° · 비 30%".
 * 서버는 기온·강수확률을 null 로 줄 수 있습니다. 값이 없는 조각은 "NaN°"나 "비 null%" 대신 통째로 뺍니다.
 */
export function weatherText(day: Pick<WeatherDay, "temp_min" | "temp_max" | "rain_prob">): string {
  const parts: string[] = [];
  if (day.temp_min !== null && day.temp_max !== null) {
    parts.push(`${Math.round(day.temp_min)}° / ${Math.round(day.temp_max)}°`);
  }
  if (day.rain_prob !== null) parts.push(`비 ${day.rain_prob}%`);
  return parts.join(" · ");
}
