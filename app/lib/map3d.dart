/// 앱이 웹뷰로 띄울 3D 지도 주소를 만듭니다.
///
/// 3D 지도는 웹(`web/src/app/embed/map3d`)에서 한 번만 만들고, 앱은 그 화면을 그대로 띄웁니다.
/// 탐색 화면에서 고른 필터를 웹의 탐색 화면과 같은 쿼리(`?q=&theme=&area=&category=&indoor=`)로 넘깁니다.
String map3dUrl(
  String webUrl, {
  String q = '',
  String? theme,
  String? area,
  String? category,
  bool? indoor,
}) {
  final query = <String, String>{
    if (q.trim().isNotEmpty) 'q': q.trim(),
    if (theme != null && theme.isNotEmpty) 'theme': theme,
    if (area != null && area.isNotEmpty) 'area': area,
    if (category != null && category.isNotEmpty) 'category': category,
    if (indoor != null) 'indoor': '$indoor',
  };
  final base = Uri.parse('$webUrl/embed/map3d');
  // 쿼리가 없을 때 주소 끝에 `?` 만 남지 않게 나눠 만듭니다.
  return (query.isEmpty ? base : base.replace(queryParameters: query)).toString();
}
