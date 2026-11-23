"""AI 사용량 모으기. DB 에서 꺼낸 줄(ai_usage 표)을 화면에 보여 줄 모양으로 더합니다.

DB 를 읽는 일은 repo.py, 주소는 routers/me.py · admin.py 에 있고, 여기는 읽어 온 줄을 더하는 계산을 맡습니다.
날짜는 한국 시간 기준으로 나눕니다(서버는 세계 표준시로 돕니다).
"""

from datetime import datetime, time, timedelta, timezone

from fastapi import HTTPException

from services.plan_common import KOREA, korea_today

# 한 번에 읽는 줄 수의 한도. Supabase 의 API 는 한 번에 1000줄까지만 돌려줍니다.
# 기간 안의 기록이 이보다 많으면 최근 1000줄만 세고, 응답의 truncated 로 알려 줍니다.
ROW_LIMIT = 1000
USER_LIMIT = 50   # 사용자별 표에 보여 줄 사람 수

EMPTY = {
    "requests": 0, "ai_requests": 0, "rule_requests": 0, "user_key_requests": 0, "server_key_requests": 0,
    "tokens_in": 0, "tokens_out": 0, "tokens_total": 0, "server_tokens_total": 0,
}


def period_start(days: int, now: datetime | None = None) -> str:
    """오늘을 포함해 days 일 전의 한국 자정. DB 에 물어볼 때 쓰는 글자(ISO)로 돌려줍니다."""
    first_day = korea_today(now) - timedelta(days=days - 1)
    return datetime.combine(first_day, time.min, tzinfo=KOREA).astimezone(timezone.utc).isoformat()


def read_usage(repo, days: int, user_id: str | None = None) -> list[dict]:
    """기간 안의 기록을 DB 에서 읽습니다. 표가 아직 없으면(SQL 004 를 실행하지 않음) 503 으로 알려 줍니다."""
    try:
        return repo.list_ai_usage(period_start(days), user_id=user_id, limit=ROW_LIMIT)
    except Exception as error:
        raise HTTPException(
            status_code=503,
            detail="AI 사용량을 읽지 못했습니다. DB 에 004_ai_usage.sql 을 실행했는지 확인해 주세요.",
        ) from error


def korea_date(created_at: str) -> str:
    """DB 의 시각 글자를 한국 날짜("2026-12-01")로 바꿉니다."""
    return datetime.fromisoformat(created_at.replace("Z", "+00:00")).astimezone(KOREA).date().isoformat()


def summarize(rows: list[dict]) -> dict:
    """줄들을 하나로 더합니다."""
    total = dict(EMPTY)
    for row in rows:
        total["requests"] += 1
        total["ai_requests" if row["mode"] == "ai" else "rule_requests"] += 1
        if row["key_source"] == "user":
            total["user_key_requests"] += 1
        elif row["key_source"] == "server":
            total["server_key_requests"] += 1
            total["server_tokens_total"] += row["tokens_total"]   # 서버 키로 쓴 것은 서비스가 내는 몫
        for name in ("tokens_in", "tokens_out", "tokens_total"):
            total[name] += row[name]
    return total


def _grouped(rows: list[dict], key) -> dict:
    groups: dict = {}
    for row in rows:
        groups.setdefault(key(row), []).append(row)
    return groups


def by_day(rows: list[dict]) -> list[dict]:
    """한국 날짜별로 더합니다. 최근 날짜가 먼저."""
    groups = _grouped(rows, lambda row: korea_date(row["created_at"]))
    return [{"date": day, **summarize(groups[day])} for day in sorted(groups, reverse=True)]


def by_user(rows: list[dict], emails: dict[str, str]) -> list[dict]:
    """사용자별로 더합니다. 토큰을 많이 쓴 순(같으면 요청이 많은 순). 로그인하지 않은 요청은 한 줄로 묶습니다."""
    groups = _grouped(rows, lambda row: row["user_id"])
    users = [{"user_id": user_id, "email": emails.get(user_id) if user_id else None, **summarize(items)} for user_id, items in groups.items()]
    users.sort(key=lambda u: (-u["tokens_total"], -u["requests"]))
    return users[:USER_LIMIT]


def report(rows: list[dict], days: int, now: datetime | None = None, emails: dict[str, str] | None = None) -> dict:
    """주소가 돌려줄 모양. emails 를 주면 사용자별 표(by_user)도 만듭니다(관리자용)."""
    today = korea_today(now).isoformat()
    return {
        "days": days,
        "total": summarize(rows),
        "today": summarize([row for row in rows if korea_date(row["created_at"]) == today]),
        "by_day": by_day(rows),
        "by_user": by_user(rows, emails) if emails is not None else None,
        "truncated": len(rows) >= ROW_LIMIT,
    }
