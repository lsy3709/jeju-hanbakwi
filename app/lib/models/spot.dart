/// 관광지 한 곳. 서버 `Spot` 모양(docs/api.md)과 1:1 로 맞춥니다.
class Spot {
  final int id;
  final String title;
  final String category;
  final String area;
  final String address;
  final double lat;
  final double lng;
  final String? imageUrl; // 없을 수 있음 → 화면에서 대체 그림
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
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      overview: (json['overview'] ?? '') as String,
      oneLiner: (json['one_liner'] ?? '') as String,
      themeTags: ((json['theme_tags'] ?? const []) as List).cast<String>(),
      indoor: (json['indoor'] ?? false) as bool,
    );
  }
}

/// `GET /spots` 의 응답: 목록 + 전체 개수 + 쪽 정보.
class SpotPage {
  final List<Spot> items;
  final int total;
  final int page;
  final int size;

  const SpotPage({required this.items, required this.total, required this.page, required this.size});

  factory SpotPage.fromJson(Map<String, dynamic> json) {
    return SpotPage(
      items: (json['items'] as List).map((e) => Spot.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      size: json['size'] as int,
    );
  }
}

/// `GET /meta`: 화면의 선택지(테마·지역·분류).
class Meta {
  final List<String> themes;
  final List<String> areas;
  final List<String> categories;

  const Meta({required this.themes, required this.areas, required this.categories});

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        themes: (json['themes'] as List).cast<String>(),
        areas: (json['areas'] as List).cast<String>(),
        categories: (json['categories'] as List).cast<String>(),
      );
}
