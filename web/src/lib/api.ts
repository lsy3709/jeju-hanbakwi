// 이 파일이 하는 일: 서버(FastAPI)와 통하는 유일한 문입니다.
// 화면은 fetch 를 직접 부르지 않고 여기 함수만 씁니다. 새 서버 주소를 쓰려면 여기에 함수를 하나 더하세요.
// 주소·응답 모양은 docs/api.md 를 따릅니다.
import { resolveApiUrl } from "./apiUrl";
import { detailText } from "./errorDetail";
import { buildQuery, spotsQuery } from "./format";
import type {
  AdminSpot,
  AdminSpotPage,
  AdminSpotsParams,
  AdminUser,
  AdminUsersParams,
  CursorPage,
  CursorParams,
  Itinerary,
  KeyCheck,
  Me,
  Meta,
  PlanRequest,
  PlanResponse,
  Spot,
  SpotCreate,
  SpotList,
  SpotPatch,
  SpotsParams,
  Trip,
  UsageReport,
  Weather,
} from "./types";

// 서버에서 미리 그릴 때는 window 가 없어서 null 을 넘깁니다. 고르는 규칙은 lib/apiUrl.ts 에 있습니다.
export const API_URL = resolveApiUrl(
  process.env.NEXT_PUBLIC_API_URL,
  typeof window === "undefined" ? null : window.location.hostname,
);

