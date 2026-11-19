"""여행 일정 짜기.

1) AI(Gemini)가 우리 도구(관광지 찾기·날씨 보기)를 스스로 불러 일정을 짭니다.  → mode "ai"
2) AI 키가 없거나 AI 가 실패하면, 같은 도구를 써서 규칙으로 짭니다.              → mode "rule"

어느 쪽이든 "우리 DB 에 있는 관광지만" 일정에 넣습니다. AI 가 지어낸 장소는 버립니다.
"""

import json
import logging
import re
from datetime import date, datetime, timedelta, timezone

from config import settings
from constants import AREAS, CATEGORIES, THEMES, TIMES
from schemas import PlanRequest
from services.weather import WeatherUnavailable, is_rainy

log = logging.getLogger("planner")

# 누구와 가는지에 따라 먼저 찾아볼 테마
COMPANION_THEMES = {
    "아이와": ["아이와", "체험", "박물관"],
    "부모님": ["숲", "폭포", "역사"],
    "연인": ["사진", "카페", "바다"],
    "친구": ["체험", "바다", "시장"],
    "혼자": ["숲", "오름", "카페"],
}

# AI 에게 한 번 묻고 기다리는 최대 시간(밀리초). 넘으면 오류가 나고 규칙 방식으로 넘어갑니다.
# 제한이 없으면 AI 가 멈췄을 때 끝없이 기다리다가, 배포 환경의 응답 시간 제한에 걸려 아무 답도 못 줍니다.
AI_TIMEOUT_MS = 20_000

KOREA = timezone(timedelta(hours=9))  # 한국 시간 = 세계 표준시 + 9시간 (서머타임 없음)

# 규칙으로 짤 때 하루에 한 지역씩 돕니다.
AREA_ORDER = ["동부", "서귀포시", "서부", "제주시"]

SYSTEM_PROMPT = f"""너는 제주 여행 일정을 짜 주는 플래너다.
규칙:
- 반드시 search_spots 도구로 찾은 관광지만 일정에 넣는다. 도구 결과에 없는 장소를 지어내지 않는다.
- 먼저 get_weather 로 날씨를 확인하고, 비나 눈이 오는 날은 실내(indoor) 위주로 고른다.
- 하루에 3~4곳, 같은 날은 가까운 지역끼리 묶는다. 같은 장소를 두 번 넣지 않는다.
- 점심에는 category 가 음식점이나 쇼핑(시장)인 곳만 넣는다. 알맞은 곳이 없으면 점심은 뺀다.
- 사용할 수 있는 테마: {", ".join(THEMES)} / 지역: {", ".join(AREAS)}
- 도구는 모두 합쳐 5번 이내로 부른다.
- 마지막 답은 설명 없이 아래 JSON 하나만 출력한다.
{{"answer": "두세 문장 설명", "itinerary": [{{"day": 1, "items": [{{"time": "오전", "spot_id": 12, "reason": "고른 이유 한 문장"}}]}}]}}
- time 은 오전, 점심, 오후, 저녁 중 하나. answer 와 reason 은 한국어 존댓말."""


# ---------------------------------------------------------------- 공통 도구

def brief(spot: dict) -> dict:
    """AI 에게는 관광지의 핵심만 줍니다. (글자 수 = 비용)"""
    return {
        "id": spot["id"],
        "title": spot["title"],
        "category": spot["category"],
        "area": spot["area"],
        "one_liner": spot["one_liner"],
        "theme_tags": spot["theme_tags"],
        "indoor": spot["indoor"],
    }


def weather_by_date(get_weather) -> dict[str, dict]:
    """날짜 → 그날 날씨(제주시 기준). 날씨를 못 받으면 빈 사전."""
    try:
        weather = get_weather()
    except WeatherUnavailable:
        return {}
    days = weather["areas"][0]["days"] if weather["areas"] else []
    return {str(day["date"]): day for day in days}


