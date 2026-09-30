import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';
import 'storage_service.dart';

class WeatherService {
  static const String _apiKey = 'a862417d6a8a6eefb0b6d7c1df3632b1';
  static const int maxDailyCalls = 60; // 每日上限 60 次保護
  static const String _callCountKey = 'weather_daily_call_count';
  static const String _callDateKey = 'weather_daily_call_date';

  static Future<bool> _canMakeApiCall() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDate = prefs.getString(_callDateKey) ?? '';

    int count = prefs.getInt(_callCountKey) ?? 0;
    if (lastDate != todayStr) {
      await prefs.setString(_callDateKey, todayStr);
      await prefs.setInt(_callCountKey, 0);
      return true;
    }
    return count < maxDailyCalls;
  }

  static Future<void> _recordApiCall() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDate = prefs.getString(_callDateKey) ?? '';

    int count = prefs.getInt(_callCountKey) ?? 0;
    if (lastDate != todayStr) {
      await prefs.setString(_callDateKey, todayStr);
      count = 0;
    }
    await prefs.setInt(_callCountKey, count + 1);
  }

  static Future<int> getTodayCallCount() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDate = prefs.getString(_callDateKey) ?? '';
    if (lastDate != todayStr) return 0;
    return prefs.getInt(_callCountKey) ?? 0;
  }

  static Future<WeatherData?> getWeather(double lat, double lng, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await StorageService.getCachedWeather(lat, lng);
      if (cached != null) return cached;
    }

    final canCall = await _canMakeApiCall();
    if (!canCall) {
      return await StorageService.getCachedWeather(lat, lng);
    }

    try {
      // 呼叫包含 pop 降雨機率的預報資料
      final forecastUrl = Uri.parse(
          "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lng&units=metric&lang=zh_tw&appid=$_apiKey");
      final res = await http.get(forecastUrl).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        await _recordApiCall();
        final data = json.decode(res.body);
        final list = (data['list'] as List?) ?? [];
        if (list.isNotEmpty) {
          final first = list[0];
          final main = first['main'] ?? {};
          final wind = first['wind'] ?? {};
          final weatherList = (first['weather'] as List?) ?? [];
          final weatherItem = weatherList.isNotEmpty ? weatherList[0] : {};
          final popDouble = (first['pop'] as num?)?.toDouble() ?? 0.0;
          final rainVol = (first['rain']?['3h'] as num?)?.toDouble() ?? 0.0;

          final weather = WeatherData(
            temp: (main['temp'] as num?)?.toDouble() ?? 20.0,
            feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 20.0,
            humidity: (main['humidity'] as num?)?.toInt() ?? 60,
            windSpeed: (wind['speed'] as num?)?.toDouble() ?? 2.0,
            description: weatherItem['description'] ?? '晴朗',
            icon: weatherItem['icon'] ?? '01d',
            rainPop: (popDouble * 100).round(),
            rainVolume: rainVol,
            lat: lat,
            lng: lng,
            fetchedAt: DateTime.now(),
          );
          await StorageService.cacheWeather(weather);
          return weather;
        }
      }
    } catch (_) {
      try {
        final weatherUrl = Uri.parse(
            "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&units=metric&lang=zh_tw&appid=$_apiKey");
        final res = await http.get(weatherUrl).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          await _recordApiCall();
          final data = json.decode(res.body);
          final main = data['main'] ?? {};
          final wind = data['wind'] ?? {};
          final weatherList = (data['weather'] as List?) ?? [];
          final weatherItem = weatherList.isNotEmpty ? weatherList[0] : {};
          final mainCondition = weatherItem['main'] ?? '';
          final rainVol = (data['rain']?['1h'] as num?)?.toDouble() ?? 0.0;

          int estimatedPop = 10;
          if (mainCondition == 'Rain' || mainCondition == 'Drizzle' || mainCondition == 'Thunderstorm') {
            estimatedPop = 90;
          } else if (mainCondition == 'Clouds') {
            estimatedPop = 30;
          } else if (mainCondition == 'Clear') {
            estimatedPop = 5;
          }

          final weather = WeatherData(
            temp: (main['temp'] as num?)?.toDouble() ?? 20.0,
            feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 20.0,
            humidity: (main['humidity'] as num?)?.toInt() ?? 60,
            windSpeed: (wind['speed'] as num?)?.toDouble() ?? 2.0,
            description: weatherItem['description'] ?? '晴朗',
            icon: weatherItem['icon'] ?? '01d',
            rainPop: estimatedPop,
            rainVolume: rainVol,
            lat: lat,
            lng: lng,
            fetchedAt: DateTime.now(),
          );
          await StorageService.cacheWeather(weather);
          return weather;
        }
      } catch (_) {}
    }
    return null;
  }
}
