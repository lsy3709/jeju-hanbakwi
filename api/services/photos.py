"""사진 주소 완성하기.

샘플 사진은 우리 서버가 직접 내줍니다. (api/static/photos/S001.jpg → /photos/S001.jpg)
DB 에는 "/photos/S001.jpg" 처럼 짧은 주소만 두고, 응답할 때 이 서버의 주소를 앞에 붙입니다.
"""

# 쓰는 곳: routers/ 의 관광지 응답들(spots · admin · agent · me)이 응답 직전에 부르고, /status 가 count_photos 를 부릅니다.
# 낱말: request.base_url = "이 요청이 들어온 서버 주소". 서버가 어떤 주소로 불렸는지 알아내는 데 씁니다.
from pathlib import Path

from fastapi import Request

from config import settings

# 이 파일 위치(services/)의 위 폴더(api/) 아래 static/photos. main.py 가 이 폴더를 /photos 주소로 내줍니다.
PHOTO_DIR = Path(__file__).parent.parent / "static" / "photos"


def with_photo_address(spot: dict, request: Request) -> dict:
    """짧은 사진 주소 앞에 이 서버의 주소를 붙인 새 사전을 돌려줍니다.

    웹은 localhost:8000, 에뮬레이터는 10.0.2.2:8000 으로 이 서버를 부릅니다.
    요청이 들어온 주소를 그대로 붙여 주면 각자 자기가 닿을 수 있는 주소로 사진을 받습니다.
    바깥 사진(https://...)이나 사진이 없는 경우는 그대로 둡니다.
    """
    # "/" 로 시작하면 우리 서버의 사진(짧은 주소)이라는 뜻입니다. 그 외(https://...)는 손대지 않습니다.
    image_url = spot.get("image_url")
    if not image_url or not image_url.startswith("/"):
        return spot
    base = settings.public_api_url or str(request.base_url).rstrip("/")
    # {**spot, "image_url": ...} 는 spot 의 칸을 모두 복사하고 image_url 칸만 새 값으로 덮어쓴 사전입니다.
    return {**spot, "image_url": base + image_url}  # 원본은 건드리지 않고 복사본을 돌려줍니다


def with_photo_addresses(spots: list[dict], request: Request) -> list[dict]:
    return [with_photo_address(spot, request) for spot in spots]


def count_photos() -> int:
    """서버에 들어 있는 사진 수. (운영 확인용)"""
    return len(list(PHOTO_DIR.glob("*.jpg"))) if PHOTO_DIR.exists() else 0
