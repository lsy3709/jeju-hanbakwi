// 서비스 이름과 문구를 한 곳에 모았습니다. 브랜드를 바꾸려면 여기만 고치세요.
// 이 파일이 하는 일: 서비스 이름·문구·메뉴 목록을 한 곳에 둡니다. Header.tsx 와 각 화면이 여기서 가져다 씁니다.
// "as const" 는 값이 바뀌지 않는 고정 목록이라고 알려 줘서, 메뉴 이름을 오타 없이 쓰게 도와 줍니다.
export const BRAND = {
  name: "제주 한 바퀴",
  tagline: "AI와 함께 짜는 나만의 제주 여행",
  description:
    "날씨와 취향에 맞는 제주 관광지를 찾고, AI가 일자별 여행 일정을 짜 드려요.",
  greeting: "어디로 한 바퀴 돌까요?",
};

// 상단 메뉴·하단 탭에서 함께 쓰는 메뉴 목록
export const NAV_ITEMS = [
  { href: "/", label: "홈", icon: "home" },
  { href: "/explore", label: "탐색", icon: "compass" },
  { href: "/planner", label: "AI 플래너", icon: "sparkles" },
  { href: "/my", label: "내 여행", icon: "heart" },
] as const;

// 관리자(/me 의 is_admin)에게만 메뉴 끝에 더해 보이는 항목. 숨기는 것은 편의일 뿐, 막는 일은 서버가 합니다.
export const ADMIN_NAV_ITEM = { href: "/admin", label: "관리자", icon: "shield" } as const;
