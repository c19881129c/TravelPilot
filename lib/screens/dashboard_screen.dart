import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/itinerary_item.dart';
import '../services/context_engine.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../widgets/context_card.dart';
import '../widgets/vault_drawer.dart';
import 'trip_manager_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ItineraryItem> _items = [];
  Position? _currentPosition;
  ContextState _contextState = ContextState(mode: ContextMode.allCompleted);
  bool _loading = true;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _initDashboard();
    _tickerTimer = Timer.periodic(const Duration(seconds: 60), (_) => _evaluate());
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDashboard() async {
    setState(() => _loading = true);
    final items = await StorageService.getItinerary();
    final pos = await LocationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _items = items;
        _currentPosition = pos;
        _loading = false;
      });
      _evaluate();
    }
  }

  void _evaluate() {
    final state = ContextEngine.evaluateContext(
      items: _items,
      now: DateTime.now(),
      userPos: _currentPosition,
    );
    if (mounted) {
      setState(() => _contextState = state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF030712),
      drawer: const VaultDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 28),
          tooltip: 'Open Vault',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRAVELPILOT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
            Text(
              'v1.0.1+2',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.cyanAccent,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.cyanAccent, size: 26),
            tooltip: 'Trip Manager',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TripManagerScreen()),
              );
              _initDashboard();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Refresh Context',
            onPressed: _initDashboard,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent),
            )
          : RefreshIndicator(
              color: Colors.amberAccent,
              backgroundColor: const Color(0xFF1E293B),
              onRefresh: _initDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ContextCard(contextState: _contextState),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ITINERARY OVERVIEW',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white60,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TripManagerScreen()),
                            );
                            _initDashboard();
                          },
                          child: const Text(
                            'MANAGE ALL',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.take(3).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.amberAccent : Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.localAddress,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
