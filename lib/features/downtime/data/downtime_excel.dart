import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/data/styled_excel.dart';
import 'downtime_models.dart';

class DowntimeExcel {
  Future<bool> export(List<DowntimeRecord> records) async {
    final book = Excel.createExcel();
    book.rename('Sheet1', 'Downtime');
    final sheet = book['Downtime'];
    StyledExcel.row(sheet, ['ID', 'Category', 'Cause', 'Start', 'End', 'Duration (min)', 'Productive', 'Note'], header: true);
    for (final r in records) {
      StyledExcel.row(sheet, [r.id, r.category, r.cause, r.start.toIso8601String(), r.end.toIso8601String(), r.duration.inSeconds / 60, r.productive ? 'YES' : 'NO', r.note]);
    }
    StyledExcel.layout(sheet, [24, 20, 34, 24, 24, 18, 14, 34]);
    return StyledExcel.save(book, 'downtime_${DateTime.now().millisecondsSinceEpoch}.xlsx', 'Downtime Excel eksport');
  }

  Future<List<DowntimeRecord>?> importRecords() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (files.isEmpty) return null;
    final bytes = await files.single.readAsBytes();
    if (bytes.isEmpty) return null;
    final book = Excel.decodeBytes(bytes);
    final sheet = book.tables['Downtime'];
    if (sheet == null) return null;
    final result = <DowntimeRecord>[];
    for (final row in sheet.rows.skip(1)) {
      if (row.length < 6) continue;
      final start = DateTime.tryParse(row[3]?.value?.toString() ?? '');
      final end = DateTime.tryParse(row[4]?.value?.toString() ?? '');
      final cause = row[2]?.value?.toString() ?? '';
      if (start == null || end == null || cause.isEmpty) continue;
      result.add(DowntimeRecord(id: row[0]?.value?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(), category: row[1]?.value?.toString() ?? '', cause: cause, start: start, end: end, productive: (row.length > 6 ? row[6]?.value?.toString().toUpperCase() : 'NO') == 'YES', note: row.length > 7 ? row[7]?.value?.toString() ?? '' : ''));
    }
    return result;
  }
}
