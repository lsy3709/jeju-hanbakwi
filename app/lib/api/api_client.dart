// 서버와 통하는 유일한 문: 화면과 컨트롤러는 http 를 직접 부르지 않고 여기 메서드만 씁니다.
// 새 서버 주소를 쓰려면 docs/api.md 를 먼저 고치고 이 파일에 메서드를 하나 더하세요.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/cursor_page.dart';
import '../models/itinerary.dart';
import '../models/spot.dart';
import '../models/trip.dart';
import '../models/usage.dart';
import '../models/weather.dart';

/// 서버가 돌려준 오류(또는 서버에 닿지 못한 상황)를 한국어 메시지로 담습니다.
class ApiException implements Exception {
  final String message;
  final int? statusCode; // 서버에 닿지 못했으면 null

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// 로그인한 사용자의 액세스 토큰을 돌려주는 함수. 로그아웃 상태면 null.
typedef TokenProvider = String? Function();

/// 설정 화면에 넣은 내 AI 키를 돌려주는 함수. 넣지 않았으면 null.
typedef AiKeyProvider = String? Function();

/// 서버(FastAPI)와 통하는 **유일한 문**. docs/api.md 의 주소를 하나씩 메서드로 만들었습니다.
/// 화면과 컨트롤러는 http 를 직접 부르지 않고 여기 메서드(getSpots, plan, saveTrip …)만 씁니다.
/// 서버 오류는 모두 한국어 메시지를 담은 [ApiException] 으로 바뀌어 나옵니다.
/// [client] 를 밖에서 넣을 수 있게 해 두면 테스트에서 가짜 서버를 꽂을 수 있습니다.
class ApiClient {
  final http.Client _client;
  final String baseUrl;
  final TokenProvider? tokenProvider;
  final AiKeyProvider? aiKeyProvider;

  ApiClient({http.Client? client, String? baseUrl, this.tokenProvider, this.aiKeyProvider})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? Config.apiUrl;

  // ---- 공개 주소 ----

  Future<Meta> getMeta() async => Meta.fromJson(await _get('/meta') as Map<String, dynamic>);

  Future<SpotPage> getSpots({
    String? q,
    String? theme,
    String? area,
    String? category,
    bool? indoor,
    int? cursor, // 앞 응답의 next_cursor. 처음에는 null
    int size = 20,
  }) async {
    // 비어 있는 조건은 아예 보내지 않습니다.
    final query = <String, String>{
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (theme != null && theme.isNotEmpty) 'theme': theme,
      if (area != null && area.isNotEmpty) 'area': area,
      if (category != null && category.isNotEmpty) 'category': category,
      if (indoor != null) 'indoor': indoor.toString(),
      if (cursor != null) 'cursor': '$cursor',
      'size': '$size',
    };
    return SpotPage.fromJson(await _get('/spots', query: query) as Map<String, dynamic>);
  }

  Future<Spot> getSpot(int id) async => Spot.fromJson(await _get('/spots/$id') as Map<String, dynamic>);

  Future<Weather> getWeather() async => Weather.fromJson(await _get('/weather') as Map<String, dynamic>);

  Future<PlanResult> plan({
    required String message,
    int days = 2,
    String? companions,
    String? startDate,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'days': days,
      if (companions != null && companions.isNotEmpty) 'companions': companions,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
    };
    // 내 AI 키가 있으면 이 요청에만 함께 보냅니다(다른 주소에는 붙이지 않습니다). 서버는 저장하지 않습니다.
    final aiKey = aiKeyProvider?.call();
    final headers = (aiKey != null && aiKey.isNotEmpty) ? {'X-Gemini-Key': aiKey} : null;
    return PlanResult.fromJson(await _send('POST', '/agent/plan', body: body, headers: headers) as Map<String, dynamic>);
  }

  /// 내 AI 키가 쓸 수 있는 키인지 서버에 묻습니다.
  Future<({bool ok, String message})> checkAiKey(String key) async {
    final json = await _send('POST', '/agent/key-check', headers: {'X-Gemini-Key': key}) as Map<String, dynamic>;
    return (ok: json['ok'] == true, message: (json['message'] ?? '') as String);
  }

