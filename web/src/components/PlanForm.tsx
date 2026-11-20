// 이 파일이 하는 일: AI 플래너의 입력 폼(하고 싶은 여행 · 일수 · 동행 · 시작 날짜 · "일정 짜기" 버튼). 값은 위에서 받고, 바뀌면 알려 줄 뿐입니다.
import { Loader2, Sparkles } from "lucide-react";
import { btnPrimary, chip, inputClass } from "@/components/ui";
import { todayString } from "@/lib/format";
import type { PlanInput } from "@/lib/types";

const COMPANIONS = ["혼자", "친구", "연인", "아이와", "부모님"];

export function PlanForm({
  input,
  onChange,
  onSubmit,
  planning,
}: {
  input: PlanInput;
  onChange: (changes: Partial<PlanInput>) => void;
  onSubmit: () => void;
  planning: boolean;
}) {
  return (
    <form
      onSubmit={(event) => {
        event.preventDefault();
        onSubmit();
      }}
      className="space-y-5 rounded-card border border-line bg-surface p-5"
    >
      <label className="block space-y-2">
        <span className="font-semibold">하고 싶은 여행</span>
        <textarea
          value={input.message}
          onChange={(event) => onChange({ message: event.target.value })}
          maxLength={500}
          rows={3}
          required
          placeholder="예) 부모님과 많이 걷지 않는 코스로 다녀오고 싶어요"
          className="w-full rounded-card border border-line bg-surface px-4 py-3 text-sm placeholder:text-muted"
        />
      </label>

      <fieldset className="space-y-2">
        <legend className="font-semibold">며칠 가나요?</legend>
        <div className="flex gap-2">
          {[1, 2, 3].map((n) => (
            <button key={n} type="button" aria-pressed={input.days === n} onClick={() => onChange({ days: n })} className={chip(input.days === n)}>
              {n}일
            </button>
          ))}
        </div>
      </fieldset>

      <fieldset className="space-y-2">
        <legend className="font-semibold">누구와 가나요? (선택)</legend>
        <div className="flex flex-wrap gap-2">
          {COMPANIONS.map((name) => (
            <button
              key={name}
              type="button"
              aria-pressed={input.companions === name}
              // 같은 칩을 다시 누르면 선택이 풀립니다
              onClick={() => onChange({ companions: input.companions === name ? "" : name })}
              className={chip(input.companions === name)}
            >
              {name}
            </button>
          ))}
        </div>
      </fieldset>

      <label className="block space-y-2">
        <span className="font-semibold">시작 날짜 (선택)</span>
        <input
          type="date"
          value={input.startDate}
          min={todayString()}
          onChange={(event) => onChange({ startDate: event.target.value })}
          className={`${inputClass} sm:w-56`}
        />
      </label>

      <button type="submit" disabled={planning || !input.message.trim()} className={btnPrimary}>
        {planning ? <Loader2 className="animate-spin" size={18} aria-hidden="true" /> : <Sparkles size={18} aria-hidden="true" />}
        {planning ? "일정을 짜는 중이에요..." : "일정 짜기"}
      </button>
    </form>
  );
}
