// 첫 화면: 인사 + 한 줄 소개 + 검색바 → 테마 칩
import { SearchBar } from "@/components/SearchBar";
import { ThemeChips } from "@/components/ThemeChips";
import { BRAND } from "@/lib/brand";

const THEMES = ["바다", "오름", "숲", "폭포", "카페", "드라이브"];

export default function HomePage() {
  return (
    <div className="space-y-8">
      <section className="space-y-4 pt-2">
        <h1 className="text-3xl font-extrabold md:text-4xl">{BRAND.greeting}</h1>
        <p className="text-muted">{BRAND.description}</p>
        <SearchBar />
      </section>

      <section aria-label="테마" className="space-y-3">
        <h2 className="text-lg font-bold">테마로 찾기</h2>
        <ThemeChips themes={THEMES} />
      </section>
    </div>
  );
}
