import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.module,
    required this.title,
    required this.savedAt,
    this.subtitle = '',
  });

  final String module;
  final String title;
  final String subtitle;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'module': module,
        'title': title,
        'subtitle': subtitle,
        'savedAt': savedAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        module: json['module'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class AppHistoryStorage {
  static const _key = 'global_history_v1';

  Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(HistoryEntry.fromJson)
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> add(HistoryEntry entry) async {
    final entries = await load();
    entries.insert(0, entry);
    final limited = entries.take(100).map((e) => e.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(limited));
  }
}
