// 컨트롤러들이 함께 쓰는 안전장치입니다. 서버 응답을 기다리는 동안 사용자가 화면을 닫으면, 늦게 온 응답이 이미 정리된(dispose) 객체를 건드려 오류가 납니다. 이를 막습니다.
// mixin 은 클래스에 "끼워 넣는 기능 묶음"이고, 컨트롤러가 `with SafeNotifier` 로 가져다 씁니다.

import 'package:flutter/foundation.dart';

/// 화면이 닫힌 뒤(dispose)에 늦게 도착한 서버 응답이 알림을 보내도 오류가 나지 않게 하는 믹스인.
/// 컨트롤러는 서버 응답을 `await` 한 뒤 값을 바꾸고 `notifyListeners()` 를 부르는데,
/// 그 사이 사용자가 화면을 떠났을 수 있기 때문입니다.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  /// dispose 가 끝난 컨트롤러인지. 응답을 받은 뒤 값을 바꾸기 전에 확인하는 데 씁니다.
  bool get isDisposed => _disposed;

  @override
  // 정리된 뒤에는 알림을 보내지 않고 조용히 넘어갑니다. super 는 원래(Flutter 기본) notifyListeners 를 뜻합니다.
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
