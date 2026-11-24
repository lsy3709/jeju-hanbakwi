// 서버 오류 본문을 화면에 보일 한 줄로 바꾸는 순수 함수입니다.
// 서버(FastAPI)의 오류는 두 모양입니다.
//   1) 직접 낸 오류: { "detail": "자기 자신은 정지할 수 없습니다." }
//   2) 입력값 검증 오류(422): { "detail": [ { "loc": ["body", "title"], "msg": "..." }, ... ] }
// 2)를 그냥 버리면 관리자가 어느 칸이 틀렸는지 알 수 없어서, 칸 이름을 한국어로 바꿔 모아 보여 줍니다.

// 이 파일은 api.ts 의 request 가 오류 응답을 읽을 때 부릅니다. 테스트는 errorDetail.test.ts 입니다.
/** 서버가 쓰는 칸 이름 → 폼에 보이는 이름 */
const FIELD_LABELS: Record<string, string> = {
  title: "이름",
  category: "분류",
  area: "지역",
  address: "주소",
  one_liner: "한 줄 소개",
  overview: "소개 글",
  theme_tags: "테마",
  indoor: "실내 여부",
  lat: "위도",
  lng: "경도",
  image_url: "사진 주소",
  suspended: "정지 여부",
};

type ValidationItem = { loc?: unknown; msg?: unknown };

// 검증 오류 한 건을 "칸 이름: 설명" 글자 한 줄로 바꿉니다. 바꿀 수 없으면 null 입니다.
function itemText(item: ValidationItem): string | null {
  if (typeof item?.msg !== "string") return null;
  // loc 은 ["body", "title"] 처럼 오고, 마지막이 칸 이름입니다. (["body", "theme_tags", 0] 처럼 숫자가 붙기도 해서 글자만 고릅니다)
  const names = Array.isArray(item.loc) ? item.loc.filter((part): part is string => typeof part === "string") : [];
  const field = names[names.length - 1];
  if (!field || field === "body") return item.msg;
  return `${FIELD_LABELS[field] ?? field}: ${item.msg}`;
}

/** 오류 본문에서 보여 줄 글자를 꺼냅니다. 모양을 알 수 없으면 null(→ 부르는 쪽이 기본 문구를 씀). */
export function detailText(data: unknown): string | null {
  // "?." 는 앞의 값이 비어 있어도(null) 오류 없이 undefined 를 돌려주는 안전한 접근입니다.
  const detail = (data as { detail?: unknown } | null)?.detail;
  if (typeof detail === "string") return detail;
  if (!Array.isArray(detail)) return null;
  const parts = detail.map((item) => itemText(item as ValidationItem)).filter((text): text is string => text !== null);
  return parts.length > 0 ? `입력값을 확인해 주세요 — ${parts.join(" / ")}` : null;
}
