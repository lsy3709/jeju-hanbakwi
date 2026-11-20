// 임시 데이터입니다. 3일차에 서버(API) 호출로 바꿉니다.
// 지금은 sample-spots.json 의 관광지 12건을 화면 안에서 직접 찾고 거릅니다.
import sampleSpots from "./sample-spots.json";
import type { Spot } from "./types";

export const SPOTS: Spot[] = sampleSpots;

// 테마 칩에 보여 줄 목록 (서버의 constants.py THEMES 와 같습니다)
export const THEMES = ["바다", "오름", "숲", "폭포", "박물관", "체험", "카페", "시장", "역사", "아이와", "사진", "드라이브"];

/** 검색어(q)가 이름·한 줄 소개에 들어 있고, 테마(theme)가 태그에 있는 관광지만 골라 돌려줍니다. 비어 있는 조건은 무시합니다. */
export function findSpots({ q = "", theme = "" }: { q?: string; theme?: string } = {}): Spot[] {
  const word = q.trim().toLowerCase();
  return SPOTS.filter((spot) => {
    if (word && !`${spot.title} ${spot.one_liner}`.toLowerCase().includes(word)) return false;
    if (theme && !spot.theme_tags.includes(theme)) return false;
    return true;
  });
}

/** 주소의 id(글자)로 관광지 하나를 찾습니다. 없거나 숫자가 아니면 undefined. */
export function getSpot(id: string): Spot | undefined {
  return SPOTS.find((spot) => String(spot.id) === id);
}
