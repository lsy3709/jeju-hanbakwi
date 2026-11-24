// 설정 화면입니다. "내 AI 키" 입력과 "내 AI 사용량" 두 묶음이 있고, AI 플래너 화면의 톱니바퀴 버튼으로 엽니다.
// 키 보관은 AiKeyStore(auth/ai_key_store.dart), 키가 쓸 수 있는지 확인은 ApiClient.checkAiKey 가 맡고, 이 화면은 그리기와 호출 연결만 합니다.
// 비밀 값이라 입력칸은 글자를 가리고, 저장한 뒤에는 입력칸을 비웁니다.

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../app_scope.dart';
import '../theme.dart';
import '../widgets/usage_panel.dart';

/// 설정 화면. "내 AI 키"와 "내 AI 사용량" 두 묶음입니다.
/// 키를 다루는 일은 [AiKeyStore] 가 하고, 이 화면은 그리기와 서버 확인 요청만 맡습니다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  // static 은 화면 객체를 만들지 않고 SettingsScreen.open(context) 로 바로 부르는 함수입니다. Navigator.push 가 새 화면을 위에 쌓아 열어 줍니다.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _input = TextEditingController();
  // setState 로 이 값들을 바꾸면 build 가 다시 불려 화면에 반영됩니다. _error 는 저장 실패 까닭, _status 는 안내 글입니다.
  String? _error; // 저장하지 못한 까닭
  String? _status; // 저장 · 확인 결과 안내
  bool _statusGood = true;
  bool _checking = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  // await 끝난 뒤 화면이 닫혔을 수 있어서 mounted 를 확인하고, 값을 바꿀 때는 setState 로 감싸 화면을 다시 그리게 합니다.
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

  // 서버에 "이 키가 쓸 수 있나" 묻는 동안 _checking 을 true 로 두어 버튼이 눌리지 않게 합니다. 실패해도 서버가 준 문구를 안내로 씁니다.
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
  // AiKeyStore(store)가 바뀌면(저장·삭제) ListenableBuilder 안쪽이 다시 그려집니다. 키가 있으면 가린 키와 버튼, 없으면 입력칸을 보여 줍니다.
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.aiKey;
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
              // ...[ ] 는 목록 안에 여러 위젯을 펼쳐 넣는 문법입니다. if / else 로 두 묶음 중 하나만 들어갑니다.
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
                  // obscureText: 입력한 글자를 ●●● 로 가립니다. 키는 비밀번호처럼 다루기 때문입니다.
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
              const Divider(height: 40),
              Text('내 AI 사용량', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                '로그인한 채로 AI 플래너를 쓴 횟수와 토큰 수입니다. 요청한 글이나 일정 내용은 기록하지 않습니다.',
                style: TextStyle(color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 12),
              // 로그인 · 로그아웃이 바뀌면 다시 그립니다.
              ListenableBuilder(
                listenable: scope.auth,
                builder: (context, _) => scope.auth.loggedIn
                    ? UsagePanel(load: (days) => scope.api.getMyAiUsage(days: days))
                    : const Text('로그인하면 내 사용량을 볼 수 있어요. (내 여행 탭에서 로그인)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
