import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

Future<String> exportToExcel(List<Map<String, dynamic>> data) async {
  var excel = Excel.createExcel();
  Sheet sheet = excel['Sheet1'];

  // Header
  sheet.appendRow([
    TextCellValue("Part"),
    TextCellValue("Quantity"),
    TextCellValue("Quantity Out"),
    TextCellValue("Date"),
  ]);

  // Data
  for (var item in data) {
    sheet.appendRow([
      TextCellValue(item["part"]?.toString() ?? ""),
      TextCellValue(item["quantity"]?.toString() ?? ""),
      TextCellValue(item["quantityOut"]?.toString() ?? ""),
      TextCellValue(item["date"]?.toString() ?? ""),
    ]);
  }

  // Save file
  final directory = await getApplicationDocumentsDirectory();
  String filePath = "${directory.path}/spare_parts.xlsx";

  File(filePath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(excel.encode()!);

  return filePath;
}