/** 서버가 오류를 돌려줬을 때(또는 서버에 닿지 못했을 때) 던지는 오류. */
export class ApiError extends Error {
  status: number; // 서버에 닿지 못했으면 0
  constructor(status: number, message: string) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

/** 화면에 보여 줄 오류 문구를 만듭니다. */
export function errorMessage(error: unknown): string {
  if (error instanceof ApiError) return error.message;
  return "알 수 없는 오류가 났어요. 잠시 뒤 다시 시도해 주세요.";
}

// 모든 요청이 지나가는 한 곳. token 이 있으면 Authorization 헤더를, aiKey 가 있으면 X-Gemini-Key 헤더를 붙입니다.
async function request<T>(
  path: string,
  options: { method?: string; body?: unknown; token?: string | null; aiKey?: string | null } = {},
): Promise<T> {
  const headers: Record<string, string> = {};
  if (options.body !== undefined) headers["Content-Type"] = "application/json";
  if (options.token) headers.Authorization = `Bearer ${options.token}`;
  if (options.aiKey) headers["X-Gemini-Key"] = options.aiKey; // 내 AI 키(설정 화면). 서버는 이 요청에만 씁니다

  let response: Response;
  try {
    response = await fetch(`${API_URL}${path}`, {
      method: options.method ?? "GET",
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    });
  } catch {
    // 서버가 꺼져 있거나 주소가 틀리면 fetch 자체가 실패합니다.
    throw new ApiError(0, "서버에 연결할 수 없어요. 서버가 켜져 있는지 확인해 주세요.");
  }

  if (!response.ok) {
    let detail = `요청에 실패했어요 (${response.status})`;
    try {
      // 서버 오류는 { "detail": "설명" } 모양입니다. 입력값 검증 오류(422)는 배열이라 errorDetail.ts 가 한 줄로 바꿉니다.
      detail = detailText(await response.json()) ?? detail;
    } catch {
      /* 본문이 JSON 이 아니면 기본 문구를 씁니다 */
    }
    throw new ApiError(response.status, detail);
  }

  if (response.status === 204) return undefined as T;
  return (await response.json()) as T;
}

// ---------- 로그인 없이 쓰는 주소 ----------
export const getMeta = () => request<Meta>("/meta");
export const getSpots = (params: SpotsParams = {}) => request<SpotList>(`/spots${spotsQuery(params)}`);
export const getSpot = (id: number | string) => request<Spot>(`/spots/${id}`);
export const getWeather = () => request<Weather>("/weather");
/**
 * aiKey: 설정 화면에 넣은 내 AI 키. 있으면 그 키로, 없으면 서버의 기본 방식으로 일정을 짭니다.
 * token: 로그인 토큰. 함께 보내면 서버가 만든 일정을 "내 여행"에 자동으로 저장합니다(응답의 saved_trip).
 */
export const planTrip = (body: PlanRequest, options: { aiKey?: string | null; token?: string | null } = {}) =>
  request<PlanResponse>("/agent/plan", { method: "POST", body, ...options });
/** 내 AI 키가 쓸 수 있는 키인지 서버에 묻습니다. */
export const checkAiKey = (aiKey: string) => request<KeyCheck>("/agent/key-check", { method: "POST", aiKey });

// ---------- 로그인이 필요한 주소 (token = Supabase 액세스 토큰) ----------
// 목록 주소는 { items, next_cursor } 를 돌려줍니다. 다음 묶음은 next_cursor 를 cursor 에 넣어 다시 부릅니다.
export const getMe = (token: string) => request<Me>("/me", { token });
/** 내 AI 사용량(최근 days 일). */
export const getMyAiUsage = (token: string, days = 30) => request<UsageReport>(`/me/ai-usage${buildQuery({ days })}`, { token });
/** 전체 AI 사용량(관리자). by_user 가 함께 옵니다. */
export const getAdminAiUsage = (token: string, days = 30) =>
  request<UsageReport>(`/admin/ai-usage${buildQuery({ days })}`, { token });
export const getFavorites = (token: string, page: CursorParams = {}) =>
  request<CursorPage<Spot>>(`/me/favorites${buildQuery(page)}`, { token });
export const addFavorite = (token: string, spotId: number) =>
  request<{ spot_id: number }>("/me/favorites", { method: "POST", body: { spot_id: spotId }, token });
export const removeFavorite = (token: string, spotId: number) =>
  request<void>(`/me/favorites/${spotId}`, { method: "DELETE", token });
export const getTrips = (token: string, page: CursorParams = {}) =>
  request<CursorPage<Trip>>(`/me/trips${buildQuery(page)}`, { token });
export const saveTrip = (token: string, title: string, itinerary: Itinerary) =>
  request<Trip>("/me/trips", { method: "POST", body: { title, itinerary }, token });
export const deleteTrip = (token: string, id: number) =>
  request<void>(`/me/trips/${id}`, { method: "DELETE", token });

/**
 * 이 한 곳을 찜했는지 서버에 묻습니다. (상세 화면의 하트)
 * 찜 목록은 커서로 나뉘어 오므로, 목록을 끝까지 받아 찾지 않고 한 곳만 따로 묻습니다.
 */
export async function isFavorite(token: string, spotId: number): Promise<boolean> {
  const answer = await request<{ spot_id: number; favorite: boolean }>(`/me/favorites/${spotId}`, { token });
  return answer.favorite;
}

// ---------- 관리자 주소 (서버가 관리자인지 확인합니다. 아니면 403) ----------
export const getAdminUsers = (token: string, params: AdminUsersParams = {}) =>
  request<CursorPage<AdminUser>>(`/admin/users${buildQuery(params)}`, { token });
export const setUserSuspended = (token: string, userId: string, suspended: boolean) =>
  request<AdminUser>(`/admin/users/${userId}`, { method: "PATCH", body: { suspended }, token });
export const getAdminSpots = (token: string, params: AdminSpotsParams = {}) =>
  request<AdminSpotPage>(`/admin/spots${buildQuery(params)}`, { token });
export const createAdminSpot = (token: string, body: SpotCreate) =>
  request<AdminSpot>("/admin/spots", { method: "POST", body, token });
export const updateAdminSpot = (token: string, id: number, changes: SpotPatch) =>
  request<AdminSpot>(`/admin/spots/${id}`, { method: "PATCH", body: changes, token });
