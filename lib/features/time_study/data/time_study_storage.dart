import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/time_study_models.dart';

class TimeStudyStorage {
  const TimeStudyStorage();

  static const _key = 'time_study_session_v2';
  static const _legacyKey = 'time_study_session_v1';

  Future<TimeStudySessionData?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key) ?? preferences.getString(_legacyKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return TimeStudySessionData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(TimeStudySessionData data) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(data.toJson()));
  }
}

class TimeStudySessionData {
  const TimeStudySessionData({
    required this.sessionName,
    required this.workType,
    required this.elements,
    required this.cycles,
    this.department = '',
    this.section = '',
    this.line = '',
    this.station = '',
    this.worker = '',
  });

  final String sessionName;
  final WorkType workType;
  final List<WorkElement> elements;
  final List<CycleRecord> cycles;
  final String department;
  final String section;
  final String line;
  final String station;
  final String worker;

  Map<String, dynamic> toJson() => {
        'sessionName': sessionName,
        'workType': workType.name,
        'department': department,
        'section': section,
        'line': line,
        'station': station,
        'worker': worker,
        'elements': elements.map(workElementToJson).toList(),
        'cycles': cycles.map(cycleRecordToJson).toList(),
      };

  factory TimeStudySessionData.fromJson(Map<String, dynamic> json) {
    final workType = WorkType.values.firstWhere(
      (value) => value.name == json['workType'],
      orElse: () => WorkType.cyclic,
    );
    final elements = (json['elements'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(workElementFromJson)
        .toList();
    final cycles = (json['cycles'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(cycleRecordFromJson)
        .toList();
    return TimeStudySessionData(
      sessionName: json['sessionName'] as String? ?? '',
      workType: workType,
      department: json['department'] as String? ?? '',
      section: json['section'] as String? ?? '',
      line: json['line'] as String? ?? '',
      station: json['station'] as String? ?? '',
      worker: json['worker'] as String? ?? '',
      elements: List.unmodifiable(elements),
      cycles: List.unmodifiable(cycles),
    );
  }
}

Map<String, dynamic> workElementToJson(WorkElement e) => {
      'id': e.id,
      'name': e.name,
      'type': e.type.name,
      'requirements': e.requirements.map((v) => v.name).toList(),
      'property': e.property,
      'verificationMethods': e.verificationMethods.map((v) => v.name).toList(),
      'basis': e.basis,
      'measurementMode': e.measurementMode.name,
      'selectedTimeUs': e.selectedTime?.inMicroseconds,
    };

WorkElement workElementFromJson(Map<String, dynamic> json) {
  final type = WorkElementType.values.firstWhere(
    (v) => v.name == json['type'],
    orElse: () => WorkElementType.productive,
  );
  final requirements = (json['requirements'] as List<dynamic>? ?? const [])
      .whereType<String>()
      .map((name) => WorkRequirement.values.firstWhere((v) => v.name == name, orElse: () => WorkRequirement.none))
      .where((v) => v != WorkRequirement.none)
      .toList();
  final verification = (json['verificationMethods'] as List<dynamic>? ?? const [])
      .whereType<String>()
      .map((name) => VerificationMethod.values.firstWhere((v) => v.name == name, orElse: () => VerificationMethod.visual))
      .toList();
  final mode = MeasurementMode.values.firstWhere(
    (v) => v.name == json['measurementMode'],
    orElse: () => MeasurementMode.startFinish,
  );
  return WorkElement(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    type: type,
    requirements: List.unmodifiable(requirements),
    property: json['property'] as String? ?? '',
    verificationMethods: List.unmodifiable(verification),
    basis: json['basis'] as String? ?? '',
    measurementMode: mode,
    selectedTime: json['selectedTimeUs'] == null ? null : Duration(microseconds: json['selectedTimeUs'] as int),
  );
}

Map<String, dynamic> elementRecordToJson(ElementRecord r) => {
      'elementId': r.elementId,
      'durationUs': r.duration.inMicroseconds,
      'recordedAt': r.recordedAt.toIso8601String(),
      'excluded': r.excluded,
      'exclusionReason': r.exclusionReason,
    };

ElementRecord elementRecordFromJson(Map<String, dynamic> json) => ElementRecord(
      elementId: json['elementId'] as String? ?? '',
      duration: Duration(microseconds: json['durationUs'] as int? ?? 0),
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
      excluded: json['excluded'] as bool? ?? false,
      exclusionReason: json['exclusionReason'] as String? ?? '',
    );

Map<String, dynamic> cycleRecordToJson(CycleRecord c) => {
      'number': c.number,
      'durationUs': c.duration.inMicroseconds,
      'recordedAt': c.recordedAt.toIso8601String(),
      'excluded': c.excluded,
      'exclusionReason': c.exclusionReason,
      'elements': c.elements.map(elementRecordToJson).toList(),
    };

CycleRecord cycleRecordFromJson(Map<String, dynamic> json) => CycleRecord(
      number: json['number'] as int? ?? 0,
      duration: Duration(microseconds: json['durationUs'] as int? ?? 0),
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
      excluded: json['excluded'] as bool? ?? false,
      exclusionReason: json['exclusionReason'] as String? ?? '',
      elements: List.unmodifiable(
        (json['elements'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(elementRecordFromJson),
      ),
    );
