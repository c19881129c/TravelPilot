import 'dart:convert';

class VaultItem {
  final String title;
  final String value;
  final String category; // 'Flight', 'Hotel', 'Emergency', 'Note'

  VaultItem({
    required this.title,
    required this.value,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'value': value,
        'category': category,
      };

  factory VaultItem.fromMap(Map<String, dynamic> map) => VaultItem(
        title: map['title'] ?? '',
        value: map['value'] ?? '',
        category: map['category'] ?? 'Note',
      );

  String toJson() => json.encode(toMap());

  factory VaultItem.fromJson(String source) =>
      VaultItem.fromMap(json.decode(source));
}
