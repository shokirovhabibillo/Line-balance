import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LineBalanceStation {
  const LineBalanceStation({
    required this.id,
    required this.sequence,
    required this.name,
    required this.workloadSeconds,
    this.operator = '',
  });

  final String id;
  final int sequence;
  final String name;
  final double workloadSeconds;
  final String operator;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sequence': sequence,
        'name': name,
        'workloadSeconds': workloadSeconds,
        'operator': operator,
      };

  factory LineBalanceStation.fromJson(Map<String, dynamic> json) => LineBalanceStation(
        id: json['id'] as String? ?? '',
        sequence: json['sequence'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        workloadSeconds: (json['workloadSeconds'] as num?)?.toDouble() ?? 0,
        operator: json['operator'] as String? ?? '',
      );
}

class LineBalancePlan {
  const LineBalancePlan({
    required this.id,
    required this.name,
    required this.taktSeconds,
    required this.stations,
    this.availableSeconds = 0,
    this.demandPerDay = 0,
  });

  final String id;
  final String name;
  final double taktSeconds;
  final List<LineBalanceStation> stations;
  final double availableSeconds;
  final double demandPerDay;

  double get totalWorkload => stations.fold(0, (sum, s) => sum + s.workloadSeconds);
  double get bottleneck => stations.isEmpty ? 0 : stations.map((s) => s.workloadSeconds).reduce((a, b) => a > b ? a : b);
  double get balancePercent => bottleneck <= 0 || stations.isEmpty ? 0 : (totalWorkload / (bottleneck * stations.length)) * 100;
  int get theoreticalStations => taktSeconds <= 0 ? 0 : (totalWorkload / taktSeconds).ceil();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'taktSeconds': taktSeconds,
        'availableSeconds': availableSeconds,
        'demandPerDay': demandPerDay,
        'stations': stations.map((e) => e.toJson()).toList(),
      };

  factory LineBalancePlan.fromJson(Map<String, dynamic> json) => LineBalancePlan(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        taktSeconds: (json['taktSeconds'] as num?)?.toDouble() ?? 0,
        availableSeconds: (json['availableSeconds'] as num?)?.toDouble() ?? 0,
        demandPerDay: (json['demandPerDay'] as num?)?.toDouble() ?? 0,
        stations: (json['stations'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(LineBalanceStation.fromJson)
            .toList(),
      );
}

class LineBalanceStorage {
  static const key = 'line_balance_v1';

  Future<List<LineBalancePlan>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(LineBalancePlan.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<LineBalancePlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(plans.map((e) => e.toJson()).toList()));
  }
}
