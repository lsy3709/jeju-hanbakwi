"""규칙으로 일정 짜기. AI 키가 없거나 AI 가 실패했을 때 쓰는 방식입니다. → mode "rule"

하루에 한 지역씩 돌고, 비 오는 날은 실내 위주로, 글에서 말한 테마와 장소를 먼저 넣습니다.
"""

import re

from constants import THEMES
from schemas import PlanRequest
from services.plan_common import trip_dates, weather_by_date
from services.weather import is_rainy

# 누구와 가는지에 따라 먼저 찾아볼 테마
COMPANION_THEMES = {
    "아이와": ["아이와", "체험", "박물관"],
    "부모님": ["숲", "폭포", "역사"],
    "연인": ["사진", "카페", "바다"],
    "친구": ["체험", "바다", "시장"],
    "혼자": ["숲", "오름", "카페"],
}

# 하루에 한 지역씩 돕니다.
AREA_ORDER = ["동부", "서귀포시", "서부", "제주시"]

SIGHTS_PER_DAY = 3  # 하루에 넣는 관광지 수 (점심은 따로)


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


def take_mentioned_for_day(mentioned: list[dict], is_last_day: bool) -> list[dict]:
    """말한 장소 가운데 오늘 갈 곳을 꺼냅니다(목록에서도 빼냄). 하루 최대 3곳.

    - 첫 장소와 같은 지역에 있는 곳을 함께 묶습니다(동선).
    - 마지막 날에는 지역이 달라도 남은 곳을 넣습니다. 말한 곳을 빠뜨리지 않는 것이 먼저이기 때문입니다.
    """
    if not mentioned:
        return []
    today = [mentioned.pop(0)]
    candidates = list(mentioned) if is_last_day else [s for s in mentioned if s["area"] == today[0]["area"]]
    for spot in candidates[: SIGHTS_PER_DAY - 1]:
        mentioned.remove(spot)
        today.append(spot)
    return today


def pick_spots(repo, themes, area, indoor, used: set, need: int, exclude_food=True) -> list[tuple[dict, str]]:
    """조건을 조금씩 풀어 가며 need 개를 고릅니다. → [(관광지, 고른 이유)]"""
    picked: list[tuple[dict, str]] = []
    if need <= 0:
        return picked

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


class RulePlanner:
    """규칙으로 일정을 짜는 방식. (services/plan_common.py 의 Planner 모양을 따릅니다)"""

    name = "rule"

    def __init__(self, repo, get_weather):
        self.repo = repo
        self.get_weather = get_weather

    def plan(self, request: PlanRequest) -> dict:
        repo = self.repo
        asked_themes = [t for t in THEMES if t in request.message]  # 글에서 직접 말한 테마
        themes = list(asked_themes)
        for theme in COMPANION_THEMES.get(request.companions or "", []):
            if theme not in themes:
                themes.append(theme)

        forecast = weather_by_date(self.get_weather)
        mentioned = find_mentioned_spots(request.message, repo)
        used: set[int] = {spot["id"] for spot in mentioned}
        sources: dict[int, dict] = {}
        itinerary = []
        dates = trip_dates(request)

        for index, day in enumerate(dates):
            weather = forecast.get(str(day))
            indoor = True if (weather and is_rainy(weather)) else None

            # 글에 나온 관광지가 있으면 먼저 넣고, 그날의 지역을 거기에 맞춥니다.
            must = take_mentioned_for_day(mentioned, is_last_day=(index == len(dates) - 1))
            area = must[0]["area"] if must else AREA_ORDER[index % len(AREA_ORDER)]
            if not must and asked_themes:
                # 직접 말한 테마가 있으면, 그 테마의 장소가 남아 있는 지역으로 갑니다.
                candidates, _ = repo.list_spots(theme=asked_themes[0], indoor=indoor, size=30)
                first = next((s for s in candidates if s["id"] not in used), None)
                if first:
                    area = first["area"]

            sights = [(spot, "말씀하신 곳을 일정에 넣었어요.") for spot in must]
            sights += pick_spots(repo, themes, area, indoor, used, need=SIGHTS_PER_DAY - len(sights))
            food_items, _ = repo.list_spots(area=area, category="음식점", size=5)
            food = next((spot for spot in food_items if spot["id"] not in used), None)

            items = []
            for slot, (spot, reason) in zip(["오전", "오후", "저녁"], sights):
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

        answer = f"{request.days}일 일정을 지역별로 묶어 짜 보았어요."
        rainy_days = [d["day"] for d in itinerary if forecast.get(str(d["date"])) and is_rainy(forecast[str(d["date"])])]
        if rainy_days:
            answer += f" {', '.join(str(d) + '일차' for d in rainy_days)}는 비 예보가 있어 실내 위주로 골랐어요."
        if mentioned:
            # 하루에 넣을 수 있는 수보다 많이 말한 경우: 조용히 빼지 않고 알려 줍니다.
            answer += f" 일정이 꽉 차서 넣지 못한 곳: {', '.join(s['title'] for s in mentioned)}. 날짜를 늘려 다시 짜 보세요."
        return {"mode": self.name, "answer": answer, "itinerary": itinerary, "sources": list(sources.values())}
