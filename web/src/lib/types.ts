// docs/api.md 의 "자료 모양"을 그대로 옮긴 타입입니다. (임시 데이터 sample-spots.json 도 이 모양입니다)

export type Spot = {
  id: number;
  title: string;
  category: string;
  area: string;
  address: string;
  lat: number;
  lng: number;
  image_url: string | null; // 사진이 없으면 null → 대체 그림
  image_credit: string | null; // 사진 저작자·라이선스. 있으면 상세에서 반드시 표시
  image_source_url: string | null; // 사진 원본 설명 쪽 주소
  overview: string;
  one_liner: string;
  theme_tags: string[];
  indoor: boolean;
};
