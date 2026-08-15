import '../domain/time_study_models.dart';

class TimeStudySummary {
  const TimeStudySummary({
    required this.count,
    required this.average,
    required this.minimum,
    required this.maximum,
    required this.range,
  });
  final int count;
  final Duration? average;
  final Duration? minimum;
  final Duration? maximum;
  final Duration? range;
}

class TimeStudyCalculator {
  const TimeStudyCalculator();

  TimeStudySummary summarize(List<CycleRecord> cycles) {
    if (cycles.isEmpty) {
      return const TimeStudySummary(
        count: 0,
        average: null,
        minimum: null,
        maximum: null,
        range: null,
      );
    }
    final values = cycles.map((e) => e.duration.inMicroseconds).toList()..sort();
    final total = values.fold<int>(0, (a, b) => a + b);
    return TimeStudySummary(
      count: values.length,
      average: Duration(microseconds: total ~/ values.length),
      minimum: Duration(microseconds: values.first),
      maximum: Duration(microseconds: values.last),
      range: Duration(microseconds: values.last - values.first),
    );
  }
}
