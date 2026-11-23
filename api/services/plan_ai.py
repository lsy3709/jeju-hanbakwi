"""AI(Gemini)로 일정 짜기. → mode "ai"

AI 에게 도구 두 개(관광지 찾기 · 날씨 보기)를 쥐여 주면, AI 가 필요한 도구를 스스로 불러 일정을 짭니다.
AI 가 준 답은 그대로 믿지 않고 검사합니다. 우리가 찾아 준 관광지가 아니면 버립니다.
"""

import json
import re
import time

from config import settings
from constants import AREAS, CATEGORIES, THEMES, TIMES
from schemas import PlanRequest
from services.plan_common import brief, trip_dates, weather_by_date
from services.weather import WeatherUnavailable, is_rainy

# AI 에게 한 번 묻고 기다리는 최대 시간(밀리초). 넘으면 오류가 나고 규칙 방식으로 넘어갑니다.
# 제한이 없으면 AI 가 멈췄을 때 끝없이 기다리다가, 배포 환경의 응답 시간 제한에 걸려 아무 답도 못 줍니다.
AI_TIMEOUT_MS = 20_000

# AI 는 도구를 부르고 결과를 받아 다시 생각하기를 몇 번 되풀이합니다(한 번 오가는 것을 "왕복"이라 부릅니다).
MAX_AI_ROUNDS = 7          # 도구를 부르는 왕복 6번 + 마지막 답
AI_TOTAL_TIMEOUT_S = 50    # 모든 왕복을 합친 시간 한도. 넘으면 오류가 나고 규칙 방식으로 넘어갑니다.

# AI 의 역할과 규칙. 내 주제로 바꿀 때 가장 먼저 고치는 곳입니다.
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
            if not spot or spot_id in seen or time_slot not in TIMES:
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


def check_gemini_key(api_key: str) -> bool:
    """이 키로 Gemini 를 부를 수 있는지 확인합니다. 글을 만들지 않고 모델 목록만 한 줄 받아 봅니다(요금 없음).

    키가 틀렸으면 False. 서비스에 닿지 못한 것 같은 다른 문제는 오류를 그대로 올립니다.
    """
    from google import genai
    from google.genai import errors, types

    client = genai.Client(api_key=api_key, http_options=types.HttpOptions(timeout=10_000))
    try:
        next(iter(client.models.list(config={"page_size": 1})), None)
    except errors.ClientError:   # 400 · 401 · 403: 키가 틀렸거나 쓸 수 없는 키
        return False
    return True


def add_tokens(used: dict, meta) -> None:
    """AI 응답 한 번이 알려 준 토큰 수를 더합니다. (생각하는 데 쓴 토큰은 출력에 넣습니다)"""
    used["ai_calls"] += 1
    if meta is None:
        return
    used["tokens_in"] += meta.prompt_token_count or 0
    used["tokens_out"] += (meta.candidates_token_count or 0) + (meta.thoughts_token_count or 0)
    used["tokens_total"] += meta.total_token_count or 0


def run_tool(tools: dict, call) -> dict:
    """AI 가 부르라고 한 도구를 실행합니다. 없는 도구거나 인자가 이상하면 오류를 AI 에게 알려 줍니다."""
    tool = tools.get(call.name)
    if tool is None:
        return {"error": f"{call.name} 라는 도구는 없습니다."}
    try:
        return {"result": tool(**(call.args or {}))}
    except TypeError as error:
        return {"error": f"인자가 맞지 않습니다: {error}"}


