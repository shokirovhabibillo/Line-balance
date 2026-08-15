enum WorkType {
  cyclic,
  nonCyclic,
}

enum WorkElementType {
  productive,
  nonProductive,
}

class WorkElement {
  const WorkElement({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final WorkElementType type;
}

class TimeStudySession {
  const TimeStudySession({
    required this.name,
    required this.workType,
    required this.elements,
  });

  final String name;
  final WorkType workType;
  final List<WorkElement> elements;
}
