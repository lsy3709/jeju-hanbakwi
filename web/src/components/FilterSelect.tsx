// 이 파일이 하는 일: 탐색 화면의 "지역 / 분류" 같은 드롭다운 하나(맨 위 선택지는 "전체").

// 컴포넌트 = 화면 조각을 그려 돌려주는 함수입니다. 중괄호 안의 이름들(props)은 부르는 쪽이 넘겨 주는 값입니다.
// 받는 값: label(앞에 붙는 이름), value(지금 고른 값), options(고를 수 있는 목록), onChange(고르면 부를 함수). 값을 직접 바꾸지 않고 부른 쪽에 알리기만 합니다.
export function FilterSelect({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: string[];
  onChange: (value: string) => void;
}) {
  return (
    <label className="flex items-center gap-2 text-sm">
      <span className="text-muted">{label}</span>
      <select
        value={value}
        // 고른 글자(event.target.value)를 부른 쪽에 알립니다. 주소의 쿼리를 바꾸는 일은 탐색 화면이 합니다.
        onChange={(event) => onChange(event.target.value)}
        className="rounded-pill border border-line bg-surface px-3 py-2 text-sm"
      >
        <option value="">전체</option>
        {options.map((option) => (
          <option key={option} value={option}>
            {option}
          </option>
        ))}
      </select>
    </label>
  );
}
