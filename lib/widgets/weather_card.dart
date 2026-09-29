import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

class WeatherCard extends StatefulWidget {
  final double lat;
  final double lng;

  const WeatherCard({
    Key? key,
    required this.lat,
    required this.lng,
  }) : super(key: key);

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  WeatherData? _weather;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  void didUpdateWidget(covariant WeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.lat - widget.lat).abs() > 0.05 ||
        (oldWidget.lng - widget.lng).abs() > 0.05) {
      _fetchWeather();
    }
  }

  Future<void> _fetchWeather() async {
    setState(() => _loading = true);
    final data = await WeatherService.getWeather(widget.lat, widget.lng);
    if (mounted) {
      setState(() {
        _weather = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
            ),
            SizedBox(width: 12),
            Text('Syncing local weather...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_weather == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Weather offline (cached)',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent, size: 28),
          const SizedBox(width: 12),
          Text(
            '\${_weather!.temp.toStringAsFixed(1)}°C',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _weather!.description.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }
}
