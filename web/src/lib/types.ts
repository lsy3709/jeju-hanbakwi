// docs/api.md 의 "자료 모양"을 그대로 옮긴 타입입니다.

export type Spot = {
  id: number;
  title: string;
  category: string;
  area: string;
  address: string;
  lat: number;
  lng: number;
  image_url: string | null; // 사진이 없으면 null → 대체 그림
  image_credit: string | null; // 사진 저작자·라이선스. 있으면 상세에서 반드시 표시
  image_source_url: string | null; // 사진 원본 설명 쪽 주소
  overview: string;
  one_liner: string;
  theme_tags: string[];
  indoor: boolean;
};

export type ItineraryItem = {
  time: "오전" | "점심" | "오후" | "저녁";
  spot_id: number;
  title: string;
  reason: string;
};

export type ItineraryDay = {
  day: number;
  date: string | null;
  weather: string | null;
  items: ItineraryItem[];
};

export type Itinerary = ItineraryDay[];

export type Meta = { themes: string[]; areas: string[]; categories: string[] };

/**
 * 커서 방식으로 나눠 받는 목록의 한 묶음(docs/api.md "목록을 나눠 받기").
 * next_cursor 가 null 이면 끝, 숫자면 그 값을 다음 요청의 cursor 로 그대로 돌려보냅니다.
 */
export type CursorPage<T> = { items: T[]; next_cursor: number | null };

/** 목록 주소에 공통으로 붙이는 쿼리. cursor 는 처음에는 보내지 않습니다. */
export type CursorParams = { cursor?: number | null; size?: number };

/** total(전체 개수)은 첫 묶음에서만 숫자이고, 이어지는 묶음에서는 null 입니다. */
export type SpotList = CursorPage<Spot> & { total: number | null; size: number };

export type SpotsParams = CursorParams & {
  q?: string;
  theme?: string;
  area?: string;
  category?: string;
  indoor?: boolean;
};

export type WeatherDay = {
  date: string;
  label: string;
  icon: "sun" | "cloud" | "rain" | "snow" | "fog";
  temp_min: number | null; // 서버가 값을 못 구하면 null
  temp_max: number | null;
  rain_prob: number | null;
};

export type Weather = {
  rainy_today: boolean;
  message: string;
  areas: { area: string; days: WeatherDay[] }[];
};

export type PlanRequest = {
  message: string;
  days?: number;
  companions?: string;
  start_date?: string;
};

/** 플래너 입력칸의 값(화면용). 서버로 보낼 때는 PlanRequest 로 바꿉니다. */
export type PlanInput = {
  message: string;
  days: number;
  companions: string; // "" = 고르지 않음
  startDate: string; // "" = 고르지 않음
};

export type PlanResponse = {
  mode: "ai" | "rule";
  answer: string;
  itinerary: Itinerary;
  sources: Spot[];
};

export type Me = {
  id: string;
  email: string | null;
  is_admin: boolean; // 관리자 메뉴를 보일지 정할 때만 씁니다(막는 일은 서버가 합니다)
  suspended: boolean; // 이용 정지된 계정이면 찜·일정 주소가 403
};

export type Trip = {
  id: number;
  title: string;
  itinerary: Itinerary;
  created_at: string;
};

// ---------- 관리자 화면 (docs/api.md "관리자 주소") ----------

export type AdminUser = {
  id: string;
  email: string | null;
  suspended: boolean;
  created_at: string;
  favorite_count: number;
  trip_count: number;
};

export type AdminUsersParams = CursorParams & { q?: string };

/** Spot 에 숨김 여부와 출처(sample · tourapi · admin)가 더해진 모양. */
export type AdminSpot = Spot & { hidden: boolean; source: string };

export type AdminSpotPage = CursorPage<AdminSpot> & { total: number | null };

export type AdminSpotsParams = CursorParams & { q?: string; hidden?: boolean };

/** POST /admin/spots 본문. 필수는 title · category · area. */
export type SpotCreate = {
  title: string;
  category: string;
  area: string;
  address?: string;
  one_liner?: string;
  overview?: string;
  theme_tags?: string[];
  indoor?: boolean;
  lat?: number;
  lng?: number;
  image_url?: string;
};

/** PATCH /admin/spots/{id} 본문. 보낸 칸만 고칩니다(사진·위치는 고치지 않음). */
export type SpotPatch = Partial<
  Pick<SpotCreate, "title" | "category" | "area" | "address" | "one_liner" | "overview" | "theme_tags" | "indoor">
> & { hidden?: boolean };