def korea_today(now: datetime | None = None) -> date:
    """한국 기준 오늘 날짜.

    date.today() 는 "서버가 있는 곳"의 날짜입니다. 배포한 서버는 세계 표준시로 돌기 때문에,
    한국의 자정~오전 9시에는 어제 날짜가 나와 일정과 날씨가 하루씩 밀립니다.
    """
    return (now or datetime.now(timezone.utc)).astimezone(KOREA).date()


def trip_dates(request: PlanRequest) -> list[date]:
    start = request.start_date or korea_today()
    return [start + timedelta(days=i) for i in range(request.days)]


# ---------------------------------------------------------------- 규칙으로 짜기

def find_mentioned_spots(message: str, repo) -> list[dict]:
    """글에 관광지 이름이 들어 있으면 찾아 줍니다. 예: "성산일출봉을 포함한 일정" """
    compact = message.replace(" ", "")
    found = []
    for word in re.findall(r"[가-힣0-9A-Za-z·]{2,}", message)[:8]:
        # 낱말 끝의 조사를 뗍니다. 긴 것부터 적어야 "에서"가 "서"만 남지 않습니다.
        trimmed = re.sub(r"(에서|이랑|하고|까지|을|를|이|가|은|는|에|의|과|와|도|로|랑)$", "", word)
        # "우도"처럼 조사와 같은 글자로 끝나는 두 글자 이름은, 떼고 나면 한 글자가 됩니다. 그럴 땐 떼지 않습니다.
        if len(trimmed) >= 2:
            word = trimmed
        items, _ = repo.list_spots(q=word, size=5)
        for spot in items:
            if spot["title"].replace(" ", "") in compact and spot not in found:
                found.append(spot)
    return found


def pick_spots(repo, themes, area, indoor, used: set, need: int, exclude_food=True) -> list[tuple[dict, str]]:
    """조건을 조금씩 풀어 가며 need 개를 고릅니다. → [(관광지, 고른 이유)]"""
    picked: list[tuple[dict, str]] = []

    def take(items, reason, allow_shopping=False):
        for spot in items:
            if len(picked) >= need:
                return
            if spot["id"] in used:
                continue
            if exclude_food and spot["category"] == "음식점":
                continue
            # 쇼핑(면세점·백화점 등)은 관광지 칸에 넣지 않습니다. 단, "시장"을 찾을 때는 시장이 쇼핑 분류라 허용합니다.
            if exclude_food and spot["category"] == "쇼핑" and not allow_shopping:
                continue
            used.add(spot["id"])
            picked.append((spot, reason))

    rain_note = "비 예보가 있어 실내에서 즐길 수 있는 곳으로 골랐어요." if indoor else ""
    for theme in themes:
        items, _ = repo.list_spots(theme=theme, area=area, indoor=indoor, size=10)
        take(items, rain_note or f"'{theme}' 테마에 맞는 곳이에요.", allow_shopping=(theme == "시장"))
    if len(picked) < need:
        items, _ = repo.list_spots(area=area, indoor=indoor, size=20)
        take(items, rain_note or f"{area} 동선에 맞춰 골랐어요.")
    if len(picked) < need:
        items, _ = repo.list_spots(indoor=indoor, size=30)
        take(items, rain_note or "함께 둘러보기 좋은 곳이에요.")
    if len(picked) < need:
        items, _ = repo.list_spots(size=50)
        take(items, "함께 둘러보기 좋은 곳이에요.")
    return picked


