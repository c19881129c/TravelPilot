import 'dart:convert';

class ItineraryItem {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final double lat;
  final double lng;
  final String localAddress;
  final String bookingRef;
  final String notes;

  ItineraryItem({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.lat,
    required this.lng,
    required this.localAddress,
    required this.bookingRef,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'localAddress': localAddress,
      'bookingRef': bookingRef,
      'notes': notes,
    };
  }

  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      localAddress: map['localAddress'] ?? '',
      bookingRef: map['bookingRef'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ItineraryItem.fromJson(String source) =>
      ItineraryItem.fromMap(json.decode(source));
}
