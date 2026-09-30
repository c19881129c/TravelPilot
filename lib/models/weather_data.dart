import 'dart:convert';

class WeatherData {
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final int rainPop; // 降雨機率 (0 ~ 100 %)
  final double rainVolume; // 降雨量 (mm)
  final double lat;
  final double lng;
  final DateTime fetchedAt;

  WeatherData({
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.rainPop,
    required this.rainVolume,
    required this.lat,
    required this.lng,
    required this.fetchedAt,
  });

  bool isExpired({int cacheMinutes = 30}) {
    return DateTime.now().difference(fetchedAt).inMinutes >= cacheMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'temp': temp,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'description': description,
      'icon': icon,
      'rainPop': rainPop,
      'rainVolume': rainVolume,
      'lat': lat,
      'lng': lng,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      temp: (map['temp'] as num?)?.toDouble() ?? 20.0,
      feelsLike: (map['feelsLike'] as num?)?.toDouble() ?? (map['temp'] as num?)?.toDouble() ?? 20.0,
      humidity: (map['humidity'] as num?)?.toInt() ?? 60,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 2.5,
      description: map['description'] ?? '晴朗',
      icon: map['icon'] ?? '01d',
      rainPop: (map['rainPop'] as num?)?.toInt() ?? 0,
      rainVolume: (map['rainVolume'] as num?)?.toDouble() ?? 0.0,
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      fetchedAt: map['fetchedAt'] != null ? DateTime.parse(map['fetchedAt']) : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory WeatherData.fromJson(String source) =>
      WeatherData.fromMap(json.decode(source));
}
