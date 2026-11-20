import '../format.dart';
import 'itinerary.dart';

/// 내가 저장한 일정.
class Trip {
  final int id;
  final String title;
  final List<ItineraryDay> itinerary;
  final String createdAt;

  const Trip({required this.id, required this.title, required this.itinerary, required this.createdAt});

  /// 저장한 날짜 "2026년 12월 1일"(웹과 같은 표기). 서버 시각(UTC)을 내 기기 시간대로 바꿔서 냅니다.
  String get savedDate => formatSavedAt(createdAt);

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as int,
        title: json['title'] as String,
        itinerary: itineraryFromJson(json['itinerary'] as List),
        createdAt: (json['created_at'] ?? '') as String,
      );
}
