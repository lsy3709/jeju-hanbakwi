import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jeju_hanbakwi/api/api_client.dart';

import 'support.dart';

/// 한글이 깨지지 않도록 UTF-8 로 응답을 만들어 주는 도우미.
http.Response jsonResponse(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('getSpots: 비어 있는 조건은 빼고 쿼리 문자열을 만든다', () async {
    late Uri seen;
    final api = ApiClient(
      baseUrl: 'http://fake',
      client: MockClient((req) async {
        seen = req.url;
        return jsonResponse({'items': [spotJson()], 'total': 1, 'page': 2, 'size': 8});
      }),
    );
    final page = await api.getSpots(q: ' 폭포 ', theme: '바다', area: '', indoor: true, page: 2, size: 8);
    expect(seen.path, '/spots');
    expect(seen.queryParameters, {'q': '폭포', 'theme': '바다', 'indoor': 'true', 'page': '2', 'size': '8'});
    expect(page.items.single.title, '성산일출봉');
  });

  test('오류 응답의 {detail} 을 ApiException 으로 던진다', () async {
    final api = ApiClient(
      baseUrl: 'http://fake',
      client: MockClient((req) async => jsonResponse({'detail': '관광지를 찾을 수 없어요'}, 404)),
    );
    await expectLater(
      api.getSpot(999),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', '관광지를 찾을 수 없어요')
            .having((e) => e.statusCode, 'status', 404),
      ),
    );
  });

  test('서버에 닿지 못하면 안내 문구가 담긴 ApiException', () async {
    final api = ApiClient(
      baseUrl: 'http://fake',
      client: MockClient((req) async => throw http.ClientException('연결 거부')),
    );
    await expectLater(
      api.getMeta(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', contains('서버에 연결할 수 없어요'))
            .having((e) => e.statusCode, 'status', isNull),
      ),
    );
  });
}
