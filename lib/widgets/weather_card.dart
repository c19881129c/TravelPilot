import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

class WeatherCard extends StatefulWidget {
  final double lat;
  final double lng;
  final String locationTitle;

  const WeatherCard({
    Key? key,
    required this.lat,
    required this.lng,
    this.locationTitle = '目的地',
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
    _fetchWeather(force: false);
  }

  @override
  void didUpdateWidget(covariant WeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.lat - widget.lat).abs() > 0.05 ||
        (oldWidget.lng - widget.lng).abs() > 0.05) {
      _fetchWeather(force: false);
    }
  }

  Future<void> _fetchWeather({bool force = false}) async {
    setState(() => _loading = true);
    final data = await WeatherService.getWeather(widget.lat, widget.lng, forceRefresh: force);
    if (mounted) {
      setState(() {
        _weather = data;
        _loading = false;
      });
    }
  }

  void _showWeatherDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent, size: 28),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.locationTitle} 即時天氣',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "座標: ${widget.lat.toStringAsFixed(2)}, ${widget.lng.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
                        tooltip: '重新整理天氣',
                        onPressed: () async {
                          Navigator.pop(context);
                          await _fetchWeather(force: true);
                          _showWeatherDetails();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_weather != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "${_weather!.temp.toStringAsFixed(1)}°C",
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _weather!.description,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailItem(Icons.thermostat_rounded, "體感溫度", "${_weather!.feelsLike.toStringAsFixed(1)}°C"),
                          _buildDetailItem(Icons.water_drop_rounded, "相對濕度", "${_weather!.humidity}%"),
                          _buildDetailItem(Icons.air_rounded, "風速", "${_weather!.windSpeed.toStringAsFixed(1)} m/s"),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "暫時無法連線至氣象站，請檢查網路後按右上角重新整理",
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.cyanAccent,
                        side: const BorderSide(color: Colors.cyanAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final webUrl = Uri.parse(
                            "https://www.google.com/search?q=${Uri.encodeComponent("${widget.locationTitle} 天氣")}");
                        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: const Text('在 Google 查看完整週氣象預報', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 22),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.amberAccent),
            ),
            SizedBox(width: 6),
            Text('更新中...', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _showWeatherDetails,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _weather != null ? Colors.cyanAccent.withOpacity(0.6) : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _weather != null ? Icons.wb_sunny_rounded : Icons.cloud_outlined,
              color: _weather != null ? Colors.amberAccent : Colors.white54,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _weather != null ? "${_weather!.temp.toStringAsFixed(0)}°C" : "天氣詳情",
              style: TextStyle(
                color: _weather != null ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.touch_app_rounded, color: Colors.cyanAccent, size: 14),
          ],
        ),
      ),
    );
  }
}