def ask_gemini(
    request: PlanRequest, repo, get_weather_fn, found: dict[int, dict], api_key: str | None = None
) -> tuple[str, dict]:
    """Gemini 에게 도구 두 개를 쥐여 주고 일정을 받아 옵니다. 돌려주는 값은 (AI 의 마지막 글, 사용량).

    api_key 가 있으면(사용자가 보낸 자기 키) 그 키로, 없으면 서버 설정의 키로 부릅니다.
    사용량은 {ai_calls, tokens_in, tokens_out, tokens_total} — 도구를 부르며 오간 모든 왕복의 합입니다.
    """
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
    tools = {"search_spots": search_spots, "get_weather": get_weather}
    client = genai.Client(api_key=api_key or settings.gemini_api_key, http_options=types.HttpOptions(timeout=AI_TIMEOUT_MS))
    config = types.GenerateContentConfig(
        system_instruction=SYSTEM_PROMPT,
        tools=list(tools.values()),  # 파이썬 함수를 그대로 넘기면 SDK 가 이름 · 설명 · 인자를 AI 에게 알려 줍니다
        # 도구는 SDK 에 맡기지 않고 아래에서 직접 실행합니다. 왕복마다 쓴 토큰 수를 더하려는 것입니다.
        # (SDK 에 맡기면 마지막 왕복의 토큰 수만 알 수 있어 실제보다 적게 잡힙니다)
        automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True),
        temperature=0.4,
        # 깊이 생각하는 정도를 낮춰 응답을 빠르게 합니다. (서버 함수에는 응답 시간 제한이 있습니다)
        thinking_config=types.ThinkingConfig(thinking_level="low"),
    )
    contents = [types.Content(role="user", parts=[types.Part(text=prompt)])]
    used = {"ai_calls": 0, "tokens_in": 0, "tokens_out": 0, "tokens_total": 0}
    started = time.monotonic()
    try:
        for _ in range(MAX_AI_ROUNDS):
            if time.monotonic() - started > AI_TOTAL_TIMEOUT_S:
                raise TimeoutError("AI 가 정해 둔 시간 안에 답하지 못했습니다.")
            response = client.models.generate_content(model=settings.gemini_model, contents=contents, config=config)
            add_tokens(used, response.usage_metadata)
            calls = response.function_calls or []
            if not calls:  # 도구를 더 부르지 않으면 이것이 마지막 답입니다
                return response.text or "", used
            # AI 의 말(도구를 불러 달라는 요청)과 도구가 돌려준 결과를 대화에 이어 붙이고 다시 묻습니다.
            contents.append(response.candidates[0].content)
            results = [types.Part.from_function_response(name=call.name, response=run_tool(tools, call)) for call in calls]
            contents.append(types.Content(role="user", parts=results))
        raise ValueError("AI 가 도구만 부르다 답을 내지 못했습니다.")
    except Exception as error:
        # 도중에 실패해도 그때까지 쓴 토큰은 쓴 것입니다. 오류에 실어 올려 사용량 기록에 잡히게 합니다.
        error.usage = used
        raise


class AiPlanner:
    """AI 로 일정을 짜는 방식. (services/plan_common.py 의 Planner 모양을 따릅니다)

    ask 는 "AI 에게 묻는 함수"입니다. 기본은 ask_gemini 이고, 테스트에서는 가짜로 바꿔 끼웁니다.
    api_key 는 사용자가 보낸 자기 키입니다. 없으면(None) 서버 설정의 키를 씁니다.
    """

    name = "ai"

    def __init__(self, repo, get_weather, ask=ask_gemini, api_key: str | None = None):
        self.repo = repo
        self.get_weather = get_weather
        self.ask = ask
        self.api_key = api_key
        self.last_usage: dict | None = None   # 마지막으로 일정을 짤 때 쓴 양(없으면 None)

    def plan(self, request: PlanRequest) -> dict:
        found: dict[int, dict] = {}
        # 사용자 키가 있을 때만 api_key 를 넘깁니다(없으면 묻는 함수가 서버 설정의 키를 씁니다).
        extra = {"api_key": self.api_key} if self.api_key else {}
        self.last_usage = None
        try:
            answer = self.ask(request, self.repo, self.get_weather, found, **extra)
        except Exception as error:
            self.last_usage = getattr(error, "usage", None)   # 실패한 시도에서 쓴 양
            raise
        # 묻는 함수는 (글, 사용량)을 돌려줍니다. 글만 돌려주는 함수(테스트의 가짜)도 받습니다.
        text, self.last_usage = answer if isinstance(answer, tuple) else (answer, None)
        return build_plan_from_ai(extract_json(text), found, request, weather_by_date(self.get_weather))
