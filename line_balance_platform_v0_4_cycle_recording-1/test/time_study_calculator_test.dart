import 'package:flutter_test/flutter_test.dart';
import 'package:line_balance_platform/features/time_study/application/time_study_calculator.dart';
import 'package:line_balance_platform/features/time_study/domain/time_study_models.dart';

void main() {
  const calculator = TimeStudyCalculator();

  test('empty cycles return empty summary', () {
    final s = calculator.summarize(const []);
    expect(s.count, 0);
    expect(s.average, isNull);
  });

  test('summary calculates average min max range', () {
    final cycles = [
      CycleRecord(number: 1, duration: const Duration(seconds: 40), recordedAt: DateTime(2026)),
      CycleRecord(number: 2, duration: const Duration(seconds: 50), recordedAt: DateTime(2026)),
      CycleRecord(number: 3, duration: const Duration(seconds: 45), recordedAt: DateTime(2026)),
    ];
    final s = calculator.summarize(cycles);
    expect(s.count, 3);
    expect(s.average, const Duration(seconds: 45));
    expect(s.minimum, const Duration(seconds: 40));
    expect(s.maximum, const Duration(seconds: 50));
    expect(s.range, const Duration(seconds: 10));
  });
}
