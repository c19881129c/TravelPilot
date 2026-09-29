import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/itinerary_item.dart';
import '../models/vault_item.dart';
import '../models/weather_data.dart';

class StorageService {
  static const String _itineraryKey = 'travelpilot_itinerary_items';
  static const String _vaultKey = 'travelpilot_vault_items';
  static const String _weatherPrefix = 'travelpilot_weather_cache_';

  static Future<List<ItineraryItem>> getItinerary() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_itineraryKey);
    if (data == null || data.isEmpty) {
      final initialData = _generateSampleHokkaidoItinerary();
      await saveItinerary(initialData);
      return initialData;
    }
    return data.map((item) => ItineraryItem.fromJson(item)).toList();
  }

  static Future<void> saveItinerary(List<ItineraryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    final encoded = items.map((e) => e.toJson()).toList();
    await prefs.setStringList(_itineraryKey, encoded);
  }

  static Future<void> addItineraryItem(ItineraryItem item) async {
    final items = await getItinerary();
    items.add(item);
    await saveItinerary(items);
  }

  static Future<void> updateItineraryItem(ItineraryItem item) async {
    final items = await getItinerary();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      items[index] = item;
      await saveItinerary(items);
    }
  }

  static Future<void> deleteItineraryItem(String id) async {
    final items = await getItinerary();
    items.removeWhere((e) => e.id == id);
    await saveItinerary(items);
  }

  // Weather Caching (30-minute expiry)
  static Future<WeatherData?> getCachedWeather(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildWeatherKey(lat, lng);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final weather = WeatherData.fromJson(raw);
      if (weather.isExpired(cacheMinutes: 30)) {
        await prefs.remove(key);
        return null;
      }
      return weather;
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheWeather(WeatherData weather) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildWeatherKey(weather.lat, weather.lng);
    await prefs.setString(key, weather.toJson());
  }

  static String _buildWeatherKey(double lat, double lng) {
    // Quantize coordinates to roughly 5-10km (~0.05 degrees) to maximize cache hits
    final qLat = lat.toStringAsFixed(2);
    final qLng = lng.toStringAsFixed(2);
    return '$_weatherPrefix\${qLat}_\$qLng';
  }

  // Vault Items
  static Future<List<VaultItem>> getVaultItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_vaultKey);
    if (raw == null || raw.isEmpty) {
      final defaultVault = [
        VaultItem(
            title: 'Inbound Flight',
            value: 'CI130 TPE -> CTS (Dep 08:35 - Arr 13:15)',
            category: 'Flight'),
        VaultItem(
            title: 'Outbound Flight',
            value: 'CI131 CTS -> TPE (Dep 14:40 - Arr 18:00)',
            category: 'Flight'),
        VaultItem(
            title: 'Sapporo Stay',
            value: 'Airbnb Sapporo Chuo-ku (Check-in 15:00)',
            category: 'Hotel'),
        VaultItem(
            title: 'Japan Emergency Services',
            value: 'Police: 110 | Ambulance/Fire: 119',
            category: 'Emergency'),
        VaultItem(
            title: 'TECO Sapporo Office',
            value: '+81-11-222-2661 (Taiwan Rep Office)',
            category: 'Emergency'),
      ];
      await prefs.setStringList(
          _vaultKey, defaultVault.map((e) => e.toJson()).toList());
      return defaultVault;
    }
    return raw.map((e) => VaultItem.fromJson(e)).toList();
  }

  static List<ItineraryItem> _generateSampleHokkaidoItinerary() {
    final now = DateTime.now();
    final baseToday = DateTime(now.year, now.month, now.day);

    return [
      ItineraryItem(
        id: '1',
        title: 'New Chitose Airport to Sapporo Express',
        startTime: baseToday.add(const Duration(hours: 13, minutes: 45)),
        endTime: baseToday.add(const Duration(hours: 14, minutes: 30)),
        lat: 42.7875,
        lng: 141.6814,
        localAddress: 'Bibi, Chitose, Hokkaido 066-0012, Japan',
        bookingRef: 'JR-EX-88219',
        notes: 'Take JR Rapid Airport train to Sapporo Station. Car 4 reserved seat.',
      ),
      ItineraryItem(
        id: '2',
        title: 'Sapporo Odori & TV Tower Check-in',
        startTime: baseToday.add(const Duration(hours: 15, minutes: 30)),
        endTime: baseToday.add(const Duration(hours: 17, minutes: 00)),
        lat: 43.0605,
        lng: 141.3564,
        localAddress: '1 Chome Odorinishi, Chuo Ward, Sapporo, Hokkaido',
        bookingRef: 'HM-SP-3041',
        notes: 'Walk through Odori Park, check into apartment, pick up pocket Wi-Fi.',
      ),
      ItineraryItem(
        id: '3',
        title: 'Dinner at Susukino Ramen Alley',
        startTime: baseToday.add(const Duration(hours: 18, minutes: 30)),
        endTime: baseToday.add(const Duration(hours: 20, minutes: 00)),
        lat: 43.0538,
        lng: 141.3533,
        localAddress: 'Minami 5-jonishi, 3 Chome, Chuo Ward, Sapporo',
        bookingRef: 'WALK-IN',
        notes: 'Ganso Ramen Yokocho. Try Hokkaido Butter Corn Miso Ramen.',
      ),
      ItineraryItem(
        id: '4',
        title: 'Otaru Canal & Music Box Museum',
        startTime: baseToday.add(const Duration(days: 1, hours: 10, minutes: 00)),
        endTime: baseToday.add(const Duration(days: 1, hours: 14, minutes: 30)),
        lat: 43.1907,
        lng: 141.0028,
        localAddress: 'Minatomachi, Otaru, Hokkaido 047-0007',
        bookingRef: 'OTARU-DAYPASS',
        notes: 'Glassblowing workshops, stroll along stone warehouses, LeTAO double fromage cake.',
      ),
      ItineraryItem(
        id: '5',
        title: 'Jozankei Hot Springs Relaxation',
        startTime: baseToday.add(const Duration(days: 2, hours: 14, minutes: 00)),
        endTime: baseToday.add(const Duration(days: 2, hours: 18, minutes: 00)),
        lat: 42.9654,
        lng: 141.1648,
        localAddress: 'Jozankei Onsen Higashi, Minami Ward, Sapporo',
        bookingRef: 'JZK-DAY-SPA-44',
        notes: 'Scenic ravine footbaths and open-air hot springs.',
      ),
    ];
  }
}
