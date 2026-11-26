// 관리자 "여행지 추가·수정" 폼의 계산(입력칸 값 ↔ 서버로 보낼 본문)을 모은 순수 함수입니다.
// 폼 화면(components/admin/SpotForm.tsx)은 입력만 받고, 무엇을 보낼지는 여기서 정합니다.
import type { AdminSpot, Meta, SpotCreate, SpotPatch } from "./types";

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
  // 사진: 추가할 때도, 수정할 때도 씁니다. 수정 폼에서는 "지금 사진"으로 채워 두고, 바꾼 경우에만 보냅니다.
  image_url: string;
  image_credit: string; // 저작자 · 라이선스 (예: "홍길동 · CC BY 4.0 · Wikimedia Commons")
  image_source_url: string; // 사진을 가져온 원본 쪽 주소
  // 위치는 추가할 때만 씁니다(서버의 수정 주소는 이 칸을 받지 않음).
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
    image_credit: "",
    image_source_url: "",
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
    image_url: spot.image_url ?? "",
    image_credit: spot.image_credit ?? "",
    image_source_url: spot.image_source_url ?? "",
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
  if (imageUrl) {
    body.image_url = imageUrl;
    // 출처는 사진이 있을 때만 뜻이 있습니다.
    if (values.image_credit.trim()) body.image_credit = values.image_credit.trim();
    if (values.image_source_url.trim()) body.image_source_url = values.image_source_url.trim();
  }
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

  // 사진. 주소를 비우면 "바꾸지 않음"입니다(서버에 사진을 지우는 길은 없습니다).
  const imageUrl = values.image_url.trim();
  const credit = values.image_credit.trim();
  const sourceUrl = values.image_source_url.trim();
  const photoChanged = imageUrl !== "" && imageUrl !== (original.image_url ?? "");
  if (photoChanged) {
    // 사진을 바꾸면 출처 두 칸도 반드시 함께 보냅니다. 비어 있으면 "" 로 보내 옛 사진의 출처를 지웁니다.
    // (안 그러면 새 사진 아래에 옛 사진을 찍은 사람의 이름이 남습니다.)
    changes.image_url = imageUrl;
    changes.image_credit = credit;
    changes.image_source_url = sourceUrl;
  } else if (imageUrl !== "") {
    if (credit !== (original.image_credit ?? "")) changes.image_credit = credit;
    if (sourceUrl !== (original.image_source_url ?? "")) changes.image_source_url = sourceUrl;
  }
  return changes;
}

/** 서버가 받는 사진 주소의 길이 한도. */
export const MAX_PHOTO_URL = 300;

/**
 * 사진 주소가 서버 규칙에 맞는지 미리 봅니다. 문제가 없으면 null, 있으면 사람에게 보여 줄 이유.
 * 서버 규칙: https 주소이거나, 이 서버 사진 폴더의 주소(/photos/…jpg). 공백 없이 300자까지.
 */
export function photoUrlProblem(url: string): string | null {
  const value = url.trim();
  if (value === "") return null; // 빈 칸은 "바꾸지 않음"
  if (/\s/.test(value)) return "주소에 공백이 들어 있어요.";
  if (value.length > MAX_PHOTO_URL) return `주소가 너무 길어요(${MAX_PHOTO_URL}자까지). 더 짧은 주소를 써 주세요.`;
  if (!value.startsWith("https://") && !value.startsWith("/photos/")) return "https:// 로 시작하는 주소만 쓸 수 있어요.";
  return null;
}

/**
 * 분류 선택지. 여행지 분류에 편의 시설 · 추천 식당 분류를 이어 붙이고, 지금 분류가 목록에 없으면 그것도 넣습니다.
 * 왜: 선택 칸에 지금 값이 없으면 "고르세요"로 보이고 저장이 막혀서, 약국 · 한식 같은 곳은 사진도 못 바꿉니다.
 */
export function categoryChoices(meta: Pick<Meta, "categories"> & Partial<Pick<Meta, "place_categories" | "food_categories">>, current: string): string[] {
  const all = [...meta.categories, ...(meta.place_categories ?? []), ...(meta.food_categories ?? [])];
  if (current) all.push(current);
  return [...new Set(all)];
}
