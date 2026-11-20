import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/models/spot.dart';
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
}
