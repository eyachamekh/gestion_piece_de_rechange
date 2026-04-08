import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

Future<String> exportToExcel(List<Map<String, dynamic>> data) async {
  var excel = Excel.createExcel();
  Sheet sheet = excel['Sheet1'];

  // Header
  sheet.appendRow(["Part", "Quantity", "Quantity Out", "Date"]);

  // Data
  for (var item in data) {
    sheet.appendRow([
      item["part"],
      item["quantity"],
      item["quantityOut"],
      item["date"],
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