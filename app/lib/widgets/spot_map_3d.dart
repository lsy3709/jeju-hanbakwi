import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 웹에서 만든 3D 지도(`/embed/map3d`)를 앱 안에 띄우는 웹뷰.
///
/// 3D 지도를 앱에서 다시 만들지 않고 웹 화면을 그대로 씁니다. 그래서 웹(Next.js)이 켜져 있어야 보입니다.
/// 주소는 `map3dUrl` 로 만들고, 주소가 바뀌면(필터를 바꾸면) 다시 불러옵니다.
class SpotMap3d extends StatefulWidget {
  const SpotMap3d({super.key, required this.url});

  final String url;

  @override
  State<SpotMap3d> createState() => _SpotMap3dState();
}

class _SpotMap3dState extends State<SpotMap3d> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    // 지도는 자바스크립트로 그립니다. 크롬(Flutter 웹)에서는 iframe 으로 뜨고 이 설정이 필요 없습니다(부르면 오류).
    if (!kIsWeb) _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  void didUpdateWidget(SpotMap3d oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _controller,
      // 손가락 움직임을 바깥 화면이 아니라 지도가 먼저 받게 합니다(지도 돌리기 · 기울이기).
      gestureRecognizers: {Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())},
    );
  }
}
