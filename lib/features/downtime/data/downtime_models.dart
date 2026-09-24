import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DowntimeRecord {
  const DowntimeRecord({
    required this.id,
    required this.category,
    required this.cause,
    required this.start,
    required this.end,
    this.productive = false,
    this.note = '',
  });

  final String id;
  final String category;
  final String cause;
  final DateTime start;
  final DateTime end;
  final bool productive;
  final String note;

  Duration get duration => end.isAfter(start) ? end.difference(start) : Duration.zero;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'cause': cause,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'productive': productive,
        'note': note,
      };

  factory DowntimeRecord.fromJson(Map<String, dynamic> json) => DowntimeRecord(
        id: json['id'] as String? ?? '',
        category: json['category'] as String? ?? '',
        cause: json['cause'] as String? ?? '',
        start: DateTime.tryParse(json['start'] as String? ?? '') ?? DateTime.now(),
        end: DateTime.tryParse(json['end'] as String? ?? '') ?? DateTime.now(),
        productive: json['productive'] as bool? ?? false,
        note: json['note'] as String? ?? '',
      );
}

class DowntimeStorage {
  static const key = 'downtime_v1';

  Future<List<DowntimeRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(DowntimeRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<DowntimeRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(records.map((e) => e.toJson()).toList()));
  }
}
