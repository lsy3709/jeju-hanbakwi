import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/format.dart';

/// 웹(web/src/lib/format.test.ts)과 같은 규칙·같은 사례로 맞춘 날짜 표기 테스트입니다.
void main() {
  test('formatDate: 요일을 붙인다', () => expect(formatDate('2026-12-01'), '12월 1일 (화)'));
  test('formatDate: 금요일 사례', () => expect(formatDate('2026-11-20'), '11월 20일 (금)'));
  test('formatDate: null 이거나 모양이 틀리면 null', () {
    expect(formatDate(null), isNull);
    expect(formatDate('어제쯤'), isNull);
  });
  test('dayTitle: 일차 제목', () {
    expect(dayTitle(1, '2026-12-01'), '1일차 · 12월 1일 (화)');
    expect(dayTitle(1, '2026-11-20'), '1일차 · 11월 20일 (금)');
    expect(dayTitle(2, null), '2일차');
  });
  test('formatSavedAt: 저장 시각은 기기 시간대의 날짜로 보여 준다', () {
    // 기기 시간 12월 2일 0시 30분 = 한국에서는 UTC 로 12월 1일. 글자만 자르면 하루 전이 나옵니다.
    final savedAt = DateTime(2026, 12, 2, 0, 30).toUtc().toIso8601String();
    expect(formatSavedAt(savedAt), '2026년 12월 2일');
  });
  test('formatSavedAt: 이상한 값이면 빈 문자열', () => expect(formatSavedAt('어제쯤'), ''));

  group('distanceText (거리 표시)', () {
    test('100m 안쪽은 바로 근처', () => expect(distanceText(0), '바로 근처'));
    test('1km 안쪽은 미터로', () {
      expect(distanceText(0.3), '약 300m');
      expect(distanceText(0.9), '약 900m');
    });
    test('1km 부터는 킬로미터로', () {
      expect(distanceText(1), '약 1.0km');
      expect(distanceText(12.34), '약 12.3km');
    });
  });
}
