import 'dart:convert';

class WeatherData {
  final double temp;
  final String description;
  final String icon;
  final double lat;
  final double lng;
  final DateTime fetchedAt;

  WeatherData({
    required this.temp,
    required this.description,
    required this.icon,
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
      'description': description,
      'icon': icon,
      'lat': lat,
      'lng': lng,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      temp: (map['temp'] as num).toDouble(),
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      fetchedAt: DateTime.parse(map['fetchedAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory WeatherData.fromJson(String source) =>
      WeatherData.fromMap(json.decode(source));
}
