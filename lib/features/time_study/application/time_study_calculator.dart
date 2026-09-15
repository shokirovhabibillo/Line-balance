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

class ElementSummary {
  const ElementSummary({
    required this.elementId,
    required this.count,
    required this.average,
    required this.minimum,
    required this.maximum,
    required this.total,
  });

  final String elementId;
  final int count;
  final Duration? average;
  final Duration? minimum;
  final Duration? maximum;
  final Duration total;
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

  List<ElementSummary> summarizeElements(
    List<CycleRecord> cycles,
    List<WorkElement> elements,
  ) {
    return elements.map((element) {
      final records = cycles
          .expand((cycle) => cycle.elements)
          .where((record) => record.elementId == element.id)
          .toList();

      if (records.isEmpty) {
        return ElementSummary(
          elementId: element.id,
          count: 0,
          average: null,
          minimum: null,
          maximum: null,
          total: Duration.zero,
        );
      }

      final values = records.map((e) => e.duration.inMicroseconds).toList()
        ..sort();
      final total = values.fold<int>(0, (a, b) => a + b);

      return ElementSummary(
        elementId: element.id,
        count: values.length,
        average: Duration(microseconds: total ~/ values.length),
        minimum: Duration(microseconds: values.first),
        maximum: Duration(microseconds: values.last),
        total: Duration(microseconds: total),
      );
    }).toList();
  }
}
