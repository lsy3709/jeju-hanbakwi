// 여러 화면에서 반복해서 쓰는 Tailwind 클래스 묶음. 버튼·칩 모양을 바꾸려면 여기만 고치세요.

// 이 파일이 하는 일: 버튼·칩·카드의 Tailwind 클래스 이름을 문자열로 한 번만 적어 두고 여러 컴포넌트가 가져다 씁니다. 색 이름(primary, line, sand …)은 app/globals.css 의 @theme 이 정한 디자인 토큰입니다.
const base =
  "inline-flex items-center justify-center gap-2 rounded-pill px-5 py-2.5 text-sm font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-50";

export const btnPrimary = `${base} bg-primary text-white hover:bg-primary-dark`;
export const btnOutline = `${base} border border-line bg-surface text-ink hover:bg-sand`;

/** 칩(테마·필터 선택). selected 면 주황색으로 채워집니다. */
// selected 값에 따라 클래스 글자를 다르게 만들어 돌려줍니다. 사용: className={chip(true)}
export function chip(selected: boolean) {
  return `inline-flex shrink-0 items-center rounded-pill border px-4 py-2 text-sm font-medium transition-colors ${
    selected
      ? "border-primary bg-primary text-white"
      : "border-line bg-surface text-ink hover:border-primary"
  }`;
}

/** 표 안처럼 좁은 곳에 쓰는 작은 테두리 버튼(관리자 화면) */
export const btnSmall =
  "inline-flex min-h-9 shrink-0 items-center justify-center gap-1 rounded-pill border border-line bg-surface px-3 py-1.5 text-xs font-semibold text-ink transition-colors hover:bg-sand disabled:cursor-not-allowed disabled:opacity-50";

export const card = "rounded-card border border-line bg-surface";
export const inputClass =
  "w-full rounded-pill border border-line bg-surface px-4 py-2.5 text-sm placeholder:text-muted";
