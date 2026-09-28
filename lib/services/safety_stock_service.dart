import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gestion_piece_de_rechange/models/safety_stock_result.dart';

class SafetyStockService {
  // Délais moyens chargés depuis le fichier Excel (référence → jours).
  static final Map<String, double> _delais = {};
  static bool _loaded = false;

  // Charge la table de délais depuis Feuil2.
  static Future<void> loadDelais() async {
    if (_loaded) return;
    try {
      final ByteData data = await rootBundle.load(
        'assets/data/délaidetraiementDA.xlsx',
      );
      final xl.Excel excel = xl.Excel.decodeBytes(data.buffer.asUint8List());

      final delaySheet = excel.tables['Feuil2'];
      if (delaySheet == null) {
        throw StateError('Worksheet Feuil2 not found');
      }

      const headerIndex = 2; // Excel row 3; rows are zero-based.
      final rows = delaySheet.rows;
      if (rows.length <= headerIndex) {
        throw StateError('Feuil2 does not contain header row 3');
      }

      final headerRow = rows[headerIndex];
      var referenceColumn = -1;
      var delayColumn = -1;
      for (var column = 0; column < headerRow.length; column++) {
        final header = _normalizeHeader(_cellText(headerRow[column]?.value));
        if (header == 'etiquettesdelignes') referenceColumn = column;
        if (header == 'moyennededelai') delayColumn = column;
      }
      if (referenceColumn < 0 || delayColumn < 0) {
        throw StateError(
          'Feuil2 headers not found: '
          '${headerRow.map((cell) => _cellText(cell?.value)).toList()}',
        );
      }

      debugPrint(
        '[SafetyStock] Excel sheet="Feuil2", headerRow=3, '
        'referenceColumn=${referenceColumn + 1}, '
        'delayColumn=${delayColumn + 1}',
      );

      for (int i = headerIndex + 1; i < rows.length; i++) {
        final row = rows[i];
        final labelCell = row.length > referenceColumn
            ? row[referenceColumn]?.value
            : null;
        final delaiCell = row.length > delayColumn
            ? row[delayColumn]?.value
            : null;

        if (labelCell == null || delaiCell == null) continue;

        final String label = _referenceText(labelCell).trim();
        final delai = _parseNumber(delaiCell);

        if (label.isNotEmpty && delai != null && delai >= 0) {
          _delais[_normalizeReference(label)] = delai;
        }
      }
      debugPrint(
        '[SafetyStock] Excel loaded: ${_delais.length} delay references '
        'from Feuil2',
      );
      debugPrint(
        '[SafetyStock] Excel samples: '
        '${_delais.entries.take(5).map((entry) => '${entry.key}->${entry.value}').join(', ')}',
      );
      debugPrint(
        '[SafetyStock] Excel lookup: 330106004406 -> '
        '${_findDelay('330106004406')?.value ?? 'none'} days',
      );
    } catch (error, stackTrace) {
      debugPrint('[SafetyStock] Excel load failed: $error\n$stackTrace');
    }
    _loaded = true;
  }

  // Retourne le délai moyen pour une référence donnée.
  // Cherche d'abord une correspondance exacte, puis partielle.
  // Si aucune correspondance, retourne [defaultDelai].
  static double getDelai(String reference, {double defaultDelai = 30.0}) {
    return _findDelay(reference)?.value ?? defaultDelai;
  }

  static String _normalizeReference(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static String _normalizeHeader(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static double? _parseNumber(dynamic value) {
    if (value is num) return value.toDouble();
    final text = _cellText(
      value,
    ).trim().replaceAll('\u00a0', '').replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(text);
  }

  static String _referenceText(dynamic value) {
    if (value is xl.TextCellValue) return value.value.text ?? '';
    if (value is xl.IntCellValue) return value.value.toString();
    if (value is xl.DoubleCellValue) {
      return value.value == value.value.truncateToDouble()
          ? value.value.toInt().toString()
          : value.value.toString();
    }
    return _cellText(value);
  }

  static String _cellText(dynamic value) {
    if (value is xl.TextCellValue) {
      return value.value.text ?? '';
    }
    return value?.toString() ?? '';
  }

  static _DelayMatch? _findDelay(String reference) {
    final key = _normalizeReference(reference);
    if (key.isEmpty) return null;
    final exact = _delais[key];
    if (exact != null) return _DelayMatch(key, exact);
    for (final entry in _delais.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return _DelayMatch(entry.key, entry.value);
      }
    }
    return null;
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
    final cutoff = DateTime.now().subtract(Duration(days: periodDays));
    // Consommation totale par référence
    final Map<String, double> totalConsumed = {};
    for (final a in activities) {
      final activityDate = _parseActivityDate(a);
      if (activityDate != null && activityDate.isBefore(cutoff)) {
        continue;
      }
      final rawReference =
          (a['reference'] ?? a['part_reference'] ?? a['piece_reference'] ?? '')
              .toString();
      final ref = _normalizeReference(rawReference);
      final qty = _parseNumber(a['quantity']);
      if (ref.isEmpty || qty == null || qty <= 0) {
        debugPrint(
          '[SafetyStock] Ignored activity: reference="$rawReference", '
          'quantity="${a['quantity']}"',
        );
        continue;
      }
      totalConsumed[ref] = (totalConsumed[ref] ?? 0) + qty;
    }

    return parts.map((part) {
      final ref = (part['reference'] ?? '').toString().trim();
      final currentQty = part['quantity'] is int
          ? part['quantity'] as int
          : int.tryParse(part['quantity'].toString()) ?? 0;

      final normalizedRef = _normalizeReference(ref);
      final consumed = totalConsumed[normalizedRef] ?? 0;
      final double consommationJour = periodDays > 0
          ? consumed / periodDays
          : 0;
      final delayMatch = _findDelay(ref);
      final double delai = delayMatch?.value ?? 30.0;
      final int safetyStock = (consommationJour * delai).ceil();

      final bool mustOrder = safetyStock > 0
          ? currentQty <= safetyStock
          : currentQty <= 5;

      debugPrint(
        '[SafetyStock] partReference="$ref", '
        'excelReference="${delayMatch?.reference ?? 'none'}", '
        'delaiDA=${delai.toStringAsFixed(2)} days '
        '${delayMatch == null ? '(fallback)' : '(Excel)'}, '
        'totalOutgoing=${consumed.toStringAsFixed(2)}, '
        'consumptionPerDay=${consommationJour.toStringAsFixed(4)}, '
        'safetyStock=$safetyStock',
      );

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

  static DateTime? _parseActivityDate(Map activity) {
    final rawDate = activity['date'] ?? activity['created_at'];
    if (rawDate == null) return null;
    return DateTime.tryParse(rawDate.toString())?.toLocal();
  }

  // Retourne uniquement les pièces qui nécessitent une commande.
  static List<SafetyStockResult> getOrderAlerts({
    required List parts,
    required List activities,
    int periodDays = 90,
  }) => compute(
    parts: parts,
    activities: activities,
    periodDays: periodDays,
  ).where((r) => r.mustOrder).toList();

  static Map<String, double> get delaisMap => Map.unmodifiable(_delais);
}

class _DelayMatch {
  final String reference;
  final double value;

  const _DelayMatch(this.reference, this.value);
}
