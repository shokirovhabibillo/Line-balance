import 'package:flutter_test/flutter_test.dart';
import 'package:line_balance_platform/features/time_study/data/time_study_storage.dart';
import 'package:line_balance_platform/features/time_study/domain/time_study_models.dart';

void main() {
  test('cycle keeps independent cycle and element observations', () {
    final now = DateTime(2026, 1, 1);
    final cycle = CycleRecord(number: 1, duration: const Duration(seconds: 10), recordedAt: now, elements: [ElementRecord(elementId: 'e1', duration: const Duration(seconds: 4), recordedAt: now)]);
    expect(cycle.duration, const Duration(seconds: 10));
    expect(cycle.elements.single.duration, const Duration(seconds: 4));
  });

  test('work element stores requirements, property, verification and basis', () {
    const element = WorkElement(
      id: 'e1', name: 'Bolt', type: WorkElementType.productive,
      requirements: [WorkRequirement.quality], property: '4 Nm ± 0.5 Nm',
      verificationMethods: [VerificationMethod.measurement], basis: 'JES',
      measurementMode: MeasurementMode.cycleLinkedFinishOnly,
    );
    expect(element.requirements, contains(WorkRequirement.quality));
    expect(element.property, '4 Nm ± 0.5 Nm');
    expect(element.measurementMode, MeasurementMode.cycleLinkedFinishOnly);
  });

  test('work element copyWith updates requirement data without changing id', () {
    const element = WorkElement(id: 'e1', name: 'Old', type: WorkElementType.productive);
    final updated = element.copyWith(name: 'New', property: 'A');
    expect(updated.id, 'e1');
    expect(updated.name, 'New');
    expect(updated.property, 'A');
  });

  test('time study session data round-trips through JSON', () {
    const data = TimeStudySessionData(
      sessionName: 'Test', workType: WorkType.cyclic,
      department: 'Production', section: 'Pressing', line: 'Tandem', station: 'St01RH', worker: 'Operator',
      elements: [WorkElement(id: 'e1', name: 'Bolt', type: WorkElementType.productive, property: '4 Nm', measurementMode: MeasurementMode.cycleLinkedFinishOnly)],
      cycles: [],
    );
    final restored = TimeStudySessionData.fromJson(data.toJson());
    expect(restored.sessionName, 'Test');
    expect(restored.station, 'St01RH');
    expect(restored.elements.single.property, '4 Nm');
    expect(restored.elements.single.measurementMode, MeasurementMode.cycleLinkedFinishOnly);
  });
}
