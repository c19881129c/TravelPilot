import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/context_engine.dart';
import 'weather_card.dart';

class ContextCard extends StatelessWidget {
  final ContextState contextState;

  const ContextCard({Key? key, required this.contextState}) : super(key: key);

  Future<void> _launchMaps(String query) async {
    final uri = Uri.parse("geo:0,0?q=${Uri.encodeComponent(query)}");
    final webUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (contextState.mode) {
      case ContextMode.transit:
        return _buildTransitMode(context);
      case ContextMode.onSite:
        return _buildOnSiteMode(context);
      case ContextMode.freeTime:
        return _buildAllCompletedMode(context);
    }
  }

  Widget _buildTransitMode(BuildContext context) {
    final item = contextState.nextItem!;
    final diff = contextState.timeUntilNext ?? const Duration(minutes: 45);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    String countdownStr;
    if (days > 0) {
      countdownStr = "${days}d ${hours}h ${minutes}m";
    } else if (hours > 0) {
      countdownStr = "${hours}h ${minutes}m";
    } else {
      countdownStr = "${minutes}m";
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amberAccent, width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amberAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.directions_transit_rounded, color: Colors.black, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'NEXT DESTINATION',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              WeatherCard(lat: item.lat, lng: item.lng, locationTitle: item.title),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'COUNTDOWN',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            countdownStr,
            style: const TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.w900,
              color: Colors.amberAccent,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.localAddress,
            style: const TextStyle(fontSize: 15, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              onPressed: () => _launchMaps("${item.lat},${item.lng}"),
              icon: const Icon(Icons.navigation_rounded, size: 28),
              label: const Text(
                'NAVIGATE IN GOOGLE MAPS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnSiteMode(BuildContext context) {
    final item = contextState.activeItem!;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent, width: 2.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Colors.black, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'ON-SITE MODE',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              WeatherCard(lat: item.lat, lng: item.lng, locationTitle: item.title),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BOOKING REFERENCE',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  item.bookingRef.isEmpty ? 'N/A' : item.bookingRef,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOCAL ADDRESS (FOR TAXI)',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  item.localAddress,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Notes: ${item.notes}',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllCompletedMode(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24),
              SizedBox(width: 8),
              Text(
                'ALL EVENTS COMPLETED',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Enjoy Your Free Journey!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'All scheduled itinerary items for this trip are finished. Tap the calendar icon in the top right to manage or add new events.',
            style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}
