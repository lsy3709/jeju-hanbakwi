import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jeju_hanbakwi/api/api_client.dart';
import 'package:jeju_hanbakwi/models/itinerary.dart';

import 'support.dart';

/// 한글이 깨지지 않도록 UTF-8 로 응답을 만들어 주는 도우미.
http.Response jsonResponse(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('내 AI 키', () {
    const key = 'AIzaUserKey_1234567890-abcdefghij';
    final planBody = {'mode': 'ai', 'answer': '좋아요', 'itinerary': <Object>[], 'sources': <Object>[], 'notice': '안내 글'};

    test('plan: 키가 있으면 X-Gemini-Key 헤더로 보내고, notice 를 읽는다', () async {
      late http.BaseRequest seen;
      final api = ApiClient(
        baseUrl: 'http://fake',
        aiKeyProvider: () => key,
        client: MockClient((req) async {
          seen = req;
          return jsonResponse(planBody);
        }),
      );
      final result = await api.plan(message: '바다');
      expect(seen.headers['X-Gemini-Key'], key);
      expect(result.notice, '안내 글');
    });

    test('plan: 키가 없으면 헤더를 보내지 않고, 다른 주소에는 키를 붙이지 않는다', () async {
      final seen = <http.BaseRequest>[];
      String? current;
      final api = ApiClient(
        baseUrl: 'http://fake',
        aiKeyProvider: () => current,
        client: MockClient((req) async {
          seen.add(req);
          if (req.url.path == '/agent/plan') return jsonResponse({...planBody, 'notice': null});
          return jsonResponse({'items': <Object>[], 'next_cursor': null, 'total': 0, 'size': 20});
        }),
      );
      final result = await api.plan(message: '바다');
      expect(seen.last.headers.containsKey('X-Gemini-Key'), isFalse);
      expect(result.notice, isNull);

      current = key;
      await api.getSpots();
      expect(seen.last.headers.containsKey('X-Gemini-Key'), isFalse);
    });

    test('checkAiKey: 헤더로 키를 보내고 ok · message 를 읽는다', () async {
      late http.BaseRequest seen;
      final api = ApiClient(
        baseUrl: 'http://fake',
        client: MockClient((req) async {
          seen = req;
          return jsonResponse({'ok': false, 'message': '쓸 수 없는 키예요.'});
        }),
      );
      final result = await api.checkAiKey(key);
      expect(seen.method, 'POST');
      expect(seen.url.path, '/agent/key-check');
      expect(seen.headers['X-Gemini-Key'], key);
      expect(result.ok, isFalse);
      expect(result.message, '쓸 수 없는 키예요.');
    });
  });

  test('getSpots: 비어 있는 조건은 빼고 쿼리 문자열을 만든다', () async {
    late Uri seen;
    final api = ApiClient(
      baseUrl: 'http://fake',
      client: MockClient((req) async {
        seen = req.url;
        return jsonResponse({'items': [spotJson()], 'next_cursor': 16, 'total': null, 'size': 8});
      }),
    );
    final page = await api.getSpots(q: ' 폭포 ', theme: '바다', area: '', indoor: true, cursor: 8, size: 8);
    expect(seen.path, '/spots');
    expect(seen.queryParameters, {'q': '폭포', 'theme': '바다', 'indoor': 'true', 'cursor': '8', 'size': '8'});
    expect(page.items.single.title, '성산일출봉');
    expect(page.nextCursor, 16);
    expect(page.total, isNull);
  });

  test('getSpots: 처음에는 cursor 를 보내지 않고 page 도 보내지 않는다', () async {
    late Uri seen;
    final api = ApiClient(
      baseUrl: 'http://fake',
      client: MockClient((req) async {
        seen = req.url;
        return jsonResponse({'items': <Object>[], 'next_cursor': null, 'total': 0, 'size': 20});
      }),
    );
    await api.getSpots();
    expect(seen.queryParameters, {'size': '20'});
  });

  test('getFavorites·getTrips: 묶음 응답을 읽고 cursor·size 를 보낸다', () async {
    final seen = <Uri>[];
    final api = ApiClient(
      baseUrl: 'http://fake',
      tokenProvider: () => 't',
      client: MockClient((req) async {
        seen.add(req.url);
        if (req.url.path == '/me/favorites') {
          return jsonResponse({'items': [spotJson(id: 5)], 'next_cursor': 31});
        }
        return jsonResponse({
          'items': [
            {'id': 3, 'title': '제목', 'itinerary': [], 'created_at': '2026-12-01T03:00:00+00:00'},
          ],
          'next_cursor': null,
        });
      }),
    );
    final favs = await api.getFavorites(cursor: 12, size: 10);
    final trips = await api.getTrips();
    expect(seen[0].queryParameters, {'cursor': '12', 'size': '10'});
    expect(seen[1].queryParameters, {'size': '20'});
    expect(favs.items.single.id, 5);
    expect(favs.nextCursor, 31);
    expect(trips.items.single.id, 3);
    expect(trips.nextCursor, isNull);
  });

  test('이용 정지(403): 서버가 준 detail 문구가 그대로 ApiException 에 담긴다', () async {
    const text = '이용이 정지된 계정입니다. 관리자에게 문의해 주세요.';
    final api = ApiClient(
      baseUrl: 'http://fake',
      client: MockClient((req) async => jsonResponse({'detail': text}, 403)),
    );
    for (final call in [api.getFavorites(), api.getTrips()]) {
      await expectLater(
        call,
        throwsA(isA<ApiException>().having((e) => e.message, 'message', text).having((e) => e.statusCode, 'status', 403)),
      );
    }
  });

  test('로그인 상태면 Authorization: Bearer 헤더를 붙인다', () async {
    String? header;
    final api = ApiClient(
      baseUrl: 'http://fake',
      tokenProvider: () => 'abc123',
      client: MockClient((req) async {
        header = req.headers['Authorization'];
        return jsonResponse({'id': 'u1', 'email': 'a@b.com'});
      }),
    );
    final me = await api.getMe();
    expect(header, 'Bearer abc123');
    expect(me['email'], 'a@b.com');
  });

  test('토큰이 없으면 Authorization 헤더를 붙이지 않는다', () async {
    Map<String, String>? headers;
    final api = ApiClient(
      baseUrl: 'http://fake',
      client: MockClient((req) async {
        headers = req.headers;
        return jsonResponse({'themes': <String>[], 'areas': <String>[], 'categories': <String>[]});
      }),
    );
    await api.getMeta();
    expect(headers!.containsKey('Authorization'), false);
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

  test('401 은 isUnauthorized', () async {
    final api = ApiClient(
      baseUrl: 'http://fake',
      client: MockClient((req) async => jsonResponse({'detail': '로그인이 필요해요'}, 401)),
    );
    await expectLater(api.getFavorites(), throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauthorized', true)));
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

  test('POST /agent/plan: 요청 본문과 응답 파싱', () async {
    late Map<String, dynamic> body;
    final api = ApiClient(
      baseUrl: 'http://fake',
      client: MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/agent/plan');
        body = jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;
        return jsonResponse({'mode': 'ai', 'answer': '좋아요', 'itinerary': [], 'sources': []});
      }),
    );
    final plan = await api.plan(message: '부모님과 제주', days: 3, companions: '부모님', startDate: '2026-12-01');
    expect(body, {'message': '부모님과 제주', 'days': 3, 'companions': '부모님', 'start_date': '2026-12-01'});
    expect(plan.mode, 'ai');
  });

  test('찜 추가·삭제, 일정 저장·삭제의 주소와 방법', () async {
    final calls = <String>[];
    final api = ApiClient(
      baseUrl: 'http://fake',
      tokenProvider: () => 't',
      client: MockClient((req) async {
        calls.add('${req.method} ${req.url.path}');
        if (req.method == 'DELETE') return http.Response('', 204);
        if (req.url.path == '/me/favorites') return jsonResponse({'spot_id': 12}, 201);
        return jsonResponse({'id': 3, 'title': '제목', 'itinerary': [], 'created_at': '2026-12-01T03:00:00+00:00'}, 201);
      }),
    );
    await api.addFavorite(12);
    await api.removeFavorite(12);
    final trip = await api.saveTrip(title: '제목', itinerary: <ItineraryDay>[]);
    await api.deleteTrip(3);
    expect(trip.id, 3);
    expect(calls, ['POST /me/favorites', 'DELETE /me/favorites/12', 'POST /me/trips', 'DELETE /me/trips/3']);
  });
}
