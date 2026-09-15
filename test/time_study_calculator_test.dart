import 'package:flutter_test/flutter_test.dart';
import 'package:line_balance_platform/features/time_study/application/time_study_calculator.dart';
import 'package:line_balance_platform/features/time_study/domain/time_study_models.dart';

void main() {
  const calculator = TimeStudyCalculator();

  test('empty cycles return empty summary', () {
    final s = calculator.summarize(const []);
    expect(s.count, 0);
    expect(s.average, isNull);
    expect(s.minimum, isNull);
    expect(s.maximum, isNull);
    expect(s.range, isNull);
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

  test('element summary calculates average min max and total', () {
    const element = WorkElement(
      id: 'e1',
      name: 'Element 1',
      type: WorkElementType.productive,
    );

    final cycles = [
      CycleRecord(
        number: 1,
        duration: const Duration(seconds: 10),
        recordedAt: DateTime(2026),
        elements: [
          ElementRecord(
            elementId: 'e1',
            duration: const Duration(seconds: 4),
            recordedAt: DateTime(2026),
          ),
        ],
      ),
      CycleRecord(
        number: 2,
        duration: const Duration(seconds: 12),
        recordedAt: DateTime(2026),
        elements: [
          ElementRecord(
            elementId: 'e1',
            duration: const Duration(seconds: 6),
            recordedAt: DateTime(2026),
          ),
        ],
      ),
    ];

    final result = calculator.summarizeElements(cycles, const [element]).single;
    expect(result.count, 2);
    expect(result.average, const Duration(seconds: 5));
    expect(result.minimum, const Duration(seconds: 4));
    expect(result.maximum, const Duration(seconds: 6));
    expect(result.total, const Duration(seconds: 10));
  });
}
