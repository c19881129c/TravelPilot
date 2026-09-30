import 'package:geolocator/geolocator.dart';
import '../models/itinerary_item.dart';
import 'location_service.dart';

enum ContextMode {
  transit,
  onSite,
  freeTime,
}

class ContextState {
  final ContextMode mode;
  final ItineraryItem? activeItem;
  final ItineraryItem? nextItem;
  final Duration? timeUntilNext;
  final double? distanceMeters;

  ContextState({
    required this.mode,
    this.activeItem,
    this.nextItem,
    this.timeUntilNext,
    this.distanceMeters,
  });
}

class ContextEngine {
  /// Evaluates GPS and current time against the local itinerary
  static ContextState evaluateContext({
    required List<ItineraryItem> items,
    required DateTime now,
    Position? userPos,
  }) {
    if (items.isEmpty) {
      return ContextState(mode: ContextMode.freeTime);
    }

    // 1. Check if we are currently "On-Site" (within event time or < 300m of destination)
    for (final item in items) {
      final isDuringEvent =
          now.isAfter(item.startTime) && now.isBefore(item.endTime);

      double? dist;
      if (userPos != null) {
        dist = LocationService.calculateDistance(
          userPos.latitude,
          userPos.longitude,
          item.lat,
          item.lng,
        );
      }

      final isWithin300m = dist != null && dist <= 300.0;

      if (isDuringEvent ||
          (isWithin300m && now.difference(item.startTime).inMinutes.abs() <= 30)) {
        return ContextState(
          mode: ContextMode.onSite,
          activeItem: item,
          distanceMeters: dist,
        );
      }
    }

    // 2. Find the immediate next upcoming event
    ItineraryItem? upcoming;
    for (final item in items) {
      if (item.startTime.isAfter(now)) {
        if (upcoming == null || item.startTime.isBefore(upcoming.startTime)) {
          upcoming = item;
        }
      }
    }

    // Whenever there is an upcoming event, ALWAYS show Transit / Next Destination mode
    if (upcoming != null) {
      final diff = upcoming.startTime.difference(now);
      double? dist;
      if (userPos != null) {
        dist = LocationService.calculateDistance(
          userPos.latitude,
          userPos.longitude,
          upcoming.lat,
          upcoming.lng,
        );
      }
      return ContextState(
        mode: ContextMode.transit,
        nextItem: upcoming,
        timeUntilNext: diff,
        distanceMeters: dist,
      );
    }

    // 3. If all events have passed, return clean completion state
    return ContextState(mode: ContextMode.freeTime);
  }
}
