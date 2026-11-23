import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../format.dart';
import '../models/usage.dart';
import '../theme.dart';

/// AI 사용량을 보여 주는 묶음: 기간 고르기 → 합계 → 오늘 → 날짜별.
/// [load] 는 "최근 며칠"을 받아 사용량을 불러오는 함수입니다(화면이 ApiClient 의 메서드를 넘깁니다).
class UsagePanel extends StatefulWidget {
  const UsagePanel({super.key, required this.load});
  final Future<UsageReport> Function(int days) load;

  @override
  State<UsagePanel> createState() => _UsagePanelState();
}

class _UsagePanelState extends State<UsagePanel> {
  static const _periods = [7, 30, 90];
  int _days = 30;
  bool _loading = true;
  String? _error;
  UsageReport? _report;
  int _requestId = 0; // 기간을 빨리 바꿨을 때 늦게 온 응답을 버리려고 셉니다

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await widget.load(_days);
      if (!mounted || id != _requestId) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [for (final d in _periods) ButtonSegment(value: d, label: Text('$d일'))],
          selected: {_days},
          onSelectionChanged: (s) {
            _days = s.first;
            _load();
          },
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.primaryDark)),
              TextButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          )
        else
          _content(_report!),
      ],
    );
  }

  Widget _content(UsageReport report) {
    final total = report.total;
    if (total.requests == 0) {
      return const Text('이 기간에는 AI 플래너를 쓴 기록이 없어요.', style: TextStyle(color: AppColors.muted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stat('요청', formatCount(total.requests), 'AI ${formatCount(total.aiRequests)} · 간단 추천 ${formatCount(total.ruleRequests)}'),
        _stat('토큰', formatCount(total.tokensTotal), '보낸 것 ${formatCount(total.tokensIn)} · 받은 것 ${formatCount(total.tokensOut)}'),
        const SizedBox(height: 4),
        Text(
          '오늘: 요청 ${formatCount(report.today.requests)}회 · 토큰 ${formatCount(report.today.tokensTotal)}',
          style: const TextStyle(color: AppColors.muted),
        ),
        if (report.truncated)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('기록이 많아 최근 1,000건만 더했어요. 기간을 줄이면 정확해져요.'),
          ),
        const Divider(height: 24),
        for (final day in report.byDay)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(day.date)),
                Text('${formatCount(day.summary.requests)}회 · 토큰 ${formatCount(day.summary.tokensTotal)}'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stat(String label, String value, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: 56, child: Text(label, style: const TextStyle(color: AppColors.muted))),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Expanded(child: Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
        ],
      ),
    );
  }
}
