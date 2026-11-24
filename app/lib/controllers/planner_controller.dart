// AI 일정 화면(screens/planner_screen.dart)의 상태를 맡는 컨트롤러입니다. 입력값(글 · 일수 · 동행 · 시작일)과 결과 · 오류 · 저장 여부를 들고, 화면 → PlannerController → ApiClient.plan / saveTrip 순으로 부릅니다.
// 글(message)은 알림 없이 바꿉니다. 글자를 칠 때마다 화면 전체를 다시 그리면 느리기 때문입니다.

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/itinerary.dart';
import 'safe_notifier.dart';

/// AI 플래너 화면의 상태: 입력값 · 요청 중 · 결과 · 오류 · 저장 상태.
class PlannerController extends ChangeNotifier with SafeNotifier {
  PlannerController({required this.api});

  final ApiClient api;

  /// 선택지(칩)로 보여 줄 "누구와" 목록.
  // static const 는 이 클래스 이름으로 바로 읽는, 바뀌지 않는 값입니다(PlannerController.companionOptions).
  static const companionOptions = ['혼자', '친구', '연인', '아이와', '부모님'];

  // ---- 입력값 ----
  // 글은 화면의 입력창이 직접 들고 있고, 바뀔 때마다 여기로 복사됩니다(타이핑마다 다시 그리지 않으려고 알림은 없음).
  String message = '';
  int days = 2;
  String? companion; // 선택 사항
  DateTime? startDate; // 선택 사항

  // ---- 결과 ----
  bool loading = false;
  String? error;
  PlanResult? result;
  bool saving = false;
  bool saved = false;

  bool get hasMessage => message.trim().isNotEmpty;

  void setDays(int value) {
    days = value;
    notifyListeners();
  }

  void setCompanion(String? value) {
    companion = value;
    notifyListeners();
  }

  void setStartDate(DateTime? value) {
    startDate = value;
    notifyListeners();
  }

  /// 서버가 받는 날짜 모양 "2026-12-03".
  // padLeft(2, '0') 은 한 자리 숫자 앞에 0 을 채워 12-03 처럼 두 자리로 맞춥니다. 서버가 받는 날짜 모양입니다.
  static String dateText(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 일정 짜기. 글이 비어 있으면 아무것도 하지 않습니다(화면이 안내 문구를 띄웁니다).
  // startDate == null ? null : dateText(startDate!) 은 날짜가 없으면 null 을, 있으면 글자로 바꿔 보냅니다(조건 ? A : B).
  Future<void> submit() async {
    if (!hasMessage) return;
    loading = true;
    error = null;
    saved = false; // 새 일정이므로 "저장됨"이 아닙니다.
    notifyListeners();
    try {
      final plan = await api.plan(
        message: message.trim(),
        days: days,
        companions: companion,
        startDate: startDate == null ? null : dateText(startDate!),
      );
      if (isDisposed) return;
      result = plan;
      saved = plan.savedTrip != null; // 서버가 자동으로 저장해 준 일정이면 처음부터 "저장됨"
    } on ApiException catch (e) {
      if (isDisposed) return;
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// 지금 결과를 "내 여행"에 저장. 성공하면 null, 실패하면 오류 문구를 돌려줍니다.
  // 돌려주는 값이 String? 인 이유: 성공은 null, 실패는 화면에 띄울 글입니다. finally 는 성공이든 실패든 "저장 중" 표시를 반드시 풀어 줍니다.
  Future<String?> save(String title) async {
    final current = result;
    if (current == null || saving) return null; // 저장 중에 또 눌러도 요청은 한 번
    saving = true;
    notifyListeners();
    try {
      await api.saveTrip(title: title, itinerary: current.itinerary);
      saved = true;
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
