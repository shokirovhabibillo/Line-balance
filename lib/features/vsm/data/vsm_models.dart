import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class VsmProcess {
  const VsmProcess({
    required this.id,
    required this.sequence,
    required this.name,
    required this.cycleTimeSeconds,
    this.changeoverSeconds = 0,
    this.uptimePercent = 100,
    this.wip = 0,
    this.leadTimeSeconds = 0,
    this.valueAdd = true,
  });

  final String id;
  final int sequence;
  final String name;
  final double cycleTimeSeconds;
  final double changeoverSeconds;
  final double uptimePercent;
  final double wip;
  final double leadTimeSeconds;
  final bool valueAdd;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sequence': sequence,
        'name': name,
        'cycleTimeSeconds': cycleTimeSeconds,
        'changeoverSeconds': changeoverSeconds,
        'uptimePercent': uptimePercent,
        'wip': wip,
        'leadTimeSeconds': leadTimeSeconds,
        'valueAdd': valueAdd,
      };

  factory VsmProcess.fromJson(Map<String, dynamic> json) => VsmProcess(
        id: json['id'] as String? ?? '',
        sequence: json['sequence'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        cycleTimeSeconds: (json['cycleTimeSeconds'] as num?)?.toDouble() ?? 0,
        changeoverSeconds: (json['changeoverSeconds'] as num?)?.toDouble() ?? 0,
        uptimePercent: (json['uptimePercent'] as num?)?.toDouble() ?? 100,
        wip: (json['wip'] as num?)?.toDouble() ?? 0,
        leadTimeSeconds: (json['leadTimeSeconds'] as num?)?.toDouble() ?? 0,
        valueAdd: json['valueAdd'] as bool? ?? true,
      );
}

class VsmMap {
  const VsmMap({
    required this.id,
    required this.name,
    required this.processes,
    this.customerDemandPerDay = 0,
    this.state = 'Current State',
  });

  final String id;
  final String name;
  final List<VsmProcess> processes;
  final double customerDemandPerDay;
  final String state;

  double get totalLeadTime => processes.fold(0, (sum, p) => sum + p.leadTimeSeconds);
  double get valueAddTime => processes.where((p) => p.valueAdd).fold(0, (sum, p) => sum + p.cycleTimeSeconds);
  double get totalCycleTime => processes.fold(0, (sum, p) => sum + p.cycleTimeSeconds);
  double get vaRatio => totalLeadTime <= 0 ? 0 : valueAddTime / totalLeadTime * 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'customerDemandPerDay': customerDemandPerDay,
        'state': state,
        'processes': processes.map((e) => e.toJson()).toList(),
      };

  factory VsmMap.fromJson(Map<String, dynamic> json) => VsmMap(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        customerDemandPerDay: (json['customerDemandPerDay'] as num?)?.toDouble() ?? 0,
        state: json['state'] as String? ?? 'Current State',
        processes: (json['processes'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(VsmProcess.fromJson)
            .toList(),
      );
}

class VsmStorage {
  static const key = 'vsm_v1';

  Future<List<VsmMap>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(VsmMap.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<VsmMap> maps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(maps.map((e) => e.toJson()).toList()));
  }
}
