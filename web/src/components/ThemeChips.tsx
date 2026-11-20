// 테마 칩 가로 줄. 모양만 있고, 눌러도 이동하지 않습니다.
// 2일차에 탐색 화면을 만들면 여기서 그 화면으로 이동하게 됩니다.
import { chip } from "./ui";

export function ThemeChips({ themes }: { themes: string[] }) {
  return (
    <div className="no-scrollbar -mx-4 flex gap-2 overflow-x-auto px-4 py-1" role="group" aria-label="테마">
      {themes.map((theme) => (
        <button key={theme} type="button" className={chip(false)}>
          {theme}
        </button>
      ))}
    </div>
  );
}
