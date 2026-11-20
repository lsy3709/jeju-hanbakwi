// 여러 곳에서 반복해서 쓰는 Tailwind 클래스 묶음. 칩 모양을 바꾸려면 여기만 고치세요.

/** 칩(테마 선택). selected 면 주황색으로 채워집니다. */
export function chip(selected: boolean) {
  return `inline-flex shrink-0 items-center rounded-pill border px-4 py-2 text-sm font-medium transition-colors ${
    selected
      ? "border-primary bg-primary text-white"
      : "border-line bg-surface text-ink hover:border-primary"
  }`;
}
