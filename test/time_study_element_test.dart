import 'package:flutter_test/flutter_test.dart';
import 'package:line_balance_platform/features/time_study/domain/time_study_models.dart';

void main() {
  test('cycle keeps independent cycle and element observations', () {
    final cycle = CycleRecord(
      number: 1,
      duration: const Duration(seconds: 20),
      recordedAt: DateTime(2026),
      elements: [
        ElementRecord(
          elementId: 'e1',
          duration: const Duration(seconds: 8),
          recordedAt: DateTime(2026),
        ),
        ElementRecord(
          elementId: 'e2',
          duration: const Duration(seconds: 12),
          recordedAt: DateTime(2026),
        ),
      ],
    );

    expect(cycle.duration, const Duration(seconds: 20));
    expect(cycle.elements.length, 2);
    expect(cycle.elements[0].duration, const Duration(seconds: 8));
    expect(cycle.elements[1].duration, const Duration(seconds: 12));
  });
}
