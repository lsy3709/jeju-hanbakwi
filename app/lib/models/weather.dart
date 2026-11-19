/// 하루치 날씨.
class WeatherDay {
  final String date;
  final String label; // 예: "비"
  final String icon; // sun | cloud | rain | snow | fog
  final double tempMin;
  final double tempMax;
  final int rainProb;

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
        tempMin: (json['temp_min'] as num).toDouble(),
        tempMax: (json['temp_max'] as num).toDouble(),
        rainProb: (json['rain_prob'] as num).round(),
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
