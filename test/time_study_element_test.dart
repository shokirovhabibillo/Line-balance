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

  test('work element stores requirements, verification methods and basis', () {
    final element = WorkElement(
      id: 'e1',
      name: 'Detalni o‘rnatish',
      type: WorkElementType.productive,
      requirements: const [WorkRequirement.safety, WorkRequirement.quality],
      verificationMethods: const [
        VerificationMethod.visual,
        VerificationMethod.measurement,
      ],
      basis: 'CVIS 009-2025; Std-275537:2025',
    );

    expect(element.requirements, contains(WorkRequirement.safety));
    expect(element.requirements, contains(WorkRequirement.quality));
    expect(element.verificationMethods, contains(VerificationMethod.visual));
    expect(
      element.verificationMethods,
      contains(VerificationMethod.measurement),
    );
    expect(element.basis, 'CVIS 009-2025; Std-275537:2025');
  });

  test('work element copyWith updates requirement data without changing id', () {
    const original = WorkElement(
      id: 'e1',
      name: 'Old',
      type: WorkElementType.productive,
    );

    final updated = original.copyWith(
      name: 'New',
      requirements: const [WorkRequirement.qcos],
      verificationMethods: const [VerificationMethod.auditory],
      basis: 'QCOS 2344433:2025',
    );

    expect(updated.id, 'e1');
    expect(updated.name, 'New');
    expect(updated.requirements, [WorkRequirement.qcos]);
    expect(updated.verificationMethods, [VerificationMethod.auditory]);
    expect(updated.basis, 'QCOS 2344433:2025');
  });


  test('time study session data round-trips through JSON', () {
  final data = TimeStudySessionData(
    sessionName: 'ST-03 yig‘ish jarayoni',
    workType: WorkType.cyclic,
    elements: const [
      WorkElement(
        id: 'e1',
        name: 'Detalni o‘rnatish',
        type: WorkElementType.productive,
        requirements: [WorkRequirement.safety, WorkRequirement.quality],
        verificationMethods: [VerificationMethod.visual],
        basis: 'CVIS 009-2025',
      ),
    ],
    cycles: [
      CycleRecord(
        number: 1,
        duration: Duration(seconds: 10),
        recordedAt: DateTime(2026, 9, 15, 20),
        elements: [
          ElementRecord(
            elementId: 'e1',
            duration: Duration(seconds: 4),
            recordedAt: DateTime(2026, 9, 15, 20),
          ),
        ],
      ),
    ],
  );

  final restored = TimeStudySessionData.fromJson(data.toJson());

  expect(restored.sessionName, data.sessionName);
  expect(restored.workType, WorkType.cyclic);
  expect(restored.elements.single.name, 'Detalni o‘rnatish');
  expect(restored.elements.single.basis, 'CVIS 009-2025');
  expect(restored.cycles.single.duration, const Duration(seconds: 10));
  expect(restored.cycles.single.elements.single.duration, const Duration(seconds: 4));
});
}
