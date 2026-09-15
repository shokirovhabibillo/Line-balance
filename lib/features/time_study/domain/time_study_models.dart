enum WorkType { cyclic, nonCyclic }

enum WorkElementType { productive, nonProductive }

class WorkElement {
  const WorkElement({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final WorkElementType type;

  WorkElement copyWith({
    String? name,
    WorkElementType? type,
  }) {
    return WorkElement(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
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
