import 'package:flutter/material.dart';

import '../theme.dart';

/// 불러오는 중.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

/// 불러오기 실패. 서버가 꺼져 있어도 앱이 죽지 않고 이 화면과 "다시 시도" 버튼을 보여 줍니다.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

/// 결과가 없을 때.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.search_off});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// 넓은 화면(웹)에서 내용이 너무 퍼지지 않게 가운데로 모아 줍니다.
class CenteredBody extends StatelessWidget {
  const CenteredBody({super.key, required this.child, this.maxWidth = 1100});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

/// 알약 모양 검색바. 입력 후 키보드의 확인을 누르면 [onSubmitted] 가 불립니다.
class SearchPill extends StatelessWidget {
  const SearchPill({super.key, required this.controller, required this.hint, required this.onSubmitted});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: '검색',
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => onSubmitted(controller.text),
        ),
      ),
    );
  }
}

/// 화면 아래에 잠깐 뜨는 안내.
void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