def plan_by_rule(request: PlanRequest, repo, get_weather) -> dict:
    asked_themes = [t for t in THEMES if t in request.message]  # 글에서 직접 말한 테마
    themes = list(asked_themes)
    for theme in COMPANION_THEMES.get(request.companions or "", []):
        if theme not in themes:
            themes.append(theme)

    forecast = weather_by_date(get_weather)
    mentioned = find_mentioned_spots(request.message, repo)
    used: set[int] = {spot["id"] for spot in mentioned}
    sources: dict[int, dict] = {}
    itinerary = []

    for index, day in enumerate(trip_dates(request)):
        weather = forecast.get(str(day))
        indoor = True if (weather and is_rainy(weather)) else None

        # 글에 나온 관광지가 있으면 그날의 지역을 거기에 맞춥니다.
        must = mentioned.pop(0) if mentioned else None
        area = must["area"] if must else AREA_ORDER[index % len(AREA_ORDER)]
        if not must and asked_themes:
            # 직접 말한 테마가 있으면, 그 테마의 장소가 남아 있는 지역으로 갑니다.
            candidates, _ = repo.list_spots(theme=asked_themes[0], indoor=indoor, size=30)
            first = next((s for s in candidates if s["id"] not in used), None)
            if first:
                area = first["area"]

        sights = [(must, "말씀하신 곳을 일정에 넣었어요.")] if must else []
        sights += pick_spots(repo, themes, area, indoor, used, need=3 - len(sights))
        food_items, _ = repo.list_spots(area=area, category="음식점", size=5)
        food = next((spot for spot in food_items if spot["id"] not in used), None)

        items = []
        slots = ["오전", "오후", "저녁"]
        for slot, (spot, reason) in zip(slots, sights):
            items.append({"time": slot, "spot_id": spot["id"], "title": spot["title"], "reason": reason})
            sources[spot["id"]] = spot
        if food:
            used.add(food["id"])
            sources[food["id"]] = food
            # 오전 다음에 점심을 끼워 넣습니다.
            items.insert(1, {"time": "점심", "spot_id": food["id"], "title": food["title"], "reason": f"{area}에서 식사하기 좋은 곳이에요."})

        itinerary.append(
            {"day": index + 1, "date": day, "weather": weather["label"] if weather else None, "items": items}
        )

    rainy_days = [d["day"] for d in itinerary if d["weather"] and forecast.get(str(d["date"])) and is_rainy(forecast[str(d["date"])])]
    answer = f"{request.days}일 일정을 지역별로 묶어 짜 보았어요."
    if rainy_days:
        answer += f" {', '.join(str(d) + '일차' for d in rainy_days)}는 비 예보가 있어 실내 위주로 골랐어요."
    return {"mode": "rule", "answer": answer, "itinerary": itinerary, "sources": list(sources.values())}


# ---------------------------------------------------------------- AI 로 짜기

def extract_json(text: str) -> dict:
    """AI 답에서 JSON 부분만 꺼냅니다. (```json 같은 장식이 붙어 와도 되게)"""
    match = re.search(r"\{.*\}", text or "", re.DOTALL)
    if not match:
        raise ValueError("AI 답에 JSON 이 없습니다.")
    return json.loads(match.group(0))


def build_plan_from_ai(data: dict, found: dict[int, dict], request: PlanRequest, forecast: dict) -> dict:
    """AI 가 준 일정을 검사합니다. 우리가 찾아 준 관광지가 아니면 버립니다."""
    dates = trip_dates(request)
    itinerary, sources, seen = [], {}, set()
    for index, raw_day in enumerate((data.get("itinerary") or [])[: request.days]):
        items = []
        for raw in raw_day.get("items") or []:
            try:
                spot_id = int(raw.get("spot_id"))
            except (TypeError, ValueError):
                continue
            spot = found.get(spot_id)
            time_slot = raw.get("time")
            if not spot or spot_id in seen or time_slot not in ("오전", "점심", "오후", "저녁"):
                continue
            seen.add(spot_id)
            sources[spot_id] = spot
            items.append(
                {"time": time_slot, "spot_id": spot_id, "title": spot["title"], "reason": str(raw.get("reason") or "")[:200]}
            )
        if items:
            # AI 가 저녁을 오전보다 먼저 적어 보내기도 합니다. 화면은 받은 순서대로 그리므로 여기서 하루 순서로 맞춥니다.
            items.sort(key=lambda item: TIMES.index(item["time"]))
            weather = forecast.get(str(dates[index]))
            itinerary.append(
                {"day": index + 1, "date": dates[index], "weather": weather["label"] if weather else None, "items": items}
            )
    if not itinerary:
        raise ValueError("AI 일정에 쓸 수 있는 관광지가 없습니다.")
    answer = str(data.get("answer") or "일정을 짜 보았어요.")[:600]
    return {"mode": "ai", "answer": answer, "itinerary": itinerary, "sources": list(sources.values())}


