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

export type SpotList = { items: Spot[]; total: number; page: number; size: number };

export type SpotsParams = {
  q?: string;
  theme?: string;
  area?: string;
  category?: string;
  indoor?: boolean;
  page?: number;
  size?: number;
};

export type WeatherDay = {
  date: string;
  label: string;
  icon: "sun" | "cloud" | "rain" | "snow" | "fog";
  temp_min: number;
  temp_max: number;
  rain_prob: number;
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

export type PlanResponse = {
  mode: "ai" | "rule";
  answer: string;
  itinerary: Itinerary;
  sources: Spot[];
};

export type Me = { id: string; email: string };

export type Trip = {
  id: number;
  title: string;
  itinerary: Itinerary;
  created_at: string;
};
