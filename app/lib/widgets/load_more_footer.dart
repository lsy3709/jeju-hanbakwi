import 'package:flutter/material.dart';

/// 목록 맨 아래의 "더 보기" 자리. 탐색 · 찜한 곳 · 저장한 일정이 같은 모양을 씁니다.
/// 더 받을 것이 없으면 아무것도 그리지 않습니다.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({super.key, required this.hasMore, required this.loadingMore, required this.onPressed});

  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
