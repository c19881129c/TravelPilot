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

  IconData _getWeatherIcon() {
    if (_weather == null) return Icons.cloud_outlined;
    final desc = _weather!.description;
    final pop = _weather!.rainPop;
    if (pop >= 60 || desc.contains('雨') || desc.contains('陣雨')) {
      return Icons.grain_rounded;
    }
    if (desc.contains('雲') || desc.contains('陰')) {
      return Icons.cloud_rounded;
    }
    return Icons.wb_sunny_rounded;
  }

  void _showWeatherDetails() async {
    final callCount = await WeatherService.getTodayCallCount();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isRainy = _weather != null && (_weather!.rainPop >= 50 || _weather!.description.contains('雨'));

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
                          Icon(
                            _getWeatherIcon(),
                            color: isRainy ? Colors.lightBlueAccent : Colors.amberAccent,
                            size: 28,
                          ),
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "今日呼叫額度: $callCount / ${WeatherService.maxDailyCalls} 次 (配額保護中)",
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isRainy ? Colors.lightBlueAccent : Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isRainy ? Colors.lightBlueAccent.withOpacity(0.15) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRainy ? Colors.lightBlueAccent : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.umbrella_rounded,
                            color: isRainy ? Colors.lightBlueAccent : Colors.amberAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isRainy
                                  ? "降雨機率 ${_weather!.rainPop}%：建議隨身攜帶雨傘！"
                                  : "降雨機率 ${_weather!.rainPop}%：天氣穩定，適合戶外活動",
                              style: TextStyle(
                                color: isRainy ? Colors.lightBlueAccent : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            "https://www.google.com/search?q=${Uri.encodeComponent("${widget.locationTitle} 天氣 降雨機率")}");
                        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: const Text('在 Google 查看完整週氣象與雷達回波', style: TextStyle(fontWeight: FontWeight.bold)),
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.amberAccent),
            ),
            SizedBox(width: 8),
            Text('正在同步即時天氣與降雨機率...', style: TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
      );
    }

    final isRainy = _weather != null && (_weather!.rainPop >= 50 || _weather!.description.contains('雨'));

    return InkWell(
      onTap: _showWeatherDetails,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRainy ? Colors.lightBlueAccent : Colors.cyanAccent.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getWeatherIcon(),
              color: isRainy ? Colors.lightBlueAccent : Colors.amberAccent,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              _weather != null
                  ? "${_weather!.temp.toStringAsFixed(0)}°C  ${_weather!.description}"
                  : "點擊載入即時天氣",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isRainy ? Colors.lightBlueAccent.withOpacity(0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.umbrella_rounded,
                    color: isRainy ? Colors.lightBlueAccent : Colors.white60,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _weather != null ? "${_weather!.rainPop}%" : "--%",
                    style: TextStyle(
                      color: isRainy ? Colors.lightBlueAccent : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.cyanAccent, size: 20),
          ],
        ),
      ),
    );
  }
}
