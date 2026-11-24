// 날씨 응답을 담는 모양입니다: Weather(전체) → AreaWeather(지역) → WeatherDay(하루). 홈 화면의 날씨 띠가 보여 줍니다.

/// 하루치 날씨.
class WeatherDay {
  final String date;
  final String label; // 예: "비"
  final String icon; // sun | cloud | rain | snow | fog
  // 서버는 값을 못 구하면 null 로 줍니다. non-null 로 읽으면 TypeError 로 홈이 무한 로딩이 됩니다.
  // double? 의 ? 는 null 허용입니다. 서버가 정수를 줄 때도 있어서 읽을 때 num 으로 받아 소수로 바꿉니다(fromJson).
  final double? tempMin;
  final double? tempMax;
  final int? rainProb;

  const WeatherDay({
    required this.date,
    required this.label,
    required this.icon,
    required this.tempMin,
    required this.tempMax,
    required this.rainProb,
  });

  factory WeatherDay.fromJson(Map<String, dynamic> json) => WeatherDay(
        date: json['date'] as String,
        label: json['label'] as String,
        icon: json['icon'] as String,
        tempMin: (json['temp_min'] as num?)?.toDouble(),
        tempMax: (json['temp_max'] as num?)?.toDouble(),
        // num? → ?. 로 null 이면 건너뛰고, 있으면 .round() 로 정수로 바꿉니다.
        rainProb: (json['rain_prob'] as num?)?.round(),
      );
}

/// 한 지역(제주시/서귀포시)의 4일 날씨.
class AreaWeather {
  final String area;
  final List<WeatherDay> days;

  const AreaWeather({required this.area, required this.days});

  factory AreaWeather.fromJson(Map<String, dynamic> json) => AreaWeather(
        area: json['area'] as String,
        days: (json['days'] as List).map((e) => WeatherDay.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class Weather {
  final bool rainyToday;
  final String message;
  final List<AreaWeather> areas;

  const Weather({required this.rainyToday, required this.message, required this.areas});

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
        rainyToday: json['rainy_today'] as bool,
        message: json['message'] as String,
        areas: (json['areas'] as List).map((e) => AreaWeather.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
