"""커서 페이징에서 되풀이되는 계산 한 가지.

목록 주소는 모두 같은 방법으로 "다음 묶음이 더 있는지"를 압니다.
  1) size 보다 하나 더(size + 1개) 가져온다.
  2) 하나 더 왔으면 뒤에 더 있다는 뜻이다. 그 하나는 버리고, 남은 것의 마지막 번호를 next_cursor 로 준다.
  3) 하나 더 오지 않았으면 끝이다. next_cursor 는 None.
전체 개수를 세지 않아도 "더 보기" 단추를 보일지 알 수 있습니다.
"""


# 쓰는 곳: routers/spots.py · me.py · admin.py 의 모든 목록 주소. repo 에 size + 1 개를 달라고 한 뒤 이 함수로 자릅니다.
# cursor_of 는 "함수를 받는 값"입니다. 호출할 때 `lambda spot: spot["id"]` 처럼 번호 꺼내는 법을 넘겨 줍니다.
def cut_page(rows: list, size: int, cursor_of):
    """rows(최대 size + 1개)를 → (이번 묶음, next_cursor) 로 나눕니다.

    cursor_of: 한 줄에서 커서로 쓸 번호를 꺼내는 함수.
    """
    if len(rows) <= size:
        return rows, None
    page = rows[:size]
    return page, cursor_of(page[-1])
