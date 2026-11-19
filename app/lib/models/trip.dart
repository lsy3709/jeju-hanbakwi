import 'itinerary.dart';

/// 내가 저장한 일정.
class Trip {
  final int id;
  final String title;
  final List<ItineraryDay> itinerary;
  final String createdAt;

  const Trip({required this.id, required this.title, required this.itinerary, required this.createdAt});

  /// 저장한 날짜 "2026-12-01". 서버 시각(UTC)을 내 기기 시간대로 바꿔서 냅니다.
  /// (글자 앞 10자만 자르면 한국의 오전 9시 이전에 저장한 것이 하루 전으로 보입니다)
  String get savedDate {
    final saved = DateTime.tryParse(createdAt)?.toLocal();
    if (saved == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${saved.year}-${two(saved.month)}-${two(saved.day)}';
  }

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as int,
        title: json['title'] as String,
        itinerary: itineraryFromJson(json['itinerary'] as List),
        createdAt: (json['created_at'] ?? '') as String,
      );
}
