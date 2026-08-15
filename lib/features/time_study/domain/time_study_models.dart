enum WorkType { cyclic, nonCyclic }
enum WorkElementType { productive, nonProductive }

class WorkElement {
  const WorkElement({required this.id, required this.name, required this.type});
  final String id;
  final String name;
  final WorkElementType type;
}

class CycleRecord {
  const CycleRecord({
    required this.number,
    required this.duration,
    required this.recordedAt,
  });
  final int number;
  final Duration duration;
  final DateTime recordedAt;
}
