import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../controllers/planner_controller.dart';
import '../theme.dart';
import '../widgets/login_prompt.dart';
import '../widgets/plan_result_view.dart';
import '../widgets/state_views.dart';
import '../widgets/title_dialog.dart';
import 'settings_screen.dart';
import 'spot_detail_screen.dart';

/// AI 플래너 화면: 입력(하고 싶은 여행 · 며칠 · 누구와 · 시작 날짜) → 결과(설명 + 일자별 타임라인).
/// 입력값·요청·저장 상태는 [PlannerController] 가 들고 있고, 이 화면은 그리기와 대화상자만 맡습니다.
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _message = TextEditingController();
  late final PlannerController _controller;
  late final ShellController _shell;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppScope 는 initState 에서 못 꺼내므로, 처음 한 번만 여기서 준비합니다.
    if (_started) return;
    _started = true;
    final scope = AppScope.of(context);
    _controller = PlannerController(api: scope.api);
    _shell = scope.shell..addListener(_onShellChanged);
  }

  @override
  void dispose() {
    _shell.removeListener(_onShellChanged);
    _controller.dispose();
    _message.dispose();
    super.dispose();
  }

  /// 상세 화면의 "이 장소로 일정 짜기" 가 보낸 문구를 입력창에 미리 채웁니다.
  void _onShellChanged() {
    final prefill = _shell.plannerPrefill;
    if (prefill != null) {
      _message.text = prefill;
      _controller.message = prefill;
      _shell.plannerPrefill = null; // 한 번 쓰면 비웁니다.
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) _controller.setStartDate(picked);
  }

  void _submit() {
    if (!_controller.hasMessage) {
      showSnack(context, '하고 싶은 여행을 적어 주세요.');
      return;
    }
    _controller.submit();
  }

  Future<void> _save() async {
    final scope = AppScope.of(context);
    if (!scope.auth.loggedIn) {
      await showLoginPrompt(context);
      return;
    }
    final title = await _askTitle();
    if (title == null || !mounted) return;
    final error = await _controller.save(title);
    if (error == null) scope.shell.tripsChanged(); // "내 여행"이 목록을 다시 불러옵니다.
    if (mounted) showSnack(context, error ?? '내 여행에 저장했어요.');
  }

  Future<String?> _askTitle() {
    final text = _controller.message.trim();
    return askTripTitle(context, initial: text.length > 20 ? '제주 여행' : text);
  }

  void _openSpot(int spotId) {
    // 일정의 spot_id 는 항상 sources 안에 있으므로, 있으면 바로 보여 줍니다.
    final spot = _controller.result?.sources.where((s) => s.id == spotId).firstOrNull;
    SpotDetailScreen.open(context, spotId: spotId, initial: spot);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CenteredBody(
        maxWidth: 760,
        child: ListenableBuilder(listenable: _controller, builder: (context, _) => _form(context)),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final c = _controller;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('AI 플래너', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            // 내 AI 키를 넣는 설정 화면
            IconButton(
              tooltip: '설정',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => SettingsScreen.open(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _message,
          onChanged: (text) => c.message = text,
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
          selected: {c.days},
          onSelectionChanged: (s) => c.setDays(s.first),
        ),
        const SizedBox(height: 16),
        const Text('누구와 가나요?', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in PlannerController.companionOptions)
              ChoiceChip(
                label: Text(option),
                selected: c.companion == option,
                // 다시 누르면 선택 해제(선택 사항이라서)
                onSelected: (on) => c.setCompanion(on ? option : null),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(c.startDate == null ? '시작 날짜 (선택)' : PlannerController.dateText(c.startDate!)),
            ),
            if (c.startDate != null)
              IconButton(tooltip: '날짜 지우기', onPressed: () => c.setStartDate(null), icon: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: c.loading ? null : _submit,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('일정 짜기'),
        ),
        const SizedBox(height: 24),
        _resultArea(),
      ],
    );
  }

  Widget _resultArea() {
    final c = _controller;
    if (c.loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: LoadingView(message: '일정을 짜는 중이에요. 잠시만 기다려 주세요…'),
      );
    }
    if (c.error != null) return ErrorView(message: c.error!, onRetry: _submit);
    final result = c.result;
    if (result == null) return const SizedBox.shrink();
    return PlanResultView(
      result: result,
      onSpotTap: _openSpot,
      onSave: _save,
      onOpenSettings: () => SettingsScreen.open(context),
    );
  }
}
