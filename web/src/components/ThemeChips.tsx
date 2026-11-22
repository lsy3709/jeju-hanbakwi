// 테마 칩. selected 가 있으면 그 칩이 주황색으로 표시됩니다.
// 어느 폭에서든 줄을 바꿔 모두 보여 줍니다.
// (옆으로 넘기는 한 줄은 마우스로 넘길 수 없고, 폰에서도 뒤 칩이 화면 끝에서 잘려 보입니다)
import { chip } from "./ui";

type Props = { themes: string[]; selected?: string; onSelect: (theme: string) => void };

export function ThemeChips({ themes, selected, onSelect }: Props) {
  return (
    <div className="flex flex-wrap gap-2 py-1" role="group" aria-label="테마">
      {themes.map((theme) => (
        <button
          key={theme}
          type="button"
          aria-pressed={selected === theme}
          // 이미 선택된 칩을 다시 누르면 선택이 풀립니다(빈 글자 전달)
          onClick={() => onSelect(selected === theme ? "" : theme)}
          className={chip(selected === theme)}
        >
          {theme}
        </button>
      ))}
    </div>
  );
}
