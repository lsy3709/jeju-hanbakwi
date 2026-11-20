import 'dart:async';

import 'package:jeju_hanbakwi/api/api_client.dart';
import 'package:jeju_hanbakwi/models/itinerary.dart';
import 'package:jeju_hanbakwi/models/spot.dart';
import 'package:jeju_hanbakwi/models/trip.dart';
import 'package:jeju_hanbakwi/models/weather.dart';

/// 테스트에서 쓰는 관광지 JSON (docs/api.md 의 Spot 모양).
Map<String, dynamic> spotJson({int id = 1, String title = '성산일출봉', bool indoor = false, String? imageUrl}) => {
  'id': id,
  'title': title,
  'category': '관광지',
  'area': '동부',
  'address': '제주특별자치도 서귀포시 성산읍 일출로 284-12',
  'lat': 33.4581,
  'lng': 126.9426,
  'image_url': imageUrl,
  'overview': '긴 소개 글',
  'one_liner': '한 줄 소개',
  'theme_tags': ['오름', '바다'],
  'indoor': indoor,
};

Map<String, dynamic> weatherJson({bool rainy = true}) => {
  'rainy_today': rainy,
  'message': '오늘 제주는 비 소식이 있어요. 실내 코스를 추천해요.',
  'areas': [
    {
      'area': '제주시',
      'days': [
        {'date': '2026-12-01', 'label': '비', 'icon': 'rain', 'temp_min': 8.1, 'temp_max': 12.4, 'rain_prob': 80},
      ],
    },
  ],
};

/// 서버 없이 화면을 시험하기 위한 가짜 ApiClient. 어떤 조건으로 불렸는지 기록합니다.
class FakeApi extends ApiClient {
  FakeApi({this.spots = const [], this.total, this.rainy = true, this.failSpots = false})
    : super(baseUrl: 'http://fake');

  final List<Spot> spots;
  final int? total;
  final bool rainy;
  bool failSpots;

  final List<Map<String, Object?>> spotCalls = [];

  @override
  Future<Meta> getMeta() async => const Meta(themes: ['바다', '오름'], areas: ['제주시', '동부'], categories: ['관광지']);

  @override
  Future<Weather> getWeather() async => Weather.fromJson(weatherJson(rainy: rainy));

  @override
  Future<SpotPage> getSpots({
    String? q,
    String? theme,
    String? area,
    String? category,
    bool? indoor,
    int page = 1,
    int size = 20,
  }) async {
    spotCalls.add({'q': q, 'theme': theme, 'area': area, 'indoor': indoor, 'page': page, 'size': size});
    if (failSpots) throw const ApiException('서버에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.');
    return SpotPage(items: spots, total: total ?? spots.length, page: page, size: size);
  }
}

/// 응답 시점을 테스트가 정하는 API. gated 를 켜면 getSpots 가 Completer 가 풀릴 때까지 기다립니다.
class GatedApi extends FakeApi {
  GatedApi({super.spots, super.total});
  bool gated = false;
  final pending = <({String? theme, int page, Completer<SpotPage> done})>[];

  @override
  Future<SpotPage> getSpots({
    String? q,
    String? theme,
    String? area,
    String? category,
    bool? indoor,
    int page = 1,
    int size = 20,
  }) {
    if (!gated) {
      return super.getSpots(q: q, theme: theme, area: area, category: category, indoor: indoor, page: page, size: size);
    }
    final done = Completer<SpotPage>();
    pending.add((theme: theme, page: page, done: done));
    return done.future;
  }
}

SpotPage pageOf(List<String> titles, {int total = 2, int page = 1}) => SpotPage(
  items: [for (var i = 0; i < titles.length; i++) Spot.fromJson(spotJson(id: 100 + i + page * 10, title: titles[i]))],
  total: total,
  page: page,
  size: 20,
);

const planDay = ItineraryDay(
  day: 1,
  date: null,
  weather: null,
  items: [ItineraryItem(time: '오전', spotId: 1, title: '성산일출봉', reason: '일출')],
);

/// 일정 짜기·저장만 흉내 내는 가짜 서버. 불린 내용을 기록합니다.
class PlanApi extends FakeApi {
  bool failPlan = false;
  bool failSave = false;
  final planCalls = <Map<String, Object?>>[];
  final saveCalls = <String>[];

  @override
  Future<PlanResult> plan({required String message, int days = 2, String? companions, String? startDate}) async {
    planCalls.add({'message': message, 'days': days, 'companions': companions, 'startDate': startDate});
    if (failPlan) throw const ApiException('지금은 이 기능을 쓸 수 없어요.', statusCode: 503);
    return const PlanResult(mode: 'ai', answer: '추천이에요', itinerary: [planDay], sources: []);
  }

  @override
  Future<Trip> saveTrip({required String title, required List<ItineraryDay> itinerary}) async {
    saveCalls.add(title);
    if (failSave) throw const ApiException('로그인이 필요해요.', statusCode: 401);
    return Trip(id: 1, title: title, itinerary: itinerary, createdAt: '');
  }
}
