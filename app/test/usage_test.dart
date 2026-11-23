import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jeju_hanbakwi/api/api_client.dart';
import 'package:jeju_hanbakwi/app.dart';
import 'package:jeju_hanbakwi/auth/auth_service.dart';
import 'package:jeju_hanbakwi/format.dart';
import 'package:jeju_hanbakwi/models/usage.dart';
import 'package:jeju_hanbakwi/widgets/usage_panel.dart';

import 'support.dart';

Map<String, dynamic> summaryJson({int requests = 12, int tokens = 46500}) => {
  'requests': requests,
  'ai_requests': 10,
  'rule_requests': 2,
  'user_key_requests': 3,
  'server_key_requests': 7,
  'tokens_in': 41200,
  'tokens_out': 5300,
  'tokens_total': tokens,
  'server_tokens_total': 31000,
};

Map<String, dynamic> reportJson({int requests = 12}) => {
  'days': 30,
  'total': summaryJson(requests: requests),
  'today': summaryJson(requests: 2, tokens: 3515),
  'by_day': [
    {'date': '2026-12-02', ...summaryJson(requests: 2, tokens: 3515)},
    {'date': '2026-12-01', ...summaryJson(requests: 10, tokens: 42985)},
  ],
  'by_user': null,
  'truncated': false,
};

void main() {
  test('formatCount: 세 자리마다 쉼표', () {
    expect(formatCount(0), '0');
    expect(formatCount(46500), '46,500');
    expect(formatCount(1234567), '1,234,567');
  });

  test('UsageReport.fromJson: 합계 · 오늘 · 날짜별을 읽는다', () {
    final report = UsageReport.fromJson(reportJson());
    expect(report.days, 30);
    expect(report.total.requests, 12);
    expect(report.total.aiRequests, 10);
    expect(report.total.tokensTotal, 46500);
    expect(report.total.serverTokensTotal, 31000);
    expect(report.today.requests, 2);
    expect(report.byDay.map((d) => d.date), ['2026-12-02', '2026-12-01']);
    expect(report.truncated, isFalse);
  });

  test('getMyAiUsage: 기간을 쿼리로 보내고 토큰을 붙인다', () async {
    late http.BaseRequest seen;
    final api = ApiClient(
      baseUrl: 'http://fake',
      tokenProvider: () => 'my-token',
      client: MockClient((req) async {
        seen = req;
        return http.Response.bytes(
          utf8.encode(jsonEncode(reportJson())),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final report = await api.getMyAiUsage(days: 7);
    expect(seen.url.path, '/me/ai-usage');
    expect(seen.url.queryParameters, {'days': '7'});
    expect(seen.headers['Authorization'], 'Bearer my-token');
    expect(report.total.requests, 12);
  });

  Future<void> pumpPanel(
    WidgetTester tester,
    Future<UsageReport> Function(int days) load,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            // 새 key: 같은 테스트에서 두 번 띄울 때 앞의 상태를 이어받지 않게 합니다.
            child: UsagePanel(key: UniqueKey(), load: load),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('UsagePanel: 합계 · 오늘 · 날짜별을 보여 주고, 기간을 바꾸면 다시 불러온다', (
    tester,
  ) async {
    final asked = <int>[];
    await pumpPanel(tester, (days) async {
      asked.add(days);
      return UsageReport.fromJson(reportJson());
    });
    expect(asked, [30]);
    expect(find.text('46,500'), findsOneWidget);
    expect(find.textContaining('AI 10 · 간단 추천 2'), findsOneWidget);
    expect(find.textContaining('오늘: 요청 2회 · 토큰 3,515'), findsOneWidget);
    expect(find.text('2026-12-01'), findsOneWidget);

    await tester.tap(find.text('7일'));
    await tester.pumpAndSettle();
    expect(asked, [30, 7]);
  });

  testWidgets('UsagePanel: 기록이 없으면 안내, 실패하면 문구와 다시 시도', (tester) async {
    await pumpPanel(
      tester,
      (days) async => UsageReport.fromJson(reportJson(requests: 0)),
    );
    expect(find.textContaining('쓴 기록이 없어요'), findsOneWidget);

    var fail = true;
    await pumpPanel(tester, (days) async {
      if (fail) throw const ApiException('AI 사용량을 읽지 못했습니다.', statusCode: 503);
      return UsageReport.fromJson(reportJson());
    });
    expect(find.text('AI 사용량을 읽지 못했습니다.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('46,500'), findsOneWidget);
  });

  testWidgets('설정: 로그인하지 않았으면 사용량 대신 로그인 안내', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      JejuApp(api: PlanApi(), auth: AuthService.disabled()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 플래너').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    expect(find.text('내 AI 사용량'), findsOneWidget);
    expect(find.textContaining('로그인하면 내 사용량을 볼 수 있어요'), findsOneWidget);
  });
}
