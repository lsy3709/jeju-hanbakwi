import 'itinerary.dart';

/// 내가 저장한 일정.
class Trip {
  final int id;
  final String title;
  final List<ItineraryDay> itinerary;
  final String createdAt;

  const Trip({required this.id, required this.title, required this.itinerary, required this.createdAt});

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as int,
        title: json['title'] as String,
        itinerary: itineraryFromJson(json['itinerary'] as List),
        createdAt: (json['created_at'] ?? '') as String,
      );
}
