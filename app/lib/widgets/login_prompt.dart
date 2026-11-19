import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../brand.dart';

/// 로그인이 필요한 버튼(찜·저장)을 로그인 전에 눌렀을 때 띄우는 안내.
Future<void> showLoginPrompt(BuildContext context) {
  final scope = AppScope.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(Brand.loginNeedTitle),
      content: Text(
        scope.auth.configured ? Brand.loginNeedBody : '${Brand.loginNotReady}.\n설정 값을 채우면 로그인할 수 있어요.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('닫기')),
        if (scope.auth.configured)
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // 상세 화면 위에서 눌렀을 수도 있으니 첫 화면(탭)으로 돌아간 뒤 "내 여행" 탭으로 이동.
              Navigator.of(context).popUntil((route) => route.isFirst);
              scope.shell.goTab(3);
            },
            child: const Text('내 여행으로 가기'),
          ),
      ],
    ),
  );
}

/// 화면 아래에 잠깐 뜨는 안내.
void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
