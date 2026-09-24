import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/data/styled_excel.dart';
import 'vsm_models.dart';

class VsmExcel {
  Future<bool> export(VsmMap map) async {
    final book = Excel.createExcel();
    book.rename('Sheet1', 'VSM');
    final sheet = book['VSM'];
    StyledExcel.row(sheet, ['Field', 'Value'], header: true);
    StyledExcel.row(sheet, ['Map', map.name]);
    StyledExcel.row(sheet, ['State', map.state]);
    StyledExcel.row(sheet, ['Customer Demand / day', map.customerDemandPerDay]);
    StyledExcel.row(sheet, ['Total CT (s)', map.totalCycleTime]);
    StyledExcel.row(sheet, ['Total Lead Time (s)', map.totalLeadTime]);
    StyledExcel.row(sheet, ['Value Add Time (s)', map.valueAddTime]);
    StyledExcel.row(sheet, ['VA / Lead Time (%)', map.vaRatio]);

    final process = book['Processes'];
    StyledExcel.row(process, ['Sequence', 'Process', 'CT (s)', 'C/O (s)', 'Uptime (%)', 'WIP', 'Lead Time (s)', 'VA'], header: true);
    for (final p in map.processes) {
      StyledExcel.row(process, [p.sequence, p.name, p.cycleTimeSeconds, p.changeoverSeconds, p.uptimePercent, p.wip, p.leadTimeSeconds, p.valueAdd ? 'YES' : 'NO']);
    }
    StyledExcel.layout(sheet, [30, 24]);
    StyledExcel.layout(process, [12, 30, 16, 16, 16, 14, 18, 12]);
    return StyledExcel.save(book, 'vsm_${DateTime.now().millisecondsSinceEpoch}.xlsx', 'VSM Excel eksport');
  }

  Future<VsmMap?> importMap() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (files.isEmpty) return null;
    final bytes = await files.single.readAsBytes();
    if (bytes.isEmpty) return null;
    final book = Excel.decodeBytes(bytes);
    final sheet = book.tables['Processes'];
    if (sheet == null) return null;
    final rows = <VsmProcess>[];
    for (final row in sheet.rows.skip(1)) {
      if (row.length < 3) continue;
      final name = row[1]?.value?.toString() ?? '';
      final ct = double.tryParse(row[2]?.value?.toString() ?? '');
      if (name.isEmpty || ct == null) continue;
      rows.add(VsmProcess(id: DateTime.now().microsecondsSinceEpoch.toString() + rows.length.toString(), sequence: int.tryParse(row[0]?.value?.toString() ?? '') ?? rows.length + 1, name: name, cycleTimeSeconds: ct, changeoverSeconds: double.tryParse(row.length > 3 ? row[3]?.value?.toString() ?? '' : '') ?? 0, uptimePercent: double.tryParse(row.length > 4 ? row[4]?.value?.toString() ?? '' : '') ?? 100, wip: double.tryParse(row.length > 5 ? row[5]?.value?.toString() ?? '' : '') ?? 0, leadTimeSeconds: double.tryParse(row.length > 6 ? row[6]?.value?.toString() ?? '' : '') ?? 0, valueAdd: (row.length > 7 ? row[7]?.value?.toString().toUpperCase() : 'YES') == 'YES'));
    }
    return VsmMap(id: DateTime.now().microsecondsSinceEpoch.toString(), name: 'Imported VSM', processes: rows);
  }
}
