"""서버의 시작점. 앱을 만들고, 주소 묶음(라우터)을 끼웁니다.

실행:  uvicorn main:app --reload        (api 폴더에서)
확인:  http://localhost:8000/docs       (주소를 직접 눌러 볼 수 있는 화면)

구조 (자세한 설명은 docs/architecture.md)
  routers/   주소 — 요청을 받아 넘기고 결과를 돌려주기만 합니다
  repo.py    DB — 다른 파일은 DB 를 직접 만지지 않고 여기 함수만 부릅니다
  deps.py    주소들이 함께 쓰는 "주입할 것"
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from routers import spots, system

app = FastAPI(title="제주 한 바퀴 API", version="1.1.0")

# 다른 주소의 화면(웹·앱)이 이 서버를 부를 수 있게 허락합니다.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    # 개발 중에는 localhost 의 어떤 포트든 허용 (Flutter 웹은 실행할 때마다 포트가 바뀝니다)
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
)

# 주소 묶음을 끼웁니다. 새 주소 묶음을 만들면 여기에 한 줄 더합니다.
app.include_router(system.router)   # /health
app.include_router(spots.router)    # /meta, /spots
