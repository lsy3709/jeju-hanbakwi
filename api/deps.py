"""주소(라우터)들이 함께 쓰는 "주입할 것"들. (의존성 주입)

FastAPI 의 Depends(...) 에 넣는 함수입니다. 주소는 "무엇이 필요한지"만 적고,
실제로 무엇을 줄지는 여기서 정합니다. 그래서 테스트에서는 가짜로 바꿔 끼울 수 있습니다.

  DB           → repo.get_repo
  로그인 확인  → auth.get_current_user
  날씨         → 아래 get_weather_service
  AI 에게 묻기 → 아래 get_ai_asker · get_key_checker
"""

from services import plan_ai, weather


def get_weather_service():
    """날씨를 가져오는 함수를 돌려줍니다. (테스트에서는 가짜 날씨 함수로 바꿉니다)"""
    return weather.get_weather


def get_ai_asker():
    """AI 에게 일정을 묻는 함수를 돌려줍니다. (테스트에서는 가짜 AI 로 바꿉니다)"""
    return plan_ai.ask_gemini


def get_key_checker():
    """AI 키가 쓸 수 있는 키인지 확인하는 함수를 돌려줍니다. (테스트에서는 가짜로 바꿉니다)"""
    return plan_ai.check_gemini_key