  // ---- 로그인이 필요한 주소 ----

  Future<Map<String, dynamic>> getMe() async => await _get('/me') as Map<String, dynamic>;

  /// 내 AI 사용량(최근 [days] 일). 로그인이 필요합니다.
  Future<UsageReport> getMyAiUsage({int days = 30}) async =>
      UsageReport.fromJson(await _get('/me/ai-usage', query: {'days': '$days'}) as Map<String, dynamic>);

  /// 찜한 곳 한 묶음. 정지된 계정은 403 + 서버 문구가 ApiException 으로 나옵니다.
  Future<CursorPage<Spot>> getFavorites({int? cursor, int size = 20}) async {
    final json = await _get('/me/favorites', query: _cursorQuery(cursor, size)) as Map<String, dynamic>;
    return CursorPage.fromJson(json, Spot.fromJson);
  }

  /// 이 한 곳을 찜했는지. 찜 목록은 나뉘어 오므로 목록에서 찾지 않고 따로 묻습니다.
  Future<bool> hasFavorite(int spotId) async {
    final json = await _get('/me/favorites/$spotId') as Map<String, dynamic>;
    return json['favorite'] == true;
  }

  Future<void> addFavorite(int spotId) async {
    await _send('POST', '/me/favorites', body: {'spot_id': spotId});
  }

  Future<void> removeFavorite(int spotId) async {
    await _send('DELETE', '/me/favorites/$spotId');
  }

  /// 저장한 일정 한 묶음(최근 저장한 순).
  Future<CursorPage<Trip>> getTrips({int? cursor, int size = 20}) async {
    final json = await _get('/me/trips', query: _cursorQuery(cursor, size)) as Map<String, dynamic>;
    return CursorPage.fromJson(json, Trip.fromJson);
  }

  Map<String, String> _cursorQuery(int? cursor, int size) => {
        if (cursor != null) 'cursor': '$cursor',
        'size': '$size',
      };

  Future<Trip> saveTrip({required String title, required List<ItineraryDay> itinerary}) async {
    final body = {'title': title, 'itinerary': itinerary.map((d) => d.toJson()).toList()};
    return Trip.fromJson(await _send('POST', '/me/trips', body: body) as Map<String, dynamic>);
  }

  Future<void> deleteTrip(int id) async {
    await _send('DELETE', '/me/trips/$id');
  }

  // ---- 공통 처리 ----

  Future<dynamic> _get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: (query == null || query.isEmpty) ? null : query);
    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';
    if (headers != null) request.headers.addAll(headers);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    // 로그인 상태면 토큰을 붙입니다. 공개 주소에 붙어도 서버는 무시합니다.
    final token = tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request).timeout(const Duration(seconds: 60)));
    } catch (_) {
      // 서버가 꺼져 있거나 주소가 틀린 경우. 앱이 죽지 않고 안내 문구를 보여 주게 합니다.
      throw const ApiException('서버에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.');
    }

    // 한글이 깨지지 않도록 바이트를 직접 UTF-8 로 풉니다.
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204 || text.isEmpty) return null;
      return jsonDecode(text);
    }
    throw ApiException(_detailOf(text, response.statusCode), statusCode: response.statusCode);
  }

  /// 오류 본문 `{detail: "..."}` 에서 설명을 꺼냅니다. 모양이 다르면 기본 문구.
  String _detailOf(String text, int status) {
    try {
      final json = jsonDecode(text);
      if (json is Map && json['detail'] is String) return json['detail'] as String;
    } catch (_) {}
    if (status == 401) return '로그인이 필요해요.';
    if (status == 404) return '찾을 수 없어요.';
    if (status == 503) return '지금은 이 기능을 쓸 수 없어요. 잠시 후 다시 시도해 주세요.';
    return '문제가 생겼어요. (오류 $status)';
  }

  void close() => _client.close();
}
