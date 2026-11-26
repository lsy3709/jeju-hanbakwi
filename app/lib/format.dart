// 날짜 표기 함수 모음. 웹(web/src/lib/format.ts)과 같은 규칙·같은 결과를 냅니다.
// 순수 함수(같은 입력 → 같은 출력)라서 테스트하기 쉽습니다. intl 패키지 없이 직접 만듭니다.

const _weekdays = ['월', '화', '수', '목', '금', '토', '일']; // DateTime.weekday: 1=월 ... 7=일

/// "2026-12-01" → "12월 1일 (화)". 날짜가 없거나 모양이 틀리면 null.
String? formatDate(String? date) {
  if (date == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(date);
  if (match == null) return null;
  // match.group(1)! 의 ! 는 "정규식이 맞았으니 null 이 아님"이라는 약속입니다.
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

/// 세 자리마다 쉼표: 46500 → "46,500". (AI 사용량의 요청 수 · 토큰 수)
String formatCount(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// 거리(km)를 읽기 쉬운 글로. 1km 안쪽은 미터로, 그 밖은 킬로미터로 적습니다.
String distanceText(double km) {
  if (km < 0.1) return '바로 근처';
  if (km < 1) return '약 ${(km * 10).round() * 100}m';
  return '약 ${km.toStringAsFixed(1)}km';
}
