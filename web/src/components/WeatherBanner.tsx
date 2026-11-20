// 홈의 날씨 배너. 데이터는 부모(홈)가 불러와서 넘겨 줍니다.
import Link from "next/link";
import { Cloud, CloudFog, CloudRain, Snowflake, Sun, type LucideIcon } from "lucide-react";
import { weatherText } from "@/lib/format";
import type { Weather, WeatherDay } from "@/lib/types";
import { btnPrimary } from "./ui";

const ICONS: Record<WeatherDay["icon"], LucideIcon> = {
  sun: Sun,
  cloud: Cloud,
  rain: CloudRain,
  snow: Snowflake,
  fog: CloudFog,
};

export function WeatherBanner({ weather }: { weather: Weather }) {
  return (
    <section
      aria-label="오늘의 제주 날씨"
      className={`space-y-3 rounded-card border p-5 ${
        weather.rainy_today ? "border-teal-200 bg-teal-50" : "border-orange-200 bg-orange-50"
      }`}
    >
      <p className="font-semibold">{weather.message}</p>
      <ul className="flex flex-wrap gap-x-6 gap-y-2">
        {weather.areas.map(({ area, days }) => {
          const today = days[0]; // days 는 오늘부터 4일이라 첫 번째가 오늘
          if (!today) return null;
          const Icon = ICONS[today.icon] ?? Cloud;
          return (
            <li key={area} className="flex items-center gap-2 text-sm">
              <Icon size={20} aria-hidden="true" />
              <span className="font-semibold">{area}</span>
              <span>{today.label}</span>
              <span className="text-muted">{weatherText(today)}</span>
            </li>
          );
        })}
      </ul>
      {weather.rainy_today && (
        <Link href="/explore?indoor=true" className={btnPrimary}>
          실내 코스 보기
        </Link>
      )}
    </section>
  );
}
