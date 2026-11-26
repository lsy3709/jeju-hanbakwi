import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_hanbakwi/map3d.dart';

/// 앱이 웹뷰로 띄울 3D 지도 주소 만들기 — 탐색 화면의 필터를 웹과 같은 쿼리로 넘깁니다.
void main() {
  const web = 'http://10.0.2.2:3000';

  test('필터가 없으면 쿼리 없이 /embed/map3d', () {
    expect(map3dUrl(web), 'http://10.0.2.2:3000/embed/map3d');
  });
  test('고른 필터만 쿼리로 붙인다', () {
    final uri = Uri.parse(map3dUrl(web, q: '폭포', theme: '바다', indoor: false));
    expect(uri.path, '/embed/map3d');
    expect(uri.queryParameters, {'q': '폭포', 'theme': '바다', 'indoor': 'false'});
  });
  test('빈 글자와 null 은 뺀다', () {
    expect(map3dUrl(web, q: '  ', area: null, category: ''), 'http://10.0.2.2:3000/embed/map3d');
  });
  test('판타지 지도는 style=fantasy 를 붙인다', () {
    final uri = Uri.parse(map3dUrl(web, theme: '오름', fantasy: true));
    expect(uri.path, '/embed/map3d');
    expect(uri.queryParameters, {'theme': '오름', 'style': 'fantasy'});
    expect(map3dUrl(web, fantasy: true), 'http://10.0.2.2:3000/embed/map3d?style=fantasy');
  });
  test('지역과 분류, 실내도 넘긴다', () {
    final uri = Uri.parse(map3dUrl(web, area: '서귀포시', category: '관광지', indoor: true));
    expect(uri.queryParameters, {'area': '서귀포시', 'category': '관광지', 'indoor': 'true'});
  });
}
