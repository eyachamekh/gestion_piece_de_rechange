import 'package:excel/excel.dart' as xl;
import 'package:flutter/services.dart';
import 'package:gestion_piece_de_rechange/models/safety_stock_result.dart';

class SafetyStockService {
  // Délais moyens chargés depuis le fichier Excel (référence → jours).
  static final Map<String, double> _delais = {};
  static bool _loaded = false;

  // Charge le fichier Excel des délais DA depuis les assets.
  // Structure attendue : colonne A = étiquette de ligne (référence),
  //                      colonne B = moyenne du délai (en jours).
  static Future<void> loadDelais() async {
    if (_loaded) return;
    try {
      final ByteData data =
          await rootBundle.load('assets/data/délaidetraiementDA.xlsx');
      final xl.Excel excel = xl.Excel.decodeBytes(data.buffer.asUint8List());

      xl.Sheet? delaySheet;
      int headerIndex = -1;
      for (final sheet in excel.sheets.values) {
        final rows = sheet.rows;
        for (int i = 0; i < rows.length; i++) {
          final row = rows[i];
          final first =
              row.isNotEmpty
                  ? row[0]?.value.toString().toLowerCase() ?? ''
                  : '';
          final second =
              row.length > 1
                  ? row[1]?.value.toString().toLowerCase() ?? ''
                  : '';
          if ((first.contains('étiquette') || first.contains('etiquette')) &&
              (second.contains('moyenne') || second.contains('délai') ||
                  second.contains('delai'))) {
            delaySheet = sheet;
            headerIndex = i;
            break;
          }
        }
        if (delaySheet != null) break;
      }

      if (delaySheet == null) {
        throw StateError('No reference/delay worksheet found');
      }

      final rows = delaySheet.rows;

      for (int i = headerIndex + 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        final labelCell = row.isNotEmpty ? row[0]?.value : null;
        final delaiCell = row.length > 1 ? row[1]?.value : null;

        if (labelCell == null || delaiCell == null) continue;

        final String label = labelCell.toString().trim();
        double? delai;

        if (delaiCell is xl.DoubleCellValue) {
          delai = delaiCell.value;
        } else if (delaiCell is xl.IntCellValue) {
          delai = delaiCell.value.toDouble();
        } else {
          delai = double.tryParse(delaiCell.toString().replaceAll(',', '.'));
        }

        if (label.isNotEmpty && delai != null && delai > 0) {
          _delais[_normalizeReference(label)] = delai;
        }
      }
    } catch (_) {
      // Fichier absent ou mal formé → délai par défaut utilisé
    }
    _loaded = true;
  }

  // Retourne le délai moyen pour une référence donnée.
  // Cherche d'abord une correspondance exacte, puis partielle.
  // Si aucune correspondance, retourne [defaultDelai].
  static double getDelai(String reference, {double defaultDelai = 30.0}) {
    final key = _normalizeReference(reference);
    if (_delais.containsKey(key)) return _delais[key]!;
    for (final entry in _delais.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return defaultDelai;
  }

  static String _normalizeReference(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // Calcule le stock de sécurité pour une liste de pièces.
  // [parts]       : liste de maps avec "reference" et "quantity".
  // [activities]  : liste des sorties avec "reference" et "quantity".
  // [periodDays]  : nombre de jours couverts par les activités.
  static List<SafetyStockResult> compute({
    required List parts,
    required List activities,
    int periodDays = 90,
  }) {
    // Consommation totale par référence
    final Map<String, int> totalConsumed = {};
    for (final a in activities) {
      final ref = _normalizeReference((a['reference'] ?? '').toString());
      final qty = a['quantity'] is int
          ? a['quantity'] as int
          : int.tryParse(a['quantity'].toString()) ?? 0;
      totalConsumed[ref] = (totalConsumed[ref] ?? 0) + qty;
    }

    return parts.map((part) {
      final ref = (part['reference'] ?? '').toString().trim();
      final currentQty = part['quantity'] is int
          ? part['quantity'] as int
          : int.tryParse(part['quantity'].toString()) ?? 0;

      final consumed = totalConsumed[_normalizeReference(ref)] ?? 0;
      final double consommationJour =
          periodDays > 0 ? consumed / periodDays : 0;
      final double delai = getDelai(ref);
      final int safetyStock = (consommationJour * delai).ceil();

      // Si pas d'historique de consommation, seuil fixe ≤ 5
      final bool mustOrder =
          safetyStock > 0 ? currentQty <= safetyStock : currentQty <= 5;

      return SafetyStockResult(
        reference: ref,
        delaiJours: delai,
        consommationJour: consommationJour,
        safetyStock: safetyStock,
        currentQty: currentQty,
        mustOrder: mustOrder,
      );
    }).toList();
  }

  // Retourne uniquement les pièces qui nécessitent une commande.
  static List<SafetyStockResult> getOrderAlerts({
    required List parts,
    required List activities,
    int periodDays = 90,
  }) =>
      compute(parts: parts, activities: activities, periodDays: periodDays)
          .where((r) => r.mustOrder)
          .toList();

  static Map<String, double> get delaisMap => Map.unmodifiable(_delais);
}