def ask_gemini(request: PlanRequest, repo, get_weather_fn, found: dict[int, dict]) -> str:
    """Gemini 에게 도구 두 개를 쥐여 주고 일정을 받아 옵니다. 돌려주는 값은 AI 의 마지막 글."""
    from google import genai
    from google.genai import types

    # ---- AI 가 부를 수 있는 도구 (함수의 이름·설명·인자가 그대로 AI 에게 전달됩니다) ----
    def search_spots(keyword: str = "", theme: str = "", area: str = "", category: str = "", indoor_only: bool = False) -> list[dict]:
        """제주 관광지를 찾는다.

        Args:
            keyword: 이름에 들어간 낱말. 예: 폭포, 성산
            theme: 테마 하나. 예: 바다, 오름, 숲, 박물관, 아이와
            area: 지역 하나. 제주시, 서귀포시, 동부, 서부 중 하나
            category: 분류 하나. 관광지, 문화시설, 축제, 레포츠, 쇼핑, 음식점 중 하나
            indoor_only: 실내만 찾으려면 true
        """
        items, _ = repo.list_spots(
            q=keyword or None,
            theme=theme if theme in THEMES else None,
            area=area if area in AREAS else None,
            category=category if category in CATEGORIES else None,
            indoor=True if indoor_only else None,
            size=8,
        )
        for spot in items:
            found[spot["id"]] = spot  # AI 에게 보여 준 관광지를 기억해 둡니다 (나중에 검사용)
        return [brief(spot) for spot in items]

    def get_weather() -> list[dict]:
        """오늘부터 4일간 제주 날씨를 날짜별로 알려 준다. rainy 가 true 면 비나 눈이 오는 날."""
        try:
            weather = get_weather_fn()
        except WeatherUnavailable:
            return []
        return [
            {"date": str(d["date"]), "label": d["label"], "rain_prob": d["rain_prob"], "rainy": is_rainy(d)}
            for d in weather["areas"][0]["days"]
        ]

    dates = trip_dates(request)
    prompt = (
        f"여행 요청: {request.message}\n"
        f"기간: {request.days}일 ({dates[0]} 부터)\n"
        f"동행: {request.companions or '정해지지 않음'}"
    )
    client = genai.Client(api_key=settings.gemini_api_key, http_options=types.HttpOptions(timeout=AI_TIMEOUT_MS))
    response = client.models.generate_content(
        model=settings.gemini_model,
        contents=prompt,
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_PROMPT,
            tools=[search_spots, get_weather],  # 파이썬 함수를 그대로 넘기면 SDK 가 알아서 불러 줍니다
            automatic_function_calling=types.AutomaticFunctionCallingConfig(maximum_remote_calls=6),
            temperature=0.4,
            # 깊이 생각하는 정도를 낮춰 응답을 빠르게 합니다. (서버 함수에는 응답 시간 제한이 있습니다)
            thinking_config=types.ThinkingConfig(thinking_level="low"),
        ),
    )
    return response.text or ""


def plan_trip(request: PlanRequest, repo, get_weather, ask_ai=ask_gemini) -> dict:
    """일정 짜기의 입구. AI 를 먼저 시도하고, 안 되면 규칙으로 짭니다."""
    if settings.gemini_api_key:
        try:
            found: dict[int, dict] = {}
            text = ask_ai(request, repo, get_weather, found)
            return build_plan_from_ai(extract_json(text), found, request, weather_by_date(get_weather))
        except Exception as error:  # AI 쪽 문제는 무엇이든 규칙 방식으로 넘어갑니다
            log.warning("AI 일정 실패, 규칙으로 대신합니다: %s", error)
    return plan_by_rule(request, repo, get_weather)
