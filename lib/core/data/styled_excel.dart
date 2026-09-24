import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class StyledExcel {
  static final _header = CellStyle(
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: Border(borderStyle: BorderStyle.Thin),
    rightBorder: Border(borderStyle: BorderStyle.Thin),
    topBorder: Border(borderStyle: BorderStyle.Thin),
    bottomBorder: Border(borderStyle: BorderStyle.Thin),
  );

  static final _body = CellStyle(
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: Border(borderStyle: BorderStyle.Thin),
    rightBorder: Border(borderStyle: BorderStyle.Thin),
    topBorder: Border(borderStyle: BorderStyle.Thin),
    bottomBorder: Border(borderStyle: BorderStyle.Thin),
  );

  static void row(Sheet sheet, List<Object?> values, {bool header = false}) {
    final rowIndex = sheet.maxRows;
    sheet.appendRow(values.map<CellValue?>((v) => _value(v)).toList());
    for (var i = 0; i < values.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex)).cellStyle = header ? _header : _body;
    }
    sheet.setRowHeight(rowIndex, header ? 32 : 28);
  }

  static CellValue _value(Object? value) {
    if (value == null) return TextCellValue('');
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is bool) return BoolCellValue(value);
    return TextCellValue(value.toString());
  }

  static void layout(Sheet sheet, List<double> widths) {
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
    sheet.setDefaultRowHeight(28);
  }

  static Future<bool> save(Excel workbook, String fileName, String title) async {
    final bytes = workbook.encode();
    if (bytes == null) return false;
    final path = await FilePicker.saveFile(
      dialogTitle: title,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      bytes: Uint8List.fromList(bytes),
    );
    return path != null;
  }
}
