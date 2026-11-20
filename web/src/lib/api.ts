// 이 파일이 하는 일: 서버(FastAPI)와 통하는 유일한 문입니다.
// 화면은 fetch 를 직접 부르지 않고 여기 함수만 씁니다. 새 서버 주소를 쓰려면 여기에 함수를 하나 더하세요.
// 주소·응답 모양은 docs/api.md 를 따릅니다.
import { spotsQuery } from "./format";
import type {
  Meta,
  Spot,
  SpotList,
  SpotsParams,
  Weather,
} from "./types";

export const API_URL = (process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000").replace(/\/$/, "");

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

// 모든 요청이 지나가는 한 곳.
async function request<T>(
  path: string,
  options: { method?: string; body?: unknown } = {},
): Promise<T> {
  const headers: Record<string, string> = {};
  if (options.body !== undefined) headers["Content-Type"] = "application/json";

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
      const data = await response.json();
      // 서버 오류는 { "detail": "설명" } 모양입니다. (검증 오류는 배열일 수 있어 문자열일 때만 씁니다)
      if (typeof data?.detail === "string") detail = data.detail;
    } catch {
      /* 본문이 JSON 이 아니면 기본 문구를 씁니다 */
    }
    throw new ApiError(response.status, detail);
  }

  if (response.status === 204) return undefined as T;
  return (await response.json()) as T;
}

// ---------- 서버 주소 ----------
export const getMeta = () => request<Meta>("/meta");
export const getSpots = (params: SpotsParams = {}) => request<SpotList>(`/spots${spotsQuery(params)}`);
export const getSpot = (id: number | string) => request<Spot>(`/spots/${id}`);
export const getWeather = () => request<Weather>("/weather");
