# API 명세 — 제주 한 바퀴

웹(Next.js)과 앱(Flutter)이 함께 쓰는 약속입니다. 서버(FastAPI)는 이 문서대로 응답합니다.

- 로컬 주소: `http://localhost:8000` (안드로이드 에뮬레이터에서는 `http://10.0.2.2:8000`)
- 직접 눌러 보기: `http://localhost:8000/docs`
- 모든 응답은 JSON, 오류는 `{ "detail": "설명" }`
- 로그인이 필요한 주소는 `Authorization: Bearer <Supabase 액세스 토큰>` 헤더가 있어야 하고, 없거나 틀리면 `401`
- 목록을 주는 주소는 모두 **커서 방식**으로 나눠 줍니다 → 아래 "목록을 나눠 받기"

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

## 목록을 나눠 받기 — 커서 페이징

목록 주소(`/spots`, `/me/favorites`, `/me/trips`, `/admin/users`, `/admin/spots`)는 같은 약속을 씁니다.

| 쿼리 | 뜻 |
|---|---|
| `size` | 한 번에 받을 개수(1~50, 기본 20) |
| `cursor` | 앞 응답의 `next_cursor`. 처음에는 보내지 않습니다 |

응답에는 `items` 와 `next_cursor` 가 있습니다. `next_cursor` 가 `null` 이면 끝입니다. 숫자면 그 값을 `cursor` 에 넣어 다시 부르면 이어지는 묶음이 옵니다.

```
GET /spots?size=20              → { "items": [1번 ~ 20번], "next_cursor": 20, "total": 68, ... }
GET /spots?size=20&cursor=20    → { "items": [21번 ~ 40번], "next_cursor": 40, "total": null, ... }
...
GET /spots?size=20&cursor=60    → { "items": [61번 ~ 68번], "next_cursor": null, "total": null, ... }
```

- 커서는 "마지막으로 받은 줄의 번호"입니다. 화면은 뜻을 풀지 말고 받은 값을 그대로 돌려보냅니다.
- 필터(`q`, `theme` 등)는 이어지는 요청에도 똑같이 붙입니다. 필터가 바뀌면 커서를 버리고 처음부터 받습니다.
- `total`(전체 개수)은 첫 묶음에서만 옵니다. 이어지는 묶음에서는 `null` 이므로, 화면은 첫 응답의 값을 기억해 둡니다.
- 쪽 번호(`page=3`) 방식을 쓰지 않는 이유: 쪽 번호는 "앞의 40개를 건너뛰고"로 찾기 때문에 뒤로 갈수록 느려지고, 보는 사이에 줄이 더해지거나 빠지면 같은 줄이 두 번 나오거나 한 줄을 건너뜁니다. 커서는 "20번 다음부터"로 찾으므로 그런 일이 없습니다.

## 주소 목록

| 방법 | 주소 | 로그인 | 설명 |
|---|---|---|---|
| GET | `/health` | - | `{ "status": "ok" }` |
| GET | `/status` | - | 무엇이 연결됐는지 (운영 확인용) |
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
| GET | `/admin/users` | 관리자 | 사용자 목록(찜 수 · 일정 수) |
| PATCH | `/admin/users/{id}` | 관리자 | 이용 정지 / 해제 |
| GET | `/admin/spots` | 관리자 | 여행지 목록(숨긴 곳 포함) |
| POST | `/admin/spots` | 관리자 | 여행지 추가 |
| PATCH | `/admin/spots/{id}` | 관리자 | 여행지 수정 · 숨김 |

### GET /status

배포한 뒤 문제가 생기면 가장 먼저 여는 주소입니다. 키 값은 나오지 않고 "있다/없다"만 나옵니다.

```json
{ "database": "ok", "spots": 68, "ai": "ai", "login": "on", "photos": 55 }
```

- `database`: `ok` 또는 `error`(DB 주소·키가 틀렸거나 테이블이 없음). `error` 면 `spots` 는 `null`.
- `spots`: 관광지 수. `0` 이면 데이터를 아직 넣지 않은 것.
- `ai`: `ai`(AI 키가 있어 AI 로 일정을 짬) 또는 `rule`(키가 없어 규칙으로만 짬).
- `login`: `on` 또는 `off`(Supabase 설정이 비어 있음).
- `photos`: 서버에 들어 있는 사진 수.

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
| `cursor` | `20` | 앞 응답의 `next_cursor`(처음에는 보내지 않음) |
| `size` | `20` | 한 번에 받을 개수(1~50, 기본 20) |

