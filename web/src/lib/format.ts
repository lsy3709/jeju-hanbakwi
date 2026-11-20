// 화면 어디서나 쓰는 "순수 함수"(같은 입력 → 같은 출력)를 모았습니다. 테스트하기 쉬워요.

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

export type FallbackTone = "sea" | "green" | "sand";

/** 사진이 없을 때 테마 태그로 대체 그림의 색 계열을 고릅니다. (바다=틸, 오름·숲=초록, 그 밖=오렌지·모래) */
export function pickFallbackTone(tags: string[]): FallbackTone {
  if (tags.some((t) => t === "바다" || t === "폭포")) return "sea";
  if (tags.some((t) => t === "오름" || t === "숲")) return "green";
  return "sand";
}
