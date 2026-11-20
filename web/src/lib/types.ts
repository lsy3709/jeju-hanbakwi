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
  temp_min: number | null; // 서버가 값을 못 구하면 null
  temp_max: number | null;
  rain_prob: number | null;
};

export type Weather = {
  rainy_today: boolean;
  message: string;
  areas: { area: string; days: WeatherDay[] }[];
};
