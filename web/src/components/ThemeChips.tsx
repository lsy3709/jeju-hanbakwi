// 테마 칩. selected 가 있으면 그 칩이 주황색으로 표시됩니다.
// 폰: 한 줄로 두고 옆으로 밉니다. 태블릿·PC(md 이상): 줄을 바꿔 모두 보여 줍니다.
// (스크롤바를 숨긴 한 줄은 마우스로 넘길 수 없어, 창이 좁으면 뒤 칩이 잘린 채 남습니다)
import { chip } from "./ui";

type Props = { themes: string[]; selected?: string; onSelect: (theme: string) => void };

export function ThemeChips({ themes, selected, onSelect }: Props) {
  return (
    <div className="no-scrollbar -mx-4 flex gap-2 overflow-x-auto px-4 py-1 md:mx-0 md:flex-wrap md:overflow-visible md:px-0" role="group" aria-label="테마">
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