응답:

```json
{ "items": [ Spot, ... ], "next_cursor": 20, "total": 42, "size": 20 }
```

- 번호(`id`)가 작은 순으로 옵니다. 관리자가 숨긴 곳은 목록에도 상세(`/spots/{id}` → 404)에도 나오지 않습니다.

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
- 하루 안의 항목은 오전 → 점심 → 오후 → 저녁 순으로 옵니다.
- 글에서 말한 관광지는 먼저 넣습니다(규칙 방식은 하루 3곳까지). 다 넣지 못하면 `answer` 에 넣지 못한 곳을 적어 줍니다.

### GET /me

```json
{ "id": "사용자 UUID", "email": "user@example.com", "is_admin": false, "suspended": false }
```

- `is_admin`: 관리자면 `true`. 화면은 이 값으로 관리자 메뉴를 보일지 정합니다(막는 일은 서버가 합니다).
- `suspended`: 이용 정지된 계정이면 `true`. 정지된 계정은 찜 · 일정 주소가 모두 `403` 입니다. `/me` 와 누구나 보는 주소는 그대로 됩니다.

### 찜

- `GET /me/favorites?size=20&cursor=` → `{ "items": [ Spot, ... ], "next_cursor": 31 }` (최근에 찜한 순. 숨긴 곳은 빠짐)
- `POST /me/favorites` 요청 `{ "spot_id": 12 }` → `201` `{ "spot_id": 12 }` (이미 찜했어도 201, 없는 관광지면 404)
- `DELETE /me/favorites/12` → `204` (본문 없음)

### 저장한 일정

- `GET /me/trips?size=20&cursor=` → `{ "items": [ { "id": 3, "title": "부모님과 제주", "itinerary": [ ... ], "created_at": "2026-12-01T03:00:00+00:00" } ], "next_cursor": null }` (최근에 저장한 순)
- `POST /me/trips` 요청 `{ "title": "부모님과 제주", "itinerary": [ ... ] }` → `201` 저장된 일정
- `DELETE /me/trips/3` → `204` (내 일정이 아니면 404)

## 관리자 주소

서버 환경변수 `ADMIN_EMAILS` 에 적힌 이메일로 로그인한 사람만 쓸 수 있습니다. 토큰이 없으면 `401`, 로그인은 했지만 관리자가 아니면 `403` 입니다. 지우는 주소는 없습니다 — 사용자는 정지하고 여행지는 숨깁니다(둘 다 되돌릴 수 있음).

### 사용자

- `GET /admin/users?q=&size=20&cursor=` → 최근에 가입한 순. `q` 는 이메일 일부.

```json
{
  "items": [
    { "id": "사용자 UUID", "email": "user@example.com", "suspended": false, "created_at": "2026-12-01T03:00:00+00:00", "favorite_count": 4, "trip_count": 1 }
  ],
  "next_cursor": null
}
```

- `PATCH /admin/users/{id}` 요청 `{ "suspended": true }` → 고친 뒤의 사용자. 없는 사용자면 `404`, 자기 자신을 정지하려 하면 `400`.

### 여행지

- `GET /admin/spots?q=&hidden=&size=20&cursor=` → `{ "items": [ AdminSpot, ... ], "next_cursor": 20, "total": 68 }`. 숨긴 곳도 함께 옵니다. `hidden=true` 면 숨긴 곳만, `hidden=false` 면 보이는 곳만.
- AdminSpot 은 Spot 에 `hidden`(숨김 여부)과 `source`(`sample` · `tourapi` · `admin`)가 더해진 모양입니다.
- `POST /admin/spots` → `201` AdminSpot. 필수는 `title`(1~60자), `category`, `area`. 선택은 `address`, `one_liner`, `overview`, `theme_tags`(5개까지), `indoor`, `lat`, `lng`, `image_url`(`https://` 로 시작).
- `PATCH /admin/spots/{id}` → 고친 뒤의 AdminSpot. 보낸 칸만 고칩니다. 숨기려면 `{ "hidden": true }`, 다시 보이려면 `{ "hidden": false }`. 없는 번호면 `404`, 보낸 칸이 없으면 `400`.
- `category` · `area` · `theme_tags` 는 `/meta` 의 선택지 안에서만 받습니다. 밖의 값이면 `422`.
