import 'package:jeju_hanbakwi/api/api_client.dart';
import 'package:jeju_hanbakwi/models/spot.dart';
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
  FakeApi({this.spots = const [], this.total, this.rainy = true, this.failSpots = false}) : super(baseUrl: 'http://fake');

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
