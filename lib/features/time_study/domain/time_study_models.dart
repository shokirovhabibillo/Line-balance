enum WorkType { cyclic, nonCyclic }

enum WorkElementType { productive, nonProductive }

enum WorkRequirement {
  safety,
  quality,
  sequence,
  stepSequence,
  qcos,
  none,
}

enum VerificationMethod {
  visual,
  auditory,
  touch,
  measurement,
}

enum MeasurementMode {
  startFinish,
  cycleLinkedFinishOnly,
}

class WorkElement {
  const WorkElement({
    required this.id,
    required this.name,
    required this.type,
    this.requirements = const [],
    this.property = '',
    this.verificationMethods = const [],
    this.basis = '',
    this.measurementMode = MeasurementMode.startFinish,
    this.selectedTime,
  });

  final String id;
  final String name;
  final WorkElementType type;
  final List<WorkRequirement> requirements;
  final String property;
  final List<VerificationMethod> verificationMethods;
  final String basis;
  final MeasurementMode measurementMode;
  final Duration? selectedTime;

  WorkElement copyWith({
    String? name,
    WorkElementType? type,
    List<WorkRequirement>? requirements,
    String? property,
    List<VerificationMethod>? verificationMethods,
    String? basis,
    MeasurementMode? measurementMode,
    Duration? selectedTime,
  }) {
    return WorkElement(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      requirements: requirements ?? this.requirements,
      property: property ?? this.property,
      verificationMethods: verificationMethods ?? this.verificationMethods,
      basis: basis ?? this.basis,
      measurementMode: measurementMode ?? this.measurementMode,
      selectedTime: selectedTime ?? this.selectedTime,
    );
  }
}

class ElementRecord {
  const ElementRecord({
    required this.elementId,
    required this.duration,
    required this.recordedAt,
    this.excluded = false,
    this.exclusionReason = '',
  });

  final String elementId;
  final Duration duration;
  final DateTime recordedAt;
  final bool excluded;
  final String exclusionReason;

  ElementRecord copyWith({
    Duration? duration,
    bool? excluded,
    String? exclusionReason,
  }) {
    return ElementRecord(
      elementId: elementId,
      duration: duration ?? this.duration,
      recordedAt: recordedAt,
      excluded: excluded ?? this.excluded,
      exclusionReason: exclusionReason ?? this.exclusionReason,
    );
  }
}

class CycleRecord {
  const CycleRecord({
    required this.number,
    required this.duration,
    required this.recordedAt,
    this.elements = const [],
    this.excluded = false,
    this.exclusionReason = '',
  });

  final int number;
  final Duration duration;
  final DateTime recordedAt;
  final List<ElementRecord> elements;
  final bool excluded;
  final String exclusionReason;

  CycleRecord copyWith({
    int? number,
    List<ElementRecord>? elements,
    Duration? duration,
    bool? excluded,
    String? exclusionReason,
  }) {
    return CycleRecord(
      number: number ?? this.number,
      duration: duration ?? this.duration,
      recordedAt: recordedAt,
      elements: elements ?? this.elements,
      excluded: excluded ?? this.excluded,
      exclusionReason: exclusionReason ?? this.exclusionReason,
    );
  }
}
