import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class LocationPickResult {
  final double lat;
  final double lng;
  final String placeName;
  final String address;

  LocationPickResult({
    required this.lat,
    required this.lng,
    required this.placeName,
    required this.address,
  });
}

class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const MapPickerScreen({
    Key? key,
    required this.initialLat,
    required this.initialLng,
  }) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final MapController _mapController;
  late LatLng _selectedLocation;
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedAddress = '';
  String _selectedTitle = '';
  bool _isSearching = false;
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = LatLng(widget.initialLat, widget.initialLng);
    _reverseGeocode(_selectedLocation);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&accept-language=zh-TW,ja,en");
      final res = await http.get(url, headers: {
        'User-Agent': 'TravelPilot-App/1.0',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        if (data.isNotEmpty) {
          _showSearchResults(data);
        } else {
          _showToast("找不到符合的地點，請嘗試其他關鍵字");
        }
      }
    } catch (_) {
      _showToast("搜尋連線異常，請稍後重試");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showSearchResults(List data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shrinkWrap: true,
          itemCount: data.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white12),
          itemBuilder: (context, index) {
            final item = data[index];
            final name = item['name'] ?? item['display_name'].split(',')[0];
            final displayName = item['display_name'] ?? '';
            final lat = double.parse(item['lat']);
            final lon = double.parse(item['lon']);

            return ListTile(
              leading: const Icon(Icons.location_on_rounded, color: Colors.amberAccent),
              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                displayName,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(context);
                final newPos = LatLng(lat, lon);
                setState(() {
                  _selectedLocation = newPos;
                  _selectedTitle = name;
                  _selectedAddress = displayName;
                });
                _mapController.move(newPos, 15);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json&accept-language=zh-TW,ja,en");
      final res = await http.get(url, headers: {
        'User-Agent': 'TravelPilot-App/1.0',
      }).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final displayName = data['display_name'] ?? '';
        final name = data['name'] ?? (displayName.isNotEmpty ? displayName.split(',')[0] : '');
        if (mounted) {
          setState(() {
            _selectedAddress = displayName;
            if (_selectedTitle.isEmpty) _selectedTitle = name;
          });
        }
      }
    } catch (_) {
      // Offline fallback
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('在地圖上選擇地點', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // 1. 地圖主體
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                  _selectedTitle = '';
                });
                _reverseGeocode(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travelpilot.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      size: 50,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. 頂部搜尋欄
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: '搜尋地點 (如: 札幌電視塔、小樽運河)',
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _searchPlace,
                    ),
                  ),
                  if (_isSearching)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.amberAccent),
                      onPressed: () => _searchPlace(_searchCtrl.text),
                    ),
                ],
              ),
            ),
          ),

          // 3. 底部確認卡片
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amberAccent, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.touch_app_rounded, color: Colors.amberAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '點選位置資訊',
                        style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        "${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}",
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isReverseGeocoding
                        ? '讀取地址中...'
                        : _selectedAddress.isEmpty
                            ? '已選取座標點 (可點選地圖任一處變更)'
                            : _selectedAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(
                          context,
                          LocationPickResult(
                            lat: _selectedLocation.latitude,
                            lng: _selectedLocation.longitude,
                            placeName: _selectedTitle,
                            address: _selectedAddress,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded, size: 24),
                      label: const Text(
                        '確定使用此位置',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
