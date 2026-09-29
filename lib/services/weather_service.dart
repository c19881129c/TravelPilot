import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import 'storage_service.dart';

class WeatherService {
  static const String _apiKey = 'a862417d6a8a6eefb0b6d7c1df3632b1';

  /// Fetches weather with strict local caching (30 minutes)
  static Future<WeatherData?> getWeather(double lat, double lng) async {
    // 1. Check local cache first
    final cached = await StorageService.getCachedWeather(lat, lng);
    if (cached != null) {
      return cached;
    }

    // 2. Fetch from OpenWeatherMap API only if cache expired or absent
    try {
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=\$lat&lon=\$lng&units=metric&appid=\$_apiKey');
      final res = await http.get(url).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final weather = WeatherData(
          temp: (data['main']['temp'] as num).toDouble(),
          description: data['weather'][0]['description'] ?? 'Clear',
          icon: data['weather'][0]['icon'] ?? '01d',
          lat: lat,
          lng: lng,
          fetchedAt: DateTime.now(),
        );
        // Save to cache
        await StorageService.cacheWeather(weather);
        return weather;
      }
    } catch (_) {
      // Offline fallback or network error
    }
    return null;
  }
}
