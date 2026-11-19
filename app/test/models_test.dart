import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/models/itinerary.dart';
import 'package:jeju_hanbakwi/models/spot.dart';
import 'package:jeju_hanbakwi/models/trip.dart';
import 'package:jeju_hanbakwi/models/weather.dart';

import 'support.dart';

void main() {
  group('Spot.fromJson', () {
    test('모든 필드를 읽는다', () {
      final spot = Spot.fromJson(spotJson(imageUrl: 'https://example.com/a.jpg'));
      expect(spot.id, 1);
      expect(spot.title, '성산일출봉');
      expect(spot.area, '동부');
      expect(spot.lat, 33.4581);
      expect(spot.imageUrl, 'https://example.com/a.jpg');
      expect(spot.themeTags, ['오름', '바다']);
      expect(spot.indoor, false);
    });

    test('image_url 이 null 이면 imageUrl 도 null', () {
      expect(Spot.fromJson(spotJson()).imageUrl, isNull);
    });

    test('lat/lng 가 정수로 와도 double 로 바뀐다', () {
      final json = spotJson();
      json['lat'] = 33;
      json['lng'] = 126;
      final spot = Spot.fromJson(json);
      expect(spot.lat, 33.0);
      expect(spot.lng, 126.0);
    });
  });

  test('SpotPage.fromJson', () {
    final page = SpotPage.fromJson({
      'items': [spotJson(id: 1), spotJson(id: 2, title: '한라산')],
      'total': 42,
      'page': 1,
      'size': 20,
    });
    expect(page.items.map((s) => s.title), ['성산일출봉', '한라산']);
    expect(page.total, 42);
  });

  test('Weather.fromJson', () {
    final w = Weather.fromJson(weatherJson());
    expect(w.rainyToday, true);
    expect(w.areas.single.area, '제주시');
    final day = w.areas.single.days.single;
    expect(day.icon, 'rain');
    expect(day.tempMax, 12.4);
    expect(day.rainProb, 80);
  });

  group('일정', () {
    final json = {
      'mode': 'rule',
      'answer': '설명',
      'itinerary': [
        {
          'day': 1,
          'date': null,
          'weather': null,
          'items': [
            {'time': '오전', 'spot_id': 12, 'title': '아쿠아플라넷 제주', 'reason': '실내 코스'},
          ],
        },
      ],
      'sources': [spotJson(id: 12, title: '아쿠아플라넷 제주')],
    };

    test('PlanResult.fromJson: rule 이면 간단 추천, date/weather 는 null 허용', () {
      final plan = PlanResult.fromJson(json);
      expect(plan.isSimple, true);
      expect(plan.itinerary.single.date, isNull);
      expect(plan.itinerary.single.items.single.spotId, 12);
      expect(plan.sources.single.id, 12);
    });

    test('toJson 은 저장 요청 모양으로 되돌린다', () {
      final plan = PlanResult.fromJson(json);
      final back = plan.itinerary.single.toJson();
      expect(back['day'], 1);
      expect((back['items'] as List).single, {'time': '오전', 'spot_id': 12, 'title': '아쿠아플라넷 제주', 'reason': '실내 코스'});
    });

    test('Trip.savedDate 는 내 기기 시간대의 날짜', () {
      // 서버는 세계 표준시(UTC)로 시각을 줍니다. 기기 시간 12월 2일 0시 30분에 저장한 것은
      // 한국에서는 UTC 로 12월 1일이라, 글자만 자르면 하루 전으로 보입니다.
      final savedAt = DateTime(2026, 12, 2, 0, 30).toUtc().toIso8601String();
      final trip = Trip(id: 1, title: 't', itinerary: const [], createdAt: savedAt);
      expect(trip.savedDate, '2026-12-02');
      expect(const Trip(id: 1, title: 't', itinerary: [], createdAt: '어제쯤').savedDate, '');
    });

    test('Trip.fromJson', () {
      final trip = Trip.fromJson({
        'id': 3,
        'title': '부모님과 제주',
        'itinerary': json['itinerary'],
        'created_at': '2026-12-01T03:00:00+00:00',
      });
      expect(trip.id, 3);
      expect(trip.itinerary, isA<List<ItineraryDay>>());
      expect(trip.itinerary.length, 1);
      expect(trip.createdAt, startsWith('2026-12-01'));
    });
  });
}
