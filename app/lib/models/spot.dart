/// 관광지 한 곳. 서버 `Spot` 모양(docs/api.md)과 1:1 로 맞춥니다.
class Spot {
  final int id;
  final String title;
  final String category;
  final String area;
  final String address;
  /// 위치. 관리자가 위치 없이 추가한 곳은 둘 다 null 입니다(지도에는 그리지 않음).
  final double? lat;
  final double? lng;

  bool get hasLocation => lat != null && lng != null;
  final String? imageUrl; // 없을 수 있음 → 화면에서 대체 그림
  final String? imageCredit; // 사진 저작자·라이선스. 있으면 상세에서 반드시 표시
  final String? imageSourceUrl; // 사진 원본 설명 쪽 주소(앱은 링크로 열지 않고 보관만)
  final String overview;
  final String oneLiner;
  final List<String> themeTags;
  final bool indoor;

  const Spot({
    required this.id,
    required this.title,
    required this.category,
    required this.area,
    required this.address,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    this.imageCredit,
    this.imageSourceUrl,
    required this.overview,
    required this.oneLiner,
    required this.themeTags,
    required this.indoor,
  });

  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'] as int,
      title: json['title'] as String,
      category: (json['category'] ?? '') as String,
      area: (json['area'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      // 서버가 정수(33)로 줄 수도 있어서 num 으로 받아 double 로 바꿉니다.
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
      imageCredit: json['image_credit'] as String?,
      imageSourceUrl: json['image_source_url'] as String?,
      overview: (json['overview'] ?? '') as String,
      oneLiner: (json['one_liner'] ?? '') as String,
      themeTags: ((json['theme_tags'] ?? const []) as List).cast<String>(),
      indoor: (json['indoor'] ?? false) as bool,
    );
  }
}

/// 가까운 곳 한 건(`GET /spots/{id}/restaurants`). 관광지 모양에 직선 거리(km)가 붙어 옵니다.
class NearbySpot {
  final Spot spot;
  final double distanceKm;

  const NearbySpot({required this.spot, required this.distanceKm});

  factory NearbySpot.fromJson(Map<String, dynamic> json) =>
      NearbySpot(spot: Spot.fromJson(json), distanceKm: (json['distance_km'] as num).toDouble());
}

/// `GET /spots` 의 응답: 목록 + 다음 커서 + 전체 개수.
/// `total` 은 첫 묶음에서만 숫자이고 이어지는 묶음에서는 null 입니다(그래서 nullable).
class SpotPage {
  final List<Spot> items;
  final int? nextCursor; // null 이면 끝
  final int? total;
  final int size;

  const SpotPage({required this.items, required this.nextCursor, required this.total, required this.size});

  factory SpotPage.fromJson(Map<String, dynamic> json) {
    return SpotPage(
      items: (json['items'] as List).map((e) => Spot.fromJson(e as Map<String, dynamic>)).toList(),
      nextCursor: json['next_cursor'] as int?,
      total: json['total'] as int?,
      size: json['size'] as int,
    );
  }
}

/// `GET /meta`: 화면의 선택지(테마·지역·분류).
class Meta {
  final List<String> themes;
  final List<String> areas;
  final List<String> categories;

  /// 편의 시설 분류(숙소 · 병원 · 약국 …). 골랐을 때만 목록에 나옵니다. 옛 서버에는 없을 수 있습니다.
  final List<String> placeCategories;

  /// 추천 식당 분류(한식 · 해산물 · 고기구이 · 국수 · 카페). 편의 시설처럼 골랐을 때만 목록에 나옵니다.
  final List<String> foodCategories;

  const Meta({
    required this.themes,
    required this.areas,
    required this.categories,
    this.placeCategories = const [],
    this.foodCategories = const [],
  });

  /// 분류 메뉴의 선택지: 여행지 분류 뒤에 편의 시설 분류, 추천 식당 분류를 잇습니다.
  List<String> get allCategories => [...categories, ...placeCategories, ...foodCategories];

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        themes: (json['themes'] as List).cast<String>(),
        areas: (json['areas'] as List).cast<String>(),
        categories: (json['categories'] as List).cast<String>(),
        placeCategories: ((json['place_categories'] as List?) ?? const []).cast<String>(),
        foodCategories: ((json['food_categories'] as List?) ?? const []).cast<String>(),
      );
}
