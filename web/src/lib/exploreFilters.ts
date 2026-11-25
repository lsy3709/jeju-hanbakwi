// 탐색 화면의 "주소 쿼리 ↔ 필터" 변환을 모은 순수 함수입니다. (React 와 무관해서 테스트하기 쉬워요)
import { buildQuery, spotsQuery } from "./format";
import type { SpotsParams } from "./types";

/** 주소 쿼리를 읽어 낸 결과. 입력칸·버튼의 선택 표시에 쓰는 글자(q, theme …)와 서버에 보낼 filters 를 함께 둡니다. */
export type ExploreState = {
  q: string;
  theme: string;
  area: string;
  category: string;
  indoorText: string; // "true" | "false" | ""
  view: ExploreView;
  isMap: boolean; // view === "map" (평면 지도)
  filters: SpotsParams;
};

/** 결과를 보여 주는 방식. "" 은 목록, "map" 은 평면 지도, "3d" 는 땅의 높낮이가 보이는 3D 지도. */
export type ExploreView = "" | "map" | "3d";

/** URLSearchParams(또는 useSearchParams 의 값)처럼 get 만 있으면 됩니다. */
type QueryReader = { get(name: string): string | null };

/** 주소 쿼리(?q=&theme=&area=&category=&indoor=&view=map|3d) → 화면 상태. 빈 값은 필터에서 뺍니다. */
export function parseExploreQuery(params: QueryReader): ExploreState {
  const q = params.get("q") ?? "";
  const theme = params.get("theme") ?? "";
  const area = params.get("area") ?? "";
  const category = params.get("category") ?? "";
  const indoorText = params.get("indoor") ?? "";
  const viewText = params.get("view");
  const view: ExploreView = viewText === "map" || viewText === "3d" ? viewText : "";
  return {
    q,
    theme,
    area,
    category,
    indoorText,
    view,
    isMap: view === "map",
    filters: {
      q: q || undefined,
      theme: theme || undefined,
      area: area || undefined,
      category: category || undefined,
      indoor: indoorText === "" ? undefined : indoorText === "true",
    },
  };
}

/**
 * 현재 상태에서 changes 만 바꾼 다음 주소를 만듭니다. (예: { theme: "바다" })
 * 값을 "" 로 바꾸면 그 항목은 주소에서 빠집니다. view(지도 · 3D 지도 보기)는 바꾸지 않는 한 그대로 유지합니다.
 */
export function exploreHref(pathname: string, state: ExploreState, changes: Record<string, string>): string {
  const next = {
    q: state.q,
    theme: state.theme,
    area: state.area,
    category: state.category,
    indoor: state.indoorText,
    view: state.view,
    ...changes,
  };
  return `${pathname}${buildQuery(next)}`;
}

/** 걸려 있는 필터가 하나라도 있는지("필터 지우기" 버튼을 보일지 정할 때). */
export function hasActiveFilter(filters: SpotsParams): boolean {
  return Object.values(filters).some((value) => value !== undefined);
}

/** 필터가 바뀌었는지 비교하는 열쇠. 같은 필터면 같은 글자가 나옵니다. */
export function filtersKey(filters: SpotsParams): string {
  return spotsQuery(filters);
}
