// 서버가 "한 번에 20개씩" 나눠 보내는 목록을 담는 모양입니다. 찜 목록과 저장한 일정 목록이 같이 씁니다.
// CursorPage<T> 의 T 는 "안에 든 항목의 종류"를 나중에 정하는 자리입니다(Spot 이면 CursorPage<Spot>). models/ 의 클래스는 모두 서버 JSON 을 담는 상자입니다.

/// 커서 방식으로 나눠 받은 목록 한 묶음(찜 · 저장한 일정용). docs/api.md "커서 페이징" 참고.
/// `nextCursor` 가 null 이면 더 받을 것이 없습니다. 커서의 뜻은 풀지 말고 그대로 돌려보냅니다.
class CursorPage<T> {
  final List<T> items;
  final int? nextCursor;

  const CursorPage({required this.items, required this.nextCursor});

  // fromJson: 서버가 준 JSON(글자로 된 Map)을 Dart 클래스로 바꿉니다. parse 는 항목 하나를 바꾸는 함수를 밖에서 받은 것이고, as 는 "이 값은 이 종류다"라고 알리는 형 변환입니다. ? 가 붙은 int? 는 값이 없을 수도(null) 있다는 뜻입니다.
  factory CursorPage.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) {
    return CursorPage(
      items: (json['items'] as List).map((e) => parse(e as Map<String, dynamic>)).toList(),
      nextCursor: json['next_cursor'] as int?,
    );
  }
}
