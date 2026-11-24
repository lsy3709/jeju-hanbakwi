// 관리자 "여행지 추가·수정" 폼의 계산(입력칸 값 ↔ 서버로 보낼 본문)을 모은 순수 함수입니다.
// 폼 화면(components/admin/SpotForm.tsx)은 입력만 받고, 무엇을 보낼지는 여기서 정합니다.
// 쓰는 곳: components/admin/SpotForm.tsx(화면)와 hooks/useAdminSpots.ts. 테스트는 spotForm.test.ts 입니다.
// 낱말 풀이: POST = 새로 만들기 요청, PATCH = 일부만 고치기 요청입니다.
import type { AdminSpot, SpotCreate, SpotPatch } from "./types";

/** 테마는 서버가 5개까지만 받습니다. */
export const MAX_THEMES = 5;

/** 입력칸의 값. 숫자 칸(위도·경도)도 입력하는 동안은 글자로 들고 있습니다("33." 처럼 덜 친 값도 담을 수 있게). */
export type SpotFormValues = {
  title: string;
  category: string;
  area: string;
  theme_tags: string[];
  one_liner: string;
  overview: string;
  address: string;
  indoor: boolean;
  // 아래 셋은 추가할 때만 씁니다(서버의 수정 주소는 이 칸을 받지 않음).
  image_url: string;
  lat: string;
  lng: string;
};

export function emptySpotForm(): SpotFormValues {
  return {
    title: "",
    category: "",
    area: "",
    theme_tags: [],
    one_liner: "",
    overview: "",
    address: "",
    indoor: false,
    image_url: "",
    lat: "",
    lng: "",
  };
}

/** 수정할 때: 목록의 여행지 값으로 입력칸을 채웁니다. */
export function spotToForm(spot: AdminSpot): SpotFormValues {
  return {
    title: spot.title,
    category: spot.category,
    area: spot.area,
    theme_tags: [...spot.theme_tags],
    one_liner: spot.one_liner ?? "",
    overview: spot.overview ?? "",
    address: spot.address ?? "",
    indoor: spot.indoor,
    image_url: "",
    lat: "",
    lng: "",
  };
}

/** 테마 칩을 눌렀을 때: 있으면 빼고, 없으면 더합니다. 이미 5개면 더하지 않습니다. */
export function toggleTheme(tags: string[], tag: string): string[] {
  if (tags.includes(tag)) return tags.filter((t) => t !== tag);
  if (tags.length >= MAX_THEMES) return tags;
  return [...tags, tag];
}

/** "33.5" → 33.5. 비었거나 숫자가 아니면 undefined(= 보내지 않음). */
function toNumber(text: string): number | undefined {
  const trimmed = text.trim();
  if (trimmed === "") return undefined;
  const value = Number(trimmed);
  return Number.isFinite(value) ? value : undefined;
}

/** 추가 폼 → POST /admin/spots 본문. 선택 칸(사진·위도·경도)은 비어 있으면 아예 빼서 서버 기본값(null)을 쓰게 합니다. */
export function createBody(values: SpotFormValues): SpotCreate {
  const body: SpotCreate = {
    title: values.title.trim(),
    category: values.category,
    area: values.area,
    address: values.address.trim(),
    one_liner: values.one_liner.trim(),
    overview: values.overview.trim(),
    theme_tags: values.theme_tags,
    indoor: values.indoor,
  };
  const lat = toNumber(values.lat);
  const lng = toNumber(values.lng);
  const imageUrl = values.image_url.trim();
  if (lat !== undefined) body.lat = lat;
  if (lng !== undefined) body.lng = lng;
  if (imageUrl) body.image_url = imageUrl;
  return body;
}

/** 테마는 순서가 달라도 같은 것으로 봅니다. */
function sameTags(a: string[], b: string[]): boolean {
  return a.length === b.length && [...a].sort().join("|") === [...b].sort().join("|");
}

/**
 * 수정 폼 → PATCH /admin/spots/{id} 본문. 바뀐 칸만 담습니다.
 * 왜: 서버는 "보낸 칸만" 고칩니다. 안 바꾼 칸까지 보내면 그사이 다른 관리자가 고친 값을 덮어쓸 수 있습니다.
 * 아무것도 안 바꾸면 빈 객체가 되고, 서버가 400("고칠 내용이 없습니다.")으로 알려 줍니다.
 */
export function patchBody(original: AdminSpot, values: SpotFormValues): SpotPatch {
  const changes: SpotPatch = {};
  const title = values.title.trim();
  const address = values.address.trim();
  const oneLiner = values.one_liner.trim();
  const overview = values.overview.trim();
  if (title !== original.title) changes.title = title;
  if (values.category !== original.category) changes.category = values.category;
  if (values.area !== original.area) changes.area = values.area;
  if (address !== (original.address ?? "")) changes.address = address;
  if (oneLiner !== (original.one_liner ?? "")) changes.one_liner = oneLiner;
  if (overview !== (original.overview ?? "")) changes.overview = overview;
  if (!sameTags(values.theme_tags, original.theme_tags)) changes.theme_tags = values.theme_tags;
  if (values.indoor !== original.indoor) changes.indoor = values.indoor;
  return changes;
}
