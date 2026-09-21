import 'package:flutter_test/flutter_test.dart';
import 'package:line_balance_platform/features/time_study/application/time_study_calculator.dart';
import 'package:line_balance_platform/features/time_study/domain/time_study_models.dart';

void main() {
  const calculator = TimeStudyCalculator();

  test('empty cycles return empty summary', () {
    final summary = calculator.summarize(const []);
    expect(summary.observedCount, 0);
    expect(summary.average, isNull);
  });

  test('summary calculates average min max range median and mode', () {
    final now = DateTime(2026, 1, 1);
    final cycles = [
      CycleRecord(number: 1, duration: const Duration(seconds: 8), recordedAt: now),
      CycleRecord(number: 2, duration: const Duration(seconds: 10), recordedAt: now),
      CycleRecord(number: 3, duration: const Duration(seconds: 10), recordedAt: now),
      CycleRecord(number: 4, duration: const Duration(seconds: 12), recordedAt: now),
    ];
    final summary = calculator.summarize(cycles);
    expect(summary.validCount, 4);
    expect(summary.average, const Duration(seconds: 10));
    expect(summary.median, const Duration(seconds: 10));
    expect(summary.mode, const Duration(seconds: 10));
    expect(summary.minimum, const Duration(seconds: 8));
    expect(summary.maximum, const Duration(seconds: 12));
    expect(summary.range, const Duration(seconds: 4));
  });

  test('excluded cycles are not used in valid statistics', () {
    final now = DateTime(2026, 1, 1);
    final cycles = [
      CycleRecord(number: 1, duration: const Duration(seconds: 8), recordedAt: now),
      CycleRecord(number: 2, duration: const Duration(seconds: 20), recordedAt: now, excluded: true, exclusionReason: 'Abnormal interruption'),
    ];
    final summary = calculator.summarize(cycles);
    expect(summary.observedCount, 2);
    expect(summary.validCount, 1);
    expect(summary.excludedCount, 1);
    expect(summary.average, const Duration(seconds: 8));
  });

  test('element summary calculates average and total', () {
    final now = DateTime(2026, 1, 1);
    const element = WorkElement(id: '1', name: 'Test', type: WorkElementType.productive);
    final cycles = [
      CycleRecord(number: 1, duration: const Duration(seconds: 5), recordedAt: now, elements: [ElementRecord(elementId: '1', duration: const Duration(seconds: 2), recordedAt: now)]),
      CycleRecord(number: 2, duration: const Duration(seconds: 6), recordedAt: now, elements: [ElementRecord(elementId: '1', duration: const Duration(seconds: 4), recordedAt: now)]),
    ];
    final summary = calculator.summarizeElements(cycles, [element]).single;
    expect(summary.validCount, 2);
    expect(summary.average, const Duration(seconds: 3));
    expect(summary.total, const Duration(seconds: 6));
  });
}
