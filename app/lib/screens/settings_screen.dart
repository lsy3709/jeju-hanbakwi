import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../app_scope.dart';
import '../theme.dart';

/// 설정 화면. 지금은 "내 AI 키" 한 묶음입니다.
/// 키를 다루는 일은 [AiKeyStore] 가 하고, 이 화면은 그리기와 서버 확인 요청만 맡습니다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _input = TextEditingController();
  String? _error; // 저장하지 못한 까닭
  String? _status; // 저장 · 확인 결과 안내
  bool _statusGood = true;
  bool _checking = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = AppScope.of(context).aiKey;
    final error = await store.save(_input.text);
    if (!mounted) return;
    setState(() {
      _error = error;
      if (error == null) {
        _input.clear(); // 저장한 키는 입력칸에 남기지 않습니다
        _status = '저장했어요. 키 확인을 누르면 쓸 수 있는 키인지 볼 수 있어요.';
        _statusGood = true;
      }
    });
  }

  Future<void> _check() async {
    final scope = AppScope.of(context);
    final key = scope.aiKey.key;
    if (key == null) return;
    setState(() => _checking = true);
    String message;
    bool ok;
    try {
      final result = await scope.api.checkAiKey(key);
      ok = result.ok;
      message = result.message;
    } on ApiException catch (e) {
      ok = false;
      message = e.message;
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      _status = message;
      _statusGood = ok;
    });
  }

  Future<void> _clear() async {
    await AppScope.of(context).aiKey.clear();
    if (!mounted) return;
    setState(() {
      _status = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).aiKey;
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('내 AI 키', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                '내 Gemini 키를 넣으면 AI 플래너가 그 키로 일정을 짭니다. 넣지 않으면 지금처럼 서비스의 기본 방식으로 짭니다.\n'
                '키는 이 기기에만 저장되고, 일정을 짤 때만 서버로 보내집니다. 서버는 키를 저장하지 않습니다.\n'
                '키는 Google AI Studio 의 API keys 화면에서 만들 수 있습니다.',
                style: TextStyle(color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 16),
              if (store.hasKey) ...[
                Text('저장된 키: ${store.masked}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _checking ? null : _check,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(_checking ? '확인하는 중...' : '키 확인'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('키 지우기'),
                    ),
                  ],
                ),
              ] else ...[
                TextField(
                  controller: _input,
                  obscureText: true, // 화면에 글자가 보이지 않게
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Gemini API 키',
                    hintText: 'AIza...',
                    errorText: _error,
                    errorMaxLines: 3,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(onPressed: _save, child: const Text('저장')),
                ),
              ],
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(_status!, style: TextStyle(color: _statusGood ? AppColors.secondary : AppColors.primaryDark)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
