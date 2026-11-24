// HomeController 의 단위 테스트입니다. 날씨 · 선택지 · 추천 목록을 채우는지, 날씨만 실패해도 홈이 열리는지, 목록 요청이 실패하면 오류를 갖는지 확인합니다.

import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/api/api_client.dart';
import 'package:jeju_hanbakwi/controllers/home_controller.dart';
import 'package:jeju_hanbakwi/models/spot.dart';
import 'package:jeju_hanbakwi/models/weather.dart';

import '../support.dart';

// getWeather 만 실패하게 만든 가짜 서버입니다. 날씨가 꺼져도 홈은 열려야 하는 규칙을 시험하려는 것입니다.
/// 날씨 서비스만 꺼진 서버.
class NoWeatherApi extends FakeApi {
  NoWeatherApi({super.spots});

  @override
  Future<Weather> getWeather() async => throw const ApiException('날씨 서비스 꺼짐', statusCode: 503);
}

void main() {
  final spots = [Spot.fromJson(spotJson(id: 1, title: '관광지 1'))];

  // 정상 불러오기와 비 오는 날 실내 요청(indoor=true)을 확인합니다.
  test('load: 날씨·선택지·추천 목록을 모두 채운다', () async {
    final c = HomeController(api: FakeApi(spots: spots, rainy: false));
    expect(c.loading, true);

    await c.load();

    expect(c.loading, false);
    expect(c.error, isNull);
    expect(c.weather?.rainyToday, false);
    expect(c.meta?.themes, ['바다', '오름']);
    expect(c.spots.length, 1);
  });

  test('비 오는 날은 실내(indoor=true), 아니면 실외로 8곳을 요청한다', () async {
    final rainy = FakeApi(spots: spots, rainy: true);
    await HomeController(api: rainy).load();
    expect(rainy.spotCalls.single, containsPair('indoor', true));
    expect(rainy.spotCalls.single, containsPair('size', 8));

    final dry = FakeApi(spots: spots, rainy: false);
    await HomeController(api: dry).load();
    expect(dry.spotCalls.single, containsPair('indoor', false));
  });

  // 일부 실패: 날씨만 실패하면 날씨만 null 이고 목록은 오며, 목록 요청이 실패하면 오류 문구가 남는지 확인합니다.
  test('날씨가 실패해도 추천 목록은 불러온다(날씨만 null)', () async {
    final c = HomeController(api: NoWeatherApi(spots: spots));

    await c.load();

    expect(c.weather, isNull);
    expect(c.error, isNull);
    expect(c.spots.length, 1);
  });

  test('추천 목록 요청이 실패하면 오류 문구를 갖는다', () async {
    final c = HomeController(api: FakeApi(spots: spots, failSpots: true));

    await c.load();

    expect(c.error, contains('서버에 연결할 수 없어요'));
    expect(c.loading, false);
  });
}
