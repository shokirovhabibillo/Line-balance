import '../domain/time_study_models.dart';

class TimeStudySummary {
  const TimeStudySummary({
    required this.observedCount,
    required this.validCount,
    required this.excludedCount,
    required this.average,
    required this.median,
    required this.mode,
    required this.minimum,
    required this.maximum,
    required this.range,
    required this.standardDeviationMicros,
  });

  final int observedCount;
  final int validCount;
  final int excludedCount;
  final Duration? average;
  final Duration? median;
  final Duration? mode;
  final Duration? minimum;
  final Duration? maximum;
  final Duration? range;
  final double? standardDeviationMicros;

  int? get standardDeviationMilliseconds =>
      standardDeviationMicros == null ? null : (standardDeviationMicros! / 1000).round();
}

class ElementSummary {
  const ElementSummary({
    required this.elementId,
    required this.observedCount,
    required this.validCount,
    required this.excludedCount,
    required this.average,
    required this.median,
    required this.mode,
    required this.minimum,
    required this.maximum,
    required this.range,
    required this.total,
    required this.standardDeviationMicros,
    this.selectedTime,
  });

  final String elementId;
  final int observedCount;
  final int validCount;
  final int excludedCount;
  final Duration? average;
  final Duration? median;
  final Duration? mode;
  final Duration? minimum;
  final Duration? maximum;
  final Duration? range;
  final Duration total;
  final double? standardDeviationMicros;
  final Duration? selectedTime;
}

class TimeStudyCalculator {
  const TimeStudyCalculator();

  TimeStudySummary summarize(List<CycleRecord> cycles) {
    final observed = cycles.map((e) => e.duration.inMicroseconds).toList();
    final valid = cycles.where((e) => !e.excluded).map((e) => e.duration.inMicroseconds).toList();
    return _summaryFromValues(observed, valid);
  }

  TimeStudySummary _summaryFromValues(List<int> observed, List<int> valid) {
    if (observed.isEmpty) {
      return const TimeStudySummary(
        observedCount: 0,
        validCount: 0,
        excludedCount: 0,
        average: null,
        median: null,
        mode: null,
        minimum: null,
        maximum: null,
        range: null,
        standardDeviationMicros: null,
      );
    }
    final values = [...valid]..sort();
    if (values.isEmpty) {
      return TimeStudySummary(
        observedCount: observed.length,
        validCount: 0,
        excludedCount: observed.length,
        average: null,
        median: null,
        mode: null,
        minimum: null,
        maximum: null,
        range: null,
        standardDeviationMicros: null,
      );
    }
    final sum = values.fold<int>(0, (a, b) => a + b);
    final average = sum / values.length;
    final medianValue = values.length.isOdd
        ? values[values.length ~/ 2].toDouble()
        : (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2;
    final counts = <int, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    final maxFrequency = counts.values.reduce((a, b) => a > b ? a : b);
    final modeValue = maxFrequency > 1
        ? counts.entries.where((e) => e.value == maxFrequency).map((e) => e.key).reduce((a, b) => a < b ? a : b)
        : null;
    final variance = values
            .map((v) => (v - average) * (v - average))
            .fold<double>(0, (a, b) => a + b) /
        values.length;

    return TimeStudySummary(
      observedCount: observed.length,
      validCount: values.length,
      excludedCount: observed.length - values.length,
      average: Duration(microseconds: average.round()),
      median: Duration(microseconds: medianValue.round()),
      mode: modeValue == null ? null : Duration(microseconds: modeValue),
      minimum: Duration(microseconds: values.first),
      maximum: Duration(microseconds: values.last),
      range: Duration(microseconds: values.last - values.first),
      standardDeviationMicros: variance.isFinite ? _sqrt(variance) : null,
    );
  }

  List<ElementSummary> summarizeElements(
    List<CycleRecord> cycles,
    List<WorkElement> elements,
  ) {
    return elements.map((element) {
      final records = cycles.expand((cycle) => cycle.elements).where((record) => record.elementId == element.id).toList();
      final observed = records.map((e) => e.duration.inMicroseconds).toList();
      final valid = records.where((e) => !e.excluded).map((e) => e.duration.inMicroseconds).toList();
      final summary = _summaryFromValues(observed, valid);
      final total = valid.fold<int>(0, (a, b) => a + b);
      return ElementSummary(
        elementId: element.id,
        observedCount: summary.observedCount,
        validCount: summary.validCount,
        excludedCount: summary.excludedCount,
        average: summary.average,
        median: summary.median,
        mode: summary.mode,
        minimum: summary.minimum,
        maximum: summary.maximum,
        range: summary.range,
        total: Duration(microseconds: total),
        standardDeviationMicros: summary.standardDeviationMicros,
        selectedTime: element.selectedTime,
      );
    }).toList();
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    var x = value;
    for (var i = 0; i < 12; i++) {
      x = (x + value / x) / 2;
    }
    return x;
  }
}
