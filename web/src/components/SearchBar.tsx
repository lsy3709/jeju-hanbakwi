"use client";

// "use client" 는 이 파일이 브라우저에서 도는 컴포넌트라는 표시입니다. 클릭에 반응하거나 useState 로 값을 기억하려면 필요합니다.
// 알약 모양 검색바. 확인(엔터)을 누르면 onSearch 로 글자를 넘깁니다.
import { useState } from "react";
import { Search } from "lucide-react";

// label: 화면 읽기 프로그램이 읽어 줄 입력칸 이름(관리자 화면처럼 관광지가 아닌 것을 찾을 때 바꿉니다).
// Props 는 이 컴포넌트가 받는 값의 모양입니다. "?" 가 붙은 값은 안 넘겨도 되고, 아래에서 기본값(= 뒤)이 쓰입니다.
type Props = { initial?: string; onSearch: (q: string) => void; placeholder?: string; label?: string };

export function SearchBar({
  initial = "",
  onSearch,
  placeholder = "관광지 이름이나 키워드를 검색해 보세요",
  label = "관광지 검색",
}: Props) {
  // 입력 중인 글자는 이 컴포넌트가 기억합니다. 검색이 확정되는 순간(엔터)에만 onSearch 로 부른 쪽에 알립니다.
  const [text, setText] = useState(initial);

  return (
    <form
      role="search"
      onSubmit={(event) => {
        event.preventDefault(); // 페이지가 새로고침되지 않게 막기
        onSearch(text.trim());
      }}
      className="flex items-center gap-2 rounded-pill border border-line bg-surface py-1.5 pl-4 pr-1.5 shadow-sm"
    >
      <Search size={18} className="text-muted" aria-hidden="true" />
      <input
        type="search"
        value={text}
        onChange={(event) => setText(event.target.value)}
        placeholder={placeholder}
        aria-label={label}
        className="min-w-0 flex-1 bg-transparent py-1.5 text-sm outline-none placeholder:text-muted"
      />
      <button
        type="submit"
        className="rounded-pill bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-primary-dark"
      >
        검색
      </button>
    </form>
  );
}
