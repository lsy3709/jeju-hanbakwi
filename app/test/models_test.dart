import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/models/cursor_page.dart';
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

    test('image_credit, image_source_url 이 있으면 읽는다', () {
      final json = spotJson(imageUrl: 'https://example.com/a.jpg');
      json['image_credit'] = 'Jane Doe · CC BY-SA 4.0';
      json['image_source_url'] = 'https://example.com/photo';
      final spot = Spot.fromJson(json);
      expect(spot.imageCredit, 'Jane Doe · CC BY-SA 4.0');
      expect(spot.imageSourceUrl, 'https://example.com/photo');
    });

    test('image_credit, image_source_url 이 없거나 null 이면 null', () {
      final spot = Spot.fromJson(spotJson()); // 두 칸이 아예 없는 응답
      expect(spot.imageCredit, isNull);
      expect(spot.imageSourceUrl, isNull);
      final json = spotJson()..addAll({'image_credit': null, 'image_source_url': null});
      expect(Spot.fromJson(json).imageCredit, isNull);
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

  test('SpotPage.fromJson: 첫 묶음은 total 이 숫자', () {
    final page = SpotPage.fromJson({
      'items': [spotJson(id: 1), spotJson(id: 2, title: '한라산')],
      'next_cursor': 2,
      'total': 42,
      'size': 20,
    });
    expect(page.items.map((s) => s.title), ['성산일출봉', '한라산']);
    expect(page.total, 42);
    expect(page.nextCursor, 2);
  });

  test('SpotPage.fromJson: 마지막 묶음은 total·next_cursor 가 null', () {
    final page = SpotPage.fromJson({'items': [spotJson(id: 9)], 'next_cursor': null, 'total': null, 'size': 20});
    expect(page.total, isNull);
    expect(page.nextCursor, isNull);
  });

  test('CursorPage.fromJson', () {
    final page = CursorPage.fromJson({'items': [spotJson(id: 3)], 'next_cursor': 31}, Spot.fromJson);
    expect(page.items.single.id, 3);
    expect(page.nextCursor, 31);
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

  test('Weather.fromJson: 기온·강수확률이 null 이어도 죽지 않는다', () {
    // jsonDecode 로 값을 null 로 바꿀 수 있는(수정 가능한) 사본을 만듭니다.
    final json = jsonDecode(jsonEncode(weatherJson())) as Map<String, dynamic>;
    final day = ((json['areas'] as List).single as Map)['days'][0] as Map;
    day['temp_min'] = null;
    day['temp_max'] = null;
    day['rain_prob'] = null;
    final parsed = Weather.fromJson(json).areas.single.days.single;
    expect(parsed.tempMin, isNull);
    expect(parsed.tempMax, isNull);
    expect(parsed.rainProb, isNull);
    expect(parsed.label, '비');
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
      expect(trip.savedDate, '2026년 12월 2일');
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
