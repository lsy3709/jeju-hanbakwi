/// 커서 방식으로 나눠 받은 목록 한 묶음(찜 · 저장한 일정용). docs/api.md "커서 페이징" 참고.
/// `nextCursor` 가 null 이면 더 받을 것이 없습니다. 커서의 뜻은 풀지 말고 그대로 돌려보냅니다.
class CursorPage<T> {
  final List<T> items;
  final int? nextCursor;

  const CursorPage({required this.items, required this.nextCursor});

  factory CursorPage.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) {
    return CursorPage(
      items: (json['items'] as List).map((e) => parse(e as Map<String, dynamic>)).toList(),
      nextCursor: json['next_cursor'] as int?,
    );
  }
}
