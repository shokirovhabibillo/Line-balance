import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/data/styled_excel.dart';
import 'line_balance_models.dart';

class LineBalanceExcel {
  Future<bool> export(LineBalancePlan plan) async {
    final book = Excel.createExcel();
    book.rename('Sheet1', 'Line Balance');
    final sheet = book['Line Balance'];
    StyledExcel.row(sheet, ['Field', 'Value'], header: true);
    StyledExcel.row(sheet, ['Plan', plan.name]);
    StyledExcel.row(sheet, ['Takt Time (s)', plan.taktSeconds]);
    StyledExcel.row(sheet, ['Demand / day', plan.demandPerDay]);
    StyledExcel.row(sheet, ['Available Time (s)', plan.availableSeconds]);
    StyledExcel.row(sheet, ['Total Workload (s)', plan.totalWorkload]);
    StyledExcel.row(sheet, ['Bottleneck (s)', plan.bottleneck]);
    StyledExcel.row(sheet, ['Balance (%)', plan.balancePercent]);
    StyledExcel.row(sheet, ['Theoretical Stations', plan.theoreticalStations]);

    final stations = book['Stations'];
    StyledExcel.row(stations, ['Sequence', 'Station', 'Operator', 'Workload (s)', 'vs Takt', 'Bottleneck'], header: true);
    for (final s in plan.stations) {
      StyledExcel.row(stations, [s.sequence, s.name, s.operator, s.workloadSeconds, plan.taktSeconds <= 0 ? '' : s.workloadSeconds / plan.taktSeconds * 100, s.workloadSeconds == plan.bottleneck ? 'YES' : '']);
    }
    StyledExcel.layout(sheet, [28, 24]);
    StyledExcel.layout(stations, [12, 30, 24, 18, 16, 16]);
    return StyledExcel.save(book, 'line_balance_${DateTime.now().millisecondsSinceEpoch}.xlsx', 'Line Balance Excel eksport');
  }

  Future<LineBalancePlan?> importPlan() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (files.isEmpty) return null;
    final bytes = await files.single.readAsBytes();
    if (bytes.isEmpty) return null;
    final book = Excel.decodeBytes(bytes);
    final sheet = book.tables['Stations'];
    if (sheet == null) return null;
    final stations = <LineBalanceStation>[];
    for (final row in sheet.rows.skip(1)) {
      if (row.length < 4) continue;
      final name = row[1]?.value?.toString() ?? '';
      final workload = double.tryParse(row[3]?.value?.toString() ?? '');
      if (name.isEmpty || workload == null) continue;
      stations.add(LineBalanceStation(id: DateTime.now().microsecondsSinceEpoch.toString() + stations.length.toString(), sequence: int.tryParse(row[0]?.value?.toString() ?? '') ?? stations.length + 1, name: name, operator: row.length > 2 ? row[2]?.value?.toString() ?? '' : '', workloadSeconds: workload));
    }
    final overview = book.tables['Line Balance'];
    double takt = 0;
    String name = 'Imported Line Balance';
    if (overview != null) {
      for (final row in overview.rows.skip(1)) {
        if (row.length < 2) continue;
        final key = row[0]?.value?.toString();
        final value = row[1]?.value?.toString() ?? '';
        if (key == 'Plan') name = value;
        if (key == 'Takt Time (s)') takt = double.tryParse(value) ?? 0;
      }
    }
    return LineBalancePlan(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, taktSeconds: takt, stations: stations);
  }
}
