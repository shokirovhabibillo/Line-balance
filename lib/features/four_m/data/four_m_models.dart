class Employee {
  Employee({
    required this.id,
    required this.name,
    this.position = '',
    this.brigade = '',
    this.station = '',
    this.shift = '',
    this.jitLevel = 0,
    this.flexibility = const {},
    this.attendanceStatus = 'Present',
  });

  final String id;
  final String name;
  final String position;
  final String brigade;
  final String station;
  final String shift;
  final int jitLevel;
  final Map<String, int> flexibility;
  final String attendanceStatus;

  Employee copyWith({
    String? name,
    String? position,
    String? brigade,
    String? station,
    String? shift,
    int? jitLevel,
    Map<String, int>? flexibility,
    String? attendanceStatus,
  }) => Employee(
        id: id,
        name: name ?? this.name,
        position: position ?? this.position,
        brigade: brigade ?? this.brigade,
        station: station ?? this.station,
        shift: shift ?? this.shift,
        jitLevel: jitLevel ?? this.jitLevel,
        flexibility: flexibility ?? this.flexibility,
        attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      );
}

class MachineInfo {
  const MachineInfo({required this.name, required this.station, this.status = 'Ready', this.cycleTimeMs = 0});
  final String name;
  final String station;
  final String status;
  final int cycleTimeMs;
}

class MaterialInfo {
  const MaterialInfo({required this.name, required this.partNumber, this.requiredQty = 0, this.availableQty = 0});
  final String name;
  final String partNumber;
  final double requiredQty;
  final double availableQty;

  double get shortage => (requiredQty - availableQty).clamp(0, double.infinity);
}

class MethodInfo {
  const MethodInfo({required this.operation, required this.standard, this.requirement = '', this.verification = ''});
  final String operation;
  final String standard;
  final String requirement;
  final String verification;
}

class Workstation4M {
  const Workstation4M({required this.station, this.man = '', this.machine = '', this.material = '', this.method = ''});
  final String station;
  final String man;
  final String machine;
  final String material;
  final String method;
}
