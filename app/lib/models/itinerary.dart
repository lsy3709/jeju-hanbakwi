import 'spot.dart';

/// 일정 안의 한 칸: "오전에 이 장소를 가요".
class ItineraryItem {
  final String time; // 오전 · 점심 · 오후 · 저녁
  final int spotId;
  final String title;
  final String reason;

  const ItineraryItem({required this.time, required this.spotId, required this.title, required this.reason});

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
        savedTrip: switch (json['saved_trip']) {
          {'id': final int id, 'title': final String title} => (id: id, title: title),
          _ => null,
        },
      );
}
