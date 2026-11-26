"""가까운 곳 찾기. 좌표 두 개의 거리를 재고, 가까운 순으로 고릅니다.

DB 를 부르지 않는 순수한 계산이라 테스트하기 쉽습니다. 후보(식당 100곳쯤)는 주소 쪽에서 받아 넘깁니다.
"""

from math import asin, cos, radians, sin, sqrt

EARTH_RADIUS_KM = 6371.0


def distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """두 좌표 사이의 직선 거리(km). 지구가 둥근 것을 셈에 넣는 하버사인 공식입니다."""
    d_lat, d_lng = radians(lat2 - lat1), radians(lng2 - lng1)
    a = sin(d_lat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lng / 2) ** 2
    return 2 * EARTH_RADIUS_KM * asin(sqrt(a))


def nearest(here: dict, candidates: list[dict], size: int = 5) -> list[dict]:
    """here 에서 가까운 순으로 size 곳. 각 곳에 distance_km(소수 한 자리)를 붙인 새 사전을 돌려줍니다.

    좌표가 없는 곳과 자기 자신은 뺍니다. here 에 좌표가 없으면 빈 목록입니다.
    """
    if here.get("lat") is None or here.get("lng") is None:
        return []
    found = []
    for place in candidates:
        if place.get("lat") is None or place.get("lng") is None or place.get("id") == here.get("id"):
            continue
        km = distance_km(here["lat"], here["lng"], place["lat"], place["lng"])
        found.append({**place, "distance_km": round(km, 1)})
    found.sort(key=lambda place: (place["distance_km"], place["id"]))
    return found[:size]
