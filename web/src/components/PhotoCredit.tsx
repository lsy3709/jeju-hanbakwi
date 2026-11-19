import type { Spot } from "@/lib/types";
import { photoCreditText } from "@/lib/format";

/** 큰 사진 바로 아래의 작은 출처 표시. 공개 라이선스 사진은 출처를 보여 줘야 쓸 수 있습니다. */
export function PhotoCredit({ spot }: { spot: Spot }) {
  const text = photoCreditText(spot);
  if (!text) return null;
  const className = "text-xs text-muted";
  // 원본 주소가 있으면 글자 전체를 새 탭 링크로 (noopener: 새 탭이 이 창을 조작하지 못하게)
  if (spot.image_source_url) {
    return (
      <a
        href={spot.image_source_url}
        target="_blank"
        rel="noopener noreferrer"
        className={`${className} block hover:underline`}
      >
        {text}
      </a>
    );
  }
  return <p className={className}>{text}</p>;
}
