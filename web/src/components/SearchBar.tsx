"use client";

// 알약 모양 검색바. 확인(엔터)을 누르면 onSearch 로 글자를 넘깁니다.
import { useState } from "react";
import { Search } from "lucide-react";

// label: 화면 읽기 프로그램이 읽어 줄 입력칸 이름(관리자 화면처럼 관광지가 아닌 것을 찾을 때 바꿉니다).
type Props = { initial?: string; onSearch: (q: string) => void; placeholder?: string; label?: string };

export function SearchBar({
  initial = "",
  onSearch,
  placeholder = "관광지 이름이나 키워드를 검색해 보세요",
  label = "관광지 검색",
}: Props) {
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
