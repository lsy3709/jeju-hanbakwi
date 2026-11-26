// 판타지 지도의 낮과 밤을 정하는 순수 함수입니다. 제주 시각에 따라 하늘 색과 빛의 세기를 바꿉니다.

/** 하늘을 정하는 방식. auto 는 지금 제주 시각을 따르고, day · night 는 그 모습으로 고정합니다. */
export type SkyMode = "auto" | "day" | "night";

/** 지금 제주가 몇 시인지(0 이상 24 미만, 30분은 0.5). 보는 사람의 PC 시각이 아니라 한국 시간으로 셉니다. */
export function jejuHour(now: Date): number {
  const hours = now.getUTCHours() + now.getUTCMinutes() / 60 + 9; // 한국은 세계 표준시 + 9시간
  return hours % 24;
}

/** 얼마나 낮인지. 0 은 밤, 1 은 낮. 새벽(5 ~ 7시)과 저녁(18 ~ 20시)에는 그 사이 값으로 서서히 바뀝니다. */
export function dayness(hour: number): number {
  if (hour >= 7 && hour <= 18) return 1;
  if (hour > 5 && hour < 7) return (hour - 5) / 2;
  if (hour > 18 && hour < 20) return (20 - hour) / 2;
  return 0;
}

/** 방식에 따른 "얼마나 낮인지". */
export function daynessOf(mode: SkyMode, now: Date): number {
  if (mode === "day") return 1;
  if (mode === "night") return 0;
  return dayness(jejuHour(now));
}

/** 밤 색과 낮 색을 섞습니다. t 가 0 이면 밤 색, 1 이면 낮 색. 색은 0xRRGGBB 숫자입니다. */
export function mixColor(night: number, day: number, t: number): number {
  const mix = (shift: number) => {
    const a = (night >> shift) & 0xff;
    const b = (day >> shift) & 0xff;
    return Math.round(a + (b - a) * t) << shift;
  };
  return mix(16) | mix(8) | mix(0);
}

/** 전환 단추를 누를 때마다: 지금 시각 → 낮 → 밤 → 지금 시각. */
export function nextSkyMode(mode: SkyMode): SkyMode {
  return mode === "auto" ? "day" : mode === "day" ? "night" : "auto";
}

/** 전환 단추에 보일 글자. */
export function skyLabel(mode: SkyMode): string {
  return mode === "auto" ? "지금 시각" : mode === "day" ? "낮" : "밤";
}
