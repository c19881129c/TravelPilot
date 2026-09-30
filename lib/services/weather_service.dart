import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';
import 'storage_service.dart';

class WeatherService {
  static const String _apiKey = 'a862417d6a8a6eefb0b6d7c1df3632b1';
  static const int maxDailyCalls = 60; // 嚴格限制每日最多 60 次 API 呼叫
  static const String _callCountKey = 'weather_daily_call_count';
  static const String _callDateKey = 'weather_daily_call_date';

  /// 檢查今日呼叫次數是否已達上限 (<= 60 次)
  static Future<bool> _canMakeApiCall() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDate = prefs.getString(_callDateKey) ?? '';

    int count = prefs.getInt(_callCountKey) ?? 0;
    if (lastDate != todayStr) {
      // 隔日自動歸零重置
      await prefs.setString(_callDateKey, todayStr);
      await prefs.setInt(_callCountKey, 0);
      return true;
    }

    return count < maxDailyCalls;
  }

  /// 增加一次呼叫記錄
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

  /// 取得今日已呼叫次數
  static Future<int> getTodayCallCount() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDate = prefs.getString(_callDateKey) ?? '';
    if (lastDate != todayStr) return 0;
    return prefs.getInt(_callCountKey) ?? 0;
  }

  /// 取得氣象資料
  static Future<WeatherData?> getWeather(double lat, double lng, {bool forceRefresh = false}) async {
    // 1. 若非強制重整，先檢查 30 分鐘本機快取
    if (!forceRefresh) {
      final cached = await StorageService.getCachedWeather(lat, lng);
      if (cached != null) {
        return cached;
      }
    }

    // 2. 嚴格檢查每日呼叫上限（不得超過 60 次）
    final canCall = await _canMakeApiCall();
    if (!canCall) {
      // 超過 60 次時拒絕呼叫外部 API，強制回傳快取資料以保護配額
      return await StorageService.getCachedWeather(lat, lng);
    }

    // 3. 聯網呼叫 OpenWeatherMap API
    try {
      final url = Uri.parse(
          "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&units=metric&lang=zh_tw&appid=$_apiKey");
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        await _recordApiCall(); // 成功發送 API，今日次數 +1

        final data = json.decode(res.body);
        final main = data['main'] ?? {};
        final wind = data['wind'] ?? {};
        final weatherList = (data['weather'] as List?) ?? [];
        final firstWeather = weatherList.isNotEmpty ? weatherList[0] : {};

        final weather = WeatherData(
          temp: (main['temp'] as num?)?.toDouble() ?? 20.0,
          feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 20.0,
          humidity: (main['humidity'] as num?)?.toInt() ?? 60,
          windSpeed: (wind['speed'] as num?)?.toDouble() ?? 2.0,
          description: firstWeather['description'] ?? '晴朗',
          icon: firstWeather['icon'] ?? '01d',
          lat: lat,
          lng: lng,
          fetchedAt: DateTime.now(),
        );
        // 存入快取
        await StorageService.cacheWeather(weather);
        return weather;
      }
    } catch (_) {
      // 網路連線或金鑰異常
    }
    return null;
  }
}
