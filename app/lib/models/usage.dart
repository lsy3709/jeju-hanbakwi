// AI 사용량(요청 수 · 토큰 수)을 담는 모양입니다. 설정 화면의 사용량 패널이 보여 주고, 서버가 준 숫자를 그대로 담기만 합니다.
// 토큰(token)은 AI 가 글을 읽고 쓰는 단위로, 사용량의 크기를 나타냅니다.

/// AI 사용량을 더한 값. (docs/api.md 의 "AI 사용량")
class UsageSummary {
  final int requests;
  final int aiRequests;
  final int ruleRequests;
  final int userKeyRequests;
  final int serverKeyRequests;
  // tokensIn 은 AI 에게 보낸 글의 토큰 수, tokensOut 은 AI 가 쓴 글의 토큰 수입니다.
  final int tokensIn;
  final int tokensOut;
  final int tokensTotal;

  /// 서버 키로 쓴 토큰(서비스가 내는 몫).
  final int serverTokensTotal;

  const UsageSummary({
    required this.requests,
    required this.aiRequests,
    required this.ruleRequests,
    required this.userKeyRequests,
    required this.serverKeyRequests,
    required this.tokensIn,
    required this.tokensOut,
    required this.tokensTotal,
    required this.serverTokensTotal,
  });

  factory UsageSummary.fromJson(Map<String, dynamic> json) => UsageSummary(
        requests: json['requests'] as int,
        aiRequests: json['ai_requests'] as int,
        ruleRequests: json['rule_requests'] as int,
        userKeyRequests: json['user_key_requests'] as int,
        serverKeyRequests: json['server_key_requests'] as int,
        tokensIn: json['tokens_in'] as int,
        tokensOut: json['tokens_out'] as int,
        tokensTotal: json['tokens_total'] as int,
        serverTokensTotal: json['server_tokens_total'] as int,
      );
}

/// 하루치 사용량.
class UsageDay {
  final String date; // "2026-12-01" (한국 날짜)
  final UsageSummary summary;

  const UsageDay({required this.date, required this.summary});

  factory UsageDay.fromJson(Map<String, dynamic> json) =>
      UsageDay(date: json['date'] as String, summary: UsageSummary.fromJson(json));
}

/// GET /me/ai-usage 응답: 기간 합계 · 오늘 · 날짜별(최근 날짜가 먼저).
class UsageReport {
  final int days;
  final UsageSummary total;
  final UsageSummary today;
  final List<UsageDay> byDay;

  /// 기록이 많아 최근 1000건만 더했으면 true.
  final bool truncated;

  const UsageReport({required this.days, required this.total, required this.today, required this.byDay, required this.truncated});

  factory UsageReport.fromJson(Map<String, dynamic> json) => UsageReport(
        days: json['days'] as int,
        total: UsageSummary.fromJson(json['total'] as Map<String, dynamic>),
        today: UsageSummary.fromJson(json['today'] as Map<String, dynamic>),
        byDay: (json['by_day'] as List).map((e) => UsageDay.fromJson(e as Map<String, dynamic>)).toList(),
        // == true 로 비교하면 값이 없거나 null 이어도 false 가 됩니다. 앞의 as 형 변환보다 안전합니다.
        truncated: json['truncated'] == true,
      );
}
