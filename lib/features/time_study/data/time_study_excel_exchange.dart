import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../application/time_study_calculator.dart';
import '../domain/time_study_models.dart';
import 'time_study_storage.dart';

class TimeStudyExcelExchange {
  Future<bool> exportSession(
    TimeStudySessionData data,
    List<ElementSummary> summaries,
  ) async {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'Session');
    final session = workbook['Session'];
    _row(session, ['Field', 'Value']);
    _row(session, ['Session', data.sessionName]);
    _row(session, ['Work type', data.workType.name]);
    _row(session, ['Department', data.department]);
    _row(session, ['Section', data.section]);
    _row(session, ['Line', data.line]);
    _row(session, ['Station', data.station]);
    _row(session, ['Worker', data.worker]);

    final elements = workbook['Work Elements'];
    _row(elements, ['ID', 'Sequence', 'Element', 'Type', 'Measurement Mode', 'Requirement', 'Xususiyati', 'Verification', 'Basis', 'Selected Time ms']);
    for (var i = 0; i < data.elements.length; i++) {
      final e = data.elements[i];
      _row(elements, [
        e.id,
        i + 1,
        e.name,
        e.type.name,
        e.measurementMode.name,
        e.requirements.map((v) => v.name).join(', '),
        e.property,
        e.verificationMethods.map((v) => v.name).join(', '),
        e.basis,
        e.selectedTime == null ? '' : e.selectedTime!.inMicroseconds / 1000,
      ]);
    }

    final observations = workbook['Observations'];
    _row(observations, ['Cycle', 'Cycle Duration ms', 'Element ID', 'Duration ms', 'Recorded at', 'Excluded', 'Exclusion reason']);
    for (final cycle in data.cycles) {
      if (cycle.elements.isEmpty) {
        _row(observations, [cycle.number, cycle.duration.inMilliseconds, '', '', cycle.recordedAt.toIso8601String(), cycle.excluded, cycle.exclusionReason]);
      } else {
        for (final record in cycle.elements) {
          _row(observations, [cycle.number, cycle.duration.inMilliseconds, record.elementId, record.duration.inMilliseconds, record.recordedAt.toIso8601String(), record.excluded, record.exclusionReason]);
        }
      }
    }

    final summary = workbook['Summary'];
    _row(summary, ['Element ID', 'Observed', 'Valid', 'Excluded', 'Average ms', 'Median ms', 'Mode ms', 'Min ms', 'Max ms', 'Range ms', 'Std Dev ms']);
    for (final item in summaries) {
      _row(summary, [
        item.elementId,
        item.observedCount,
        item.validCount,
        item.excludedCount,
        _ms(item.average),
        _ms(item.median),
        _ms(item.mode),
        _ms(item.minimum),
        _ms(item.maximum),
        _ms(item.range),
        item.standardDeviationMicros == null ? '' : item.standardDeviationMicros! / 1000,
      ]);
    }

