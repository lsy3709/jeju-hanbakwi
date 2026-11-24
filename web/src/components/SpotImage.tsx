"use client";

// "use client" 는 이 파일이 브라우저에서 도는 컴포넌트라는 표시입니다. 클릭에 반응하거나 useState 로 값을 기억하려면 필요합니다. 사진 불러오기 실패를 기억(useState)하기 때문입니다.
// 관광지 사진. 주소가 없거나(null) 불러오기에 실패하면 테마 색의 "대체 그림"을 보여 줍니다.
import { useState } from "react";
import { Mountain, Sun, Waves, type LucideIcon } from "lucide-react";
import { pickFallbackTone, type FallbackTone } from "@/lib/format";

// 대체 그림의 색 계열(바다·초록·모래)과 아이콘을 짝지어 둔 표입니다. 색 이름은 Tailwind 가 제공하는 색입니다.
const TONES: Record<FallbackTone, { bg: string; Icon: LucideIcon }> = {
  sea: { bg: "bg-linear-to-br from-teal-100 to-cyan-300 text-teal-700", Icon: Waves },
  green: { bg: "bg-linear-to-br from-lime-100 to-emerald-300 text-emerald-800", Icon: Mountain },
  sand: { bg: "bg-linear-to-br from-orange-100 to-amber-200 text-orange-700", Icon: Sun },
};

type Props = {
  imageUrl: string | null;
  title: string;
  tags: string[];
  className?: string; // 크기·비율은 부르는 쪽에서 정합니다
};

// 사진 주소가 있고 불러오기에 실패하지 않았으면 사진을, 아니면 테마 색의 대체 그림을 그립니다.
export function SpotImage({ imageUrl, title, tags, className = "" }: Props) {
  // "어떤 주소가 실패했는지"를 기억해 두면, 주소가 바뀔 때 따로 초기화하지 않아도 됩니다.
  const [failedUrl, setFailedUrl] = useState<string | null>(null);

  if (imageUrl && failedUrl !== imageUrl) {
    return (
      <img
        src={imageUrl}
        alt={title}
        loading="lazy"
        onError={() => setFailedUrl(imageUrl)}
        className={`object-cover ${className}`}
      />
    );
  }

  const { bg, Icon } = TONES[pickFallbackTone(tags)];
  return (
    <div role="img" aria-label={`${title} (사진 없음)`} className={`flex items-center justify-center ${bg} ${className}`}>
      <Icon size={36} aria-hidden="true" />
    </div>
  );
}
