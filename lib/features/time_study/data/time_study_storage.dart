import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/time_study_models.dart';

class TimeStudyStorage {
  const TimeStudyStorage();

  static const _key = 'time_study_session_v1';

  Future<TimeStudySessionData?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      return TimeStudySessionData.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
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
  });

  final String sessionName;
  final WorkType workType;
  final List<WorkElement> elements;
  final List<CycleRecord> cycles;

  Map<String, dynamic> toJson() => {
        'sessionName': sessionName,
        'workType': workType.name,
        'elements': elements.map(workElementToJson).toList(),
        'cycles': cycles.map(cycleRecordToJson).toList(),
      };

  factory TimeStudySessionData.fromJson(Map<String, dynamic> json) {
    final typeName = json['workType'] as String?;
    final workType = WorkType.values.firstWhere(
      (value) => value.name == typeName,
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
      elements: List.unmodifiable(elements),
      cycles: List.unmodifiable(cycles),
    );
  }
}

Map<String, dynamic> workElementToJson(WorkElement element) => {
      'id': element.id,
      'name': element.name,
      'type': element.type.name,
      'requirements': element.requirements.map((e) => e.name).toList(),
      'verificationMethods':
          element.verificationMethods.map((e) => e.name).toList(),
      'basis': element.basis,
    };

WorkElement workElementFromJson(Map<String, dynamic> json) {
  final typeName = json['type'] as String?;
  final type = WorkElementType.values.firstWhere(
    (value) => value.name == typeName,
    orElse: () => WorkElementType.productive,
  );

  final requirements = (json['requirements'] as List<dynamic>? ?? const [])
      .whereType<String>()
      .map(
        (name) => WorkRequirement.values.firstWhere(
          (value) => value.name == name,
          orElse: () => WorkRequirement.none,
        ),
      )
      .where((value) => value != WorkRequirement.none)
      .toList();

  final verificationMethods =
      (json['verificationMethods'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .map(
            (name) => VerificationMethod.values.firstWhere(
              (value) => value.name == name,
              orElse: () => VerificationMethod.visual,
            ),
          )
          .toList();

  return WorkElement(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    type: type,
    requirements: List.unmodifiable(requirements),
    verificationMethods: List.unmodifiable(verificationMethods),
    basis: json['basis'] as String? ?? '',
  );
}

Map<String, dynamic> elementRecordToJson(ElementRecord record) => {
      'elementId': record.elementId,
      'durationUs': record.duration.inMicroseconds,
      'recordedAt': record.recordedAt.toIso8601String(),
    };

ElementRecord elementRecordFromJson(Map<String, dynamic> json) => ElementRecord(
      elementId: json['elementId'] as String? ?? '',
      duration: Duration(microseconds: json['durationUs'] as int? ?? 0),
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
    );

Map<String, dynamic> cycleRecordToJson(CycleRecord cycle) => {
      'number': cycle.number,
      'durationUs': cycle.duration.inMicroseconds,
      'recordedAt': cycle.recordedAt.toIso8601String(),
      'elements': cycle.elements.map(elementRecordToJson).toList(),
    };

CycleRecord cycleRecordFromJson(Map<String, dynamic> json) {
  final elements = (json['elements'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(elementRecordFromJson)
      .toList();

  return CycleRecord(
    number: json['number'] as int? ?? 0,
    duration: Duration(microseconds: json['durationUs'] as int? ?? 0),
    recordedAt:
        DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
    elements: List.unmodifiable(elements),
  );
}
