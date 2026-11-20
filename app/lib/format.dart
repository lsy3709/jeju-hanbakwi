// 날짜 표기 함수 모음. 웹(web/src/lib/format.ts)과 같은 규칙·같은 결과를 냅니다.
// 순수 함수(같은 입력 → 같은 출력)라서 테스트하기 쉽습니다. intl 패키지 없이 직접 만듭니다.

const _weekdays = ['월', '화', '수', '목', '금', '토', '일']; // DateTime.weekday: 1=월 ... 7=일

/// "2026-12-01" → "12월 1일 (화)". 날짜가 없거나 모양이 틀리면 null.
String? formatDate(String? date) {
  if (date == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(date);
  if (match == null) return null;
  final y = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  final d = int.parse(match.group(3)!);
  // 시간대 때문에 하루가 밀리지 않도록 UTC 날짜로 요일을 계산합니다.
  final weekday = _weekdays[DateTime.utc(y, m, d).weekday - 1];
  return '$m월 $d일 ($weekday)';
}

/// 일정 한 날의 제목: "1일차 · 12월 1일 (화)" (날짜가 없으면 "1일차").
String dayTitle(int day, String? date) {
  final text = formatDate(date);
  return text == null ? '$day일차' : '$day일차 · $text';
}

/// 저장 시각(ISO) → "2026년 12월 1일". 잘못된 값이면 빈 문자열.
/// 서버는 세계 표준시(UTC)로 시각을 주므로, 기기 시간대로 바꿔서 날짜를 냅니다.
/// (글자 앞 10자만 자르면 한국의 오전 9시 이전에 저장한 것이 하루 전으로 보입니다)
String formatSavedAt(String iso) {
  final saved = DateTime.tryParse(iso)?.toLocal();
  if (saved == null) return '';
  return '${saved.year}년 ${saved.month}월 ${saved.day}일';
}
