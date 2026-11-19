// 여러 화면에서 반복해서 쓰는 Tailwind 클래스 묶음. 버튼·칩 모양을 바꾸려면 여기만 고치세요.

const base =
  "inline-flex items-center justify-center gap-2 rounded-pill px-5 py-2.5 text-sm font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-50";

export const btnPrimary = `${base} bg-primary text-white hover:bg-primary-dark`;
export const btnOutline = `${base} border border-line bg-surface text-ink hover:bg-sand`;

/** 칩(테마·필터 선택). selected 면 주황색으로 채워집니다. */
export function chip(selected: boolean) {
  return `inline-flex shrink-0 items-center rounded-pill border px-4 py-2 text-sm font-medium transition-colors ${
    selected
      ? "border-primary bg-primary text-white"
      : "border-line bg-surface text-ink hover:border-primary"
  }`;
}

export const card = "rounded-card border border-line bg-surface";
export const inputClass =
  "w-full rounded-pill border border-line bg-surface px-4 py-2.5 text-sm placeholder:text-muted";
