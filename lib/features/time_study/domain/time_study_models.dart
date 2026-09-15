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

class WorkElement {
  const WorkElement({
    required this.id,
    required this.name,
    required this.type,
    this.requirements = const [],
    this.verificationMethods = const [],
    this.basis = '',
  });

  final String id;
  final String name;
  final WorkElementType type;
  final List<WorkRequirement> requirements;
  final List<VerificationMethod> verificationMethods;
  final String basis;

  WorkElement copyWith({
    String? name,
    WorkElementType? type,
    List<WorkRequirement>? requirements,
    List<VerificationMethod>? verificationMethods,
    String? basis,
  }) {
    return WorkElement(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      requirements: requirements ?? this.requirements,
      verificationMethods: verificationMethods ?? this.verificationMethods,
      basis: basis ?? this.basis,
    );
  }
}

class ElementRecord {
  const ElementRecord({
    required this.elementId,
    required this.duration,
    required this.recordedAt,
  });

  final String elementId;
  final Duration duration;
  final DateTime recordedAt;
}

class CycleRecord {
  const CycleRecord({
    required this.number,
    required this.duration,
    required this.recordedAt,
    this.elements = const [],
  });

  final int number;
  final Duration duration;
  final DateTime recordedAt;
  final List<ElementRecord> elements;

  CycleRecord copyWith({
    int? number,
    List<ElementRecord>? elements,
  }) {
    return CycleRecord(
      number: number ?? this.number,
      duration: duration,
      recordedAt: recordedAt,
      elements: elements ?? this.elements,
    );
  }
}
