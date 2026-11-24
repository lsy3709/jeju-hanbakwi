// 목록 맨 아래 "더 보기" 버튼 위젯입니다. 컨트롤러의 hasMore · loadingMore 값을 받아 그리기만 하고, 누르면 onPressed 를 불러 줍니다.

import 'package:flutter/material.dart';

/// 목록 맨 아래의 "더 보기" 자리. 탐색 · 찜한 곳 · 저장한 일정이 같은 모양을 씁니다.
/// 더 받을 것이 없으면 아무것도 그리지 않습니다.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({super.key, required this.hasMore, required this.loadingMore, required this.onPressed});

  final bool hasMore;
  final bool loadingMore;
  // VoidCallback 은 "받는 값도 돌려주는 값도 없는 함수"의 이름입니다.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // SizedBox.shrink() 는 크기 0 의 빈 위젯입니다. 더 받을 게 없으면 아무것도 그리지 않습니다.
    if (!hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: loadingMore
            ? const CircularProgressIndicator()
            : OutlinedButton(onPressed: onPressed, child: const Text('더 보기')),
      ),
    );
  }
}
