import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../app_scope.dart';
import '../models/itinerary.dart';
import '../theme.dart';
import '../widgets/itinerary_view.dart';
import '../widgets/login_prompt.dart';
import '../widgets/state_views.dart';
import 'spot_detail_screen.dart';

/// AI 플래너: 입력(하고 싶은 여행 · 며칠 · 누구와 · 시작 날짜) → 결과(설명 + 일자별 타임라인).
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  static const _companions = ['혼자', '친구', '연인', '아이와', '부모님'];

  final _message = TextEditingController();
  int _days = 2;
  String? _companion;
  DateTime? _startDate;

  bool _loading = false;
  String? _error;
  PlanResult? _result;

  ShellController? _shell;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shell == null) {
      _shell = AppScope.of(context).shell;
      _shell!.addListener(_onShellChanged);
    }
  }

  @override
  void dispose() {
    _shell?.removeListener(_onShellChanged);
    _message.dispose();
    super.dispose();
  }

  /// 상세 화면의 "이 장소로 일정 짜기" 가 보낸 문구를 입력창에 미리 채웁니다.
  void _onShellChanged() {
    final prefill = _shell!.plannerPrefill;
    if (prefill != null) {
      _message.text = prefill;
      _shell!.plannerPrefill = null; // 한 번 쓰면 비웁니다.
    }
  }

  String _dateText(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      showSnack(context, '하고 싶은 여행을 적어 주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AppScope.of(context).api.plan(
            message: text,
            days: _days,
            companions: _companion,
            startDate: _startDate == null ? null : _dateText(_startDate!),
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final scope = AppScope.of(context);
    if (!scope.auth.loggedIn) {
      await showLoginPrompt(context);
      return;
    }
    final title = await _askTitle();
    if (title == null || !mounted) return;
    try {
      await scope.api.saveTrip(title: title, itinerary: _result!.itinerary);
      scope.shell.tripsChanged();
      if (mounted) showSnack(context, '내 여행에 저장했어요.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  Future<String?> _askTitle() {
    final controller = TextEditingController(text: _message.text.trim().length > 20 ? '제주 여행' : _message.text.trim());
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('일정 제목'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '예: 부모님과 제주')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) Navigator.pop(dialogContext, t);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _openSpot(int spotId) {
    // 일정의 spot_id 는 항상 sources 안에 있으므로, 있으면 바로 보여 줍니다.
    final spot = _result?.sources.where((s) => s.id == spotId).firstOrNull;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SpotDetailScreen(spotId: spotId, initial: spot)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CenteredBody(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('AI 플래너', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '예: 부모님과 많이 걷지 않는 코스로 가고 싶어요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('며칠 여행인가요?', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 1, label: Text('1일')),
                ButtonSegment(value: 2, label: Text('2일')),
                ButtonSegment(value: 3, label: Text('3일')),
              ],
              selected: {_days},
              onSelectionChanged: (s) => setState(() => _days = s.first),
            ),
            const SizedBox(height: 16),
            const Text('누구와 가나요?', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _companions)
                  ChoiceChip(
                    label: Text(c),
                    selected: _companion == c,
                    labelStyle: TextStyle(color: _companion == c ? Colors.white : AppColors.ink),
                    // 다시 누르면 선택 해제(선택 사항이라서)
                    onSelected: (on) => setState(() => _companion = on ? c : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_startDate == null ? '시작 날짜 (선택)' : _dateText(_startDate!)),
                ),
                if (_startDate != null)
                  IconButton(tooltip: '날짜 지우기', onPressed: () => setState(() => _startDate = null), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('일정 짜기'),
            ),
            const SizedBox(height: 24),
            _resultArea(),
          ],
        ),
      ),
    );
  }

  Widget _resultArea() {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(32), child: LoadingView(message: '일정을 짜는 중이에요. 잠시만 기다려 주세요…'));
    }
    if (_error != null) return ErrorView(message: _error!, onRetry: _submit);
    final result = _result;
    if (result == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.isSimple)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text('간단 추천', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
          ),
        if (result.answer.isNotEmpty) Text(result.answer, style: const TextStyle(height: 1.6)),
        const SizedBox(height: 16),
        ItineraryView(days: result.itinerary, onSpotTap: _openSpot),
        const SizedBox(height: 4),
        OutlinedButton.icon(onPressed: _save, icon: const Icon(Icons.bookmark_add_outlined), label: const Text('내 여행에 저장')),
      ],
    );
  }
}
