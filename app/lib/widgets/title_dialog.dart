import 'package:flutter/material.dart';

/// 일정 제목을 묻는 대화상자. "저장"을 누르면 적은 제목을, 취소하거나 바깥을 눌러 닫으면 null 을 돌려줍니다.
Future<String?> askTripTitle(BuildContext context, {String initial = ''}) {
  return showDialog<String>(context: context, builder: (_) => _TitleDialog(initial: initial));
}

/// 입력칸의 TextEditingController 는 대화상자가 직접 만들고 직접 정리합니다.
/// 바깥에서 "닫히자마자" 정리하면, 닫히는 애니메이션 동안 아직 그려지는 입력칸이 정리된 것을 써서 오류가 납니다.
class _TitleDialog extends StatefulWidget {
  const _TitleDialog({required this.initial});

  final String initial;

  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isNotEmpty) Navigator.pop(context, title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('일정 제목'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '예: 부모님과 제주'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }
}
