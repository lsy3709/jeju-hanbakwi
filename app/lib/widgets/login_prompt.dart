// 로그인이 필요한 일(찜 · 저장)을 로그인 전에 눌렀을 때 띄우는 안내 창(showLoginPrompt)과, 화면 아래에 잠깐 뜨는 안내(showSnack)를 모아 둔 함수들입니다. 여러 화면이 같이 씁니다.
// 위젯이 아니라 함수라서 화면에서 await showLoginPrompt(context) 처럼 부릅니다.

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../brand.dart';

/// 로그인이 필요한 버튼(찜·저장)을 로그인 전에 눌렀을 때 띄우는 안내.
// showDialog 는 화면 위에 대화상자를 띄우고, 닫힐 때까지 기다리는 Future 를 돌려줍니다. builder 가 대화상자의 내용을 만듭니다.
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
              // popUntil: 쌓여 있는 화면을 첫 화면까지 닫습니다. 그다음 3번 탭(내 여행)으로 이동합니다.
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
// ..hideCurrentSnackBar() 처럼 점 두 개(..)는 같은 객체에 이어서 명령하는 문법입니다. 이미 떠 있는 안내를 치우고 새 안내를 띄웁니다.
void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