    final bytes = workbook.encode();
    if (bytes == null) return false;
    final output = await FilePicker.saveFile(
      dialogTitle: 'Time Study Excel faylini saqlash',
      fileName: 'time_study_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      bytes: Uint8List.fromList(bytes),
    );
    return output != null;
  }

  Future<TimeStudySessionData?> importSession() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (files.isEmpty) return null;
    final bytes = await files.single.readAsBytes();
    if (bytes.isEmpty) return null;

    final workbook = Excel.decodeBytes(bytes);
    final sessionSheet = workbook.tables['Session'];
    final elementSheet = workbook.tables['Work Elements'];
    if (sessionSheet == null || elementSheet == null) return null;

    final fields = <String, String>{};
    for (final row in sessionSheet.rows.skip(1)) {
      if (row.length < 2) continue;
      final key = row[0]?.value?.toString() ?? '';
      final value = row[1]?.value?.toString() ?? '';
      if (key.isNotEmpty) fields[key] = value;
    }

    final elements = <WorkElement>[];
    for (final row in elementSheet.rows.skip(1)) {
      if (row.length < 3) continue;
      final id = row[0]?.value?.toString() ?? '';
      final name = row[2]?.value?.toString() ?? '';
      if (id.isEmpty || name.isEmpty) continue;
      final type = WorkElementType.values.firstWhere(
        (v) => v.name == (row.length > 3 ? row[3]?.value?.toString() : ''),
        orElse: () => WorkElementType.productive,
      );
      final mode = MeasurementMode.values.firstWhere(
        (v) => v.name == (row.length > 4 ? row[4]?.value?.toString() : ''),
        orElse: () => MeasurementMode.startFinish,
      );
      final requirements = _enumList<WorkRequirement>(row.length > 5 ? row[5]?.value?.toString() ?? '' : '', WorkRequirement.values);
      final verification = _enumList<VerificationMethod>(row.length > 7 ? row[7]?.value?.toString() ?? '' : '', VerificationMethod.values);
      elements.add(WorkElement(
        id: id,
        name: name,
        type: type,
        measurementMode: mode,
        requirements: requirements.where((v) => v != WorkRequirement.none).toList(),
        property: row.length > 6 ? row[6]?.value?.toString() ?? '' : '',
        verificationMethods: verification,
        basis: row.length > 8 ? row[8]?.value?.toString() ?? '' : '',
        selectedTime: row.length > 9 ? _durationFromCell(row[9]?.value?.toString()) : null,
      ));
    }

    final cyclesByNumber = <int, List<ElementRecord>>{};
    final cycleDurations = <int, int>{};
    final observationSheet = workbook.tables['Observations'];
    if (observationSheet != null) {
      for (final row in observationSheet.rows.skip(1)) {
        if (row.length < 4) continue;
        final number = int.tryParse(row[0]?.value?.toString() ?? '');
        final cycleMs = int.tryParse(row[1]?.value?.toString() ?? '');
        final elementId = row[2]?.value?.toString() ?? '';
        final durationMs = int.tryParse(row[3]?.value?.toString() ?? '');
        if (number == null) continue;
        if (cycleMs != null) cycleDurations[number] = cycleMs;
        if (elementId.isNotEmpty && durationMs != null) {
          cyclesByNumber.putIfAbsent(number, () => []).add(ElementRecord(
            elementId: elementId,
            duration: Duration(milliseconds: durationMs),
            recordedAt: DateTime.tryParse(row.length > 4 ? row[4]?.value?.toString() ?? '' : '') ?? DateTime.now(),
            excluded: row.length > 5 && (row[5]?.value?.toString().toLowerCase() == 'true'),
            exclusionReason: row.length > 6 ? row[6]?.value?.toString() ?? '' : '',
          ));
        }
      }
    }
    final cycles = cyclesByNumber.keys.map((number) => CycleRecord(
      number: number,
      duration: Duration(milliseconds: cycleDurations[number] ?? 0),
      recordedAt: DateTime.now(),
      elements: List.unmodifiable(cyclesByNumber[number] ?? const []),
    )).toList()..sort((a, b) => a.number.compareTo(b.number));

    final workType = WorkType.values.firstWhere(
      (v) => v.name == fields['Work type'],
      orElse: () => WorkType.cyclic,
    );
    return TimeStudySessionData(
      sessionName: fields['Session'] ?? '',
      workType: workType,
      department: fields['Department'] ?? '',
      section: fields['Section'] ?? '',
      line: fields['Line'] ?? '',
      station: fields['Station'] ?? '',
      worker: fields['Worker'] ?? '',
      elements: List.unmodifiable(elements),
      cycles: List.unmodifiable(cycles),
    );
  }

  Future<bool> exportTemplate() async {
    final data = const TimeStudySessionData(
      sessionName: 'Namuna Time Study',
      workType: WorkType.cyclic,
      elements: [
        WorkElement(
          id: 'E001',
          name: 'Namuna ish elementi',
          type: WorkElementType.productive,
          property: '4 Nm ± 0.5 Nm',
          requirements: [WorkRequirement.quality],
          verificationMethods: [VerificationMethod.measurement],
          basis: 'JES / Standard',
          measurementMode: MeasurementMode.startFinish,
        ),
      ],
      cycles: [],
    );
    return exportSession(data, const []);
  }

  void _row(Sheet sheet, List<Object?> values) {
    sheet.appendRow(values.map<CellValue?>((v) => TextCellValue(v?.toString() ?? '')).toList());
  }

  String _ms(Duration? d) => d == null ? '' : (d.inMicroseconds / 1000).toStringAsFixed(3);

  Duration? _durationFromCell(String? value) {
    final ms = double.tryParse(value ?? '');
    return ms == null ? null : Duration(microseconds: (ms * 1000).round());
  }

  List<T> _enumList<T>(String value, List<T> values) {
    if (value.trim().isEmpty) return [];
    return value.split(',').map((part) {
      final name = part.trim();
      return values.firstWhere((v) => (v as Enum).name == name, orElse: () => values.first);
    }).toList();
  }
}
