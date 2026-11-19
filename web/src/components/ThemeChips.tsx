// 테마 칩 가로 스크롤. selected 가 있으면 그 칩이 주황색으로 표시됩니다.
import { chip } from "./ui";

type Props = { themes: string[]; selected?: string; onSelect: (theme: string) => void };

export function ThemeChips({ themes, selected, onSelect }: Props) {
  return (
    <div className="no-scrollbar -mx-4 flex gap-2 overflow-x-auto px-4 py-1" role="group" aria-label="테마">
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
