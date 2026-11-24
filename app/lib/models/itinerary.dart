// AI(또는 규칙)가 짠 일정을 담는 모양입니다. 칸(ItineraryItem) → 하루(ItineraryDay) → 응답 전체(PlanResult) 순으로 감싸고 있습니다.
// ApiClient 가 서버 응답을 fromJson 으로 이 클래스들로 바꾸고, 일정 화면과 저장 요청이 쓰며, 저장할 때는 toJson 으로 다시 서버 모양(Map)으로 되돌립니다.

import 'spot.dart';

/// 일정 안의 한 칸: "오전에 이 장소를 가요".
class ItineraryItem {
  final String time; // 오전 · 점심 · 오후 · 저녁
  final int spotId;
  final String title;
  final String reason;

  const ItineraryItem({required this.time, required this.spotId, required this.title, required this.reason});

  // (json['reason'] ?? '') 의 ?? 는 "왼쪽이 null 이면 오른쪽 값"이라는 뜻입니다. 서버가 값을 빼먹어도 앱이 죽지 않게 빈 글자로 대신합니다.
  factory ItineraryItem.fromJson(Map<String, dynamic> json) => ItineraryItem(
        time: json['time'] as String,
        spotId: json['spot_id'] as int,
        title: json['title'] as String,
        reason: (json['reason'] ?? '') as String,
      );

  // 저장(POST /me/trips)할 때 서버가 받는 모양으로 되돌립니다.
  Map<String, dynamic> toJson() => {'time': time, 'spot_id': spotId, 'title': title, 'reason': reason};
}

/// 하루치 일정.
class ItineraryDay {
  final int day;
  // String? 의 ? 는 null(값 없음)이 올 수 있다는 표시입니다. 날짜나 날씨를 못 구한 날이 있습니다.
  final String? date; // null 일 수 있음
  final String? weather; // null 일 수 있음
  final List<ItineraryItem> items;

  const ItineraryDay({required this.day, required this.date, required this.weather, required this.items});

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        day: json['day'] as int,
        date: json['date'] as String?,
        weather: json['weather'] as String?,
        items: (json['items'] as List).map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toJson() =>
      {'day': day, 'date': date, 'weather': weather, 'items': items.map((e) => e.toJson()).toList()};
}

// 일정 목록(JSON 리스트)을 하루씩 바꿔 주는 도우미 함수입니다. PlanResult 와 Trip 이 같이 씁니다.
List<ItineraryDay> itineraryFromJson(List<dynamic> list) =>
    list.map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>)).toList();

/// `POST /agent/plan` 의 응답.
class PlanResult {
  final String mode; // ai | rule
  final String answer;
  final List<ItineraryDay> itinerary;
  final List<Spot> sources;

  /// 보낸 내 AI 키로 일정을 받지 못해 다른 방식으로 대신했을 때만 오는 안내 글.
  final String? notice;

  /// 로그인한 채로 짰으면 서버가 "내 여행"에 자동 저장하고 그 일정의 번호와 제목을 알려 줍니다. 아니면 null.
  // 레코드 타입: 값 두 개(번호, 제목)를 묶은 것이고 ? 때문에 통째로 없을 수도 있습니다. 로그인하지 않고 짠 일정이면 null 입니다.
  final ({int id, String title})? savedTrip;

  const PlanResult({
    required this.mode,
    required this.answer,
    required this.itinerary,
    required this.sources,
    this.notice,
    this.savedTrip,
  });

  /// rule 이면 AI 가 아니라 규칙으로 짠 "간단 추천".
  bool get isSimple => mode == 'rule';

  factory PlanResult.fromJson(Map<String, dynamic> json) => PlanResult(
        mode: json['mode'] as String,
        answer: (json['answer'] ?? '') as String,
        itinerary: itineraryFromJson(json['itinerary'] as List),
        sources: (json['sources'] as List).map((e) => Spot.fromJson(e as Map<String, dynamic>)).toList(),
        notice: json['notice'] as String?,
        // switch 식(패턴 맞추기): saved_trip 이 {id: 정수, title: 글자} 모양이면 값을 꺼내고, 그 밖의 모양(없음 포함)이면 null 로 처리합니다.
        savedTrip: switch (json['saved_trip']) {
          {'id': final int id, 'title': final String title} => (id: id, title: title),
          _ => null,
        },
      );
}
