"use client";

// 알약 모양 검색바. 글자는 입력되지만 확인(엔터)을 눌러도 아무 일도 일어나지 않습니다.
// 2일차에 탐색 화면을 만들면 여기서 그 화면으로 이동하게 됩니다.
import { useState } from "react";
import { Search } from "lucide-react";

export function SearchBar({ placeholder = "관광지 이름이나 키워드를 검색해 보세요" }: { placeholder?: string }) {
  const [text, setText] = useState("");

  return (
    <form
      role="search"
      onSubmit={(event) => {
        event.preventDefault(); // 페이지가 새로고침되지 않게 막기 (이동은 아직 없음)
      }}
      className="flex items-center gap-2 rounded-pill border border-line bg-surface py-1.5 pl-4 pr-1.5 shadow-sm"
    >
      <Search size={18} className="text-muted" aria-hidden="true" />
      <input
        type="search"
        value={text}
        onChange={(event) => setText(event.target.value)}
        placeholder={placeholder}
        aria-label="관광지 검색"
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
