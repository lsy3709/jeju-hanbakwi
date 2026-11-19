# API 명세 — 제주 한 바퀴

웹(Next.js)과 앱(Flutter)이 함께 쓰는 약속입니다. 서버(FastAPI)는 이 문서대로 응답합니다.

- 로컬 주소: `http://localhost:8000` (안드로이드 에뮬레이터에서는 `http://10.0.2.2:8000`)
- 직접 눌러 보기: `http://localhost:8000/docs`
- 모든 응답은 JSON, 오류는 `{ "detail": "설명" }`
- 로그인이 필요한 주소는 `Authorization: Bearer <Supabase 액세스 토큰>` 헤더가 있어야 하고, 없거나 틀리면 `401`

## 자료 모양

### Spot (관광지)

```json
{
  "id": 1,
  "title": "성산일출봉",
  "category": "관광지",
  "area": "동부",
  "address": "제주특별자치도 서귀포시 성산읍 일출로 284-12",
  "lat": 33.4581,
  "lng": 126.9426,
  "image_url": null,
  "image_credit": null,
  "image_source_url": null,
  "overview": "긴 소개 글",
  "one_liner": "한 줄 소개",
  "theme_tags": ["오름", "바다", "사진"],
  "indoor": false
}
```

- `image_url` 은 `null` 일 수 있습니다(화면은 대체 그림을 보여 줍니다). 값이 있으면 항상 `http` 로 시작하는 완성된 주소입니다. 우리 서버에 있는 사진은 요청이 들어온 서버 주소가 앞에 붙어 옵니다(예: `http://localhost:8000/photos/S001.jpg`, 에뮬레이터에서는 `http://10.0.2.2:8000/photos/S001.jpg`).
- `image_credit` 은 사진의 저작자와 라이선스입니다(예: `"홍길동 · CC BY-SA 4.0"`). 값이 있으면 **상세 화면의 사진 아래에 반드시 보여 줍니다.** `image_source_url` 이 있으면 그 글자를 원본 쪽으로 가는 링크로 만듭니다. 둘 다 `null` 일 수 있습니다.
- `category`: 관광지 · 문화시설 · 축제 · 레포츠 · 쇼핑 · 음식점
- `area`: 제주시 · 서귀포시 · 동부 · 서부

### Itinerary (일정)

```json
[
  {
    "day": 1,
    "date": "2026-12-01",
    "weather": "비",
    "items": [
      { "time": "오전", "spot_id": 12, "title": "아쿠아플라넷 제주", "reason": "비가 와도 즐길 수 있는 실내 코스" }
    ]
  }
]
```

- `time`: 오전 · 점심 · 오후 · 저녁
- `date`, `weather` 는 `null` 일 수 있습니다.

## 주소 목록

| 방법 | 주소 | 로그인 | 설명 |
|---|---|---|---|
| GET | `/health` | - | `{ "status": "ok" }` |
| GET | `/meta` | - | 화면에서 쓰는 선택지 |
| GET | `/spots` | - | 관광지 목록 |
| GET | `/spots/{id}` | - | 관광지 한 곳 (없으면 404) |
| GET | `/weather` | - | 제주시·서귀포시 오늘부터 4일 날씨 |
| POST | `/agent/plan` | - | AI 일정 짜기 |
| GET | `/me` | 필요 | 로그인한 사용자 |
| GET | `/me/favorites` | 필요 | 찜한 관광지 목록 |
| POST | `/me/favorites` | 필요 | 찜 추가 |
| DELETE | `/me/favorites/{spot_id}` | 필요 | 찜 삭제 |
| GET | `/me/trips` | 필요 | 저장한 일정 목록 |
| POST | `/me/trips` | 필요 | 일정 저장 |
| DELETE | `/me/trips/{id}` | 필요 | 일정 삭제 |

### GET /meta

```json
{
  "themes": ["바다", "오름", "숲", "폭포", "박물관", "체험", "카페", "시장", "역사", "아이와", "사진", "드라이브"],
  "areas": ["제주시", "서귀포시", "동부", "서부"],
  "categories": ["관광지", "문화시설", "축제", "레포츠", "쇼핑", "음식점"]
}
```

### GET /spots

쿼리(모두 선택):

| 이름 | 예 | 뜻 |
|---|---|---|
| `q` | `폭포` | 이름·한 줄 소개에서 찾기 |
| `theme` | `바다` | 테마 태그 하나 |
| `area` | `동부` | 지역 |
| `category` | `관광지` | 분류 |
| `indoor` | `true` / `false` | 실내 / 실외 |
| `page` | `1` | 쪽 번호(1부터) |
| `size` | `20` | 한 쪽 개수(1~50, 기본 20) |

응답:

```json
{ "items": [ Spot, ... ], "total": 42, "page": 1, "size": 20 }
```

### GET /weather

```json
{
  "rainy_today": true,
  "message": "오늘 제주는 비 소식이 있어요. 실내 코스를 추천해요.",
  "areas": [
    {
      "area": "제주시",
      "days": [
        { "date": "2026-12-01", "label": "비", "icon": "rain", "temp_min": 8.1, "temp_max": 12.4, "rain_prob": 80 }
      ]
    },
    { "area": "서귀포시", "days": [ ... ] }
  ]
}
```

- `icon`: `sun` · `cloud` · `rain` · `snow` · `fog`
- `days` 는 오늘부터 4일. 날씨 서비스가 응답하지 않으면 `503`.

### POST /agent/plan

요청:

```json
{ "message": "부모님과 2박 3일, 많이 걷지 않는 코스", "days": 2, "companions": "부모님", "start_date": "2026-12-01" }
```

- `message` 필수(1~500자). `days` 1~3(기본 2). `companions`, `start_date` 는 선택.

응답:

```json
{
  "mode": "ai",
  "answer": "짧은 설명 글",
  "itinerary": [ ... Itinerary ... ],
  "sources": [ Spot, ... ]
}
```

- `mode`: `ai`(AI 가 짠 일정) 또는 `rule`(AI 를 쓸 수 없을 때 규칙으로 짠 일정). 화면은 `rule` 일 때 "간단 추천" 표시를 붙입니다.
- `sources` 는 일정에 나온 관광지입니다. 일정의 `spot_id` 는 항상 `sources` 안에 있습니다.

### GET /me

```json
{ "id": "사용자 UUID", "email": "user@example.com" }
```

### 찜

- `GET /me/favorites` → `[ Spot, ... ]` (최근에 찜한 순)
- `POST /me/favorites` 요청 `{ "spot_id": 12 }` → `201` `{ "spot_id": 12 }` (이미 찜했어도 201, 없는 관광지면 404)
- `DELETE /me/favorites/12` → `204` (본문 없음)

### 저장한 일정

- `GET /me/trips` → `[ { "id": 3, "title": "부모님과 제주", "itinerary": [ ... ], "created_at": "2026-12-01T03:00:00+00:00" } ]`
- `POST /me/trips` 요청 `{ "title": "부모님과 제주", "itinerary": [ ... ] }` → `201` 저장된 일정
- `DELETE /me/trips/3` → `204` (내 일정이 아니면 404)
