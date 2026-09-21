import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'time_study_storage.dart';

class TimeStudyHistoryEntry {
  const TimeStudyHistoryEntry({required this.savedAt, required this.data});
  final DateTime savedAt;
  final TimeStudySessionData data;

  Map<String, dynamic> toJson() => {'savedAt': savedAt.toIso8601String(), 'data': data.toJson()};

  factory TimeStudyHistoryEntry.fromJson(Map<String, dynamic> json) => TimeStudyHistoryEntry(
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
        data: TimeStudySessionData.fromJson((json['data'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}

class TimeStudyHistoryStorage {
  static const _key = 'time_study_history_v1';

  Future<List<TimeStudyHistoryEntry>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(TimeStudyHistoryEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(TimeStudySessionData data) async {
    final entries = await load();
    entries.insert(0, TimeStudyHistoryEntry(savedAt: DateTime.now(), data: data));
    final unique = <String, TimeStudyHistoryEntry>{};
    for (final entry in entries) {
      final key = '${entry.data.sessionName}|${entry.savedAt.millisecondsSinceEpoch ~/ 1000}';
      unique[key] = entry;
    }
    final limited = unique.values.take(30).toList();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(limited.map((e) => e.toJson()).toList()));
  }
}
