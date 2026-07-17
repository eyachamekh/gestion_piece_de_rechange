import 'package:excel/excel.dart' as xl;
import 'package:flutter/services.dart';

/// Résultat du calcul de stock de sécurité pour une pièce.
class SafetyStockResult {
  final String reference;
  final double delaiJours;        // délai moyen de traitement DA (jours)
  final double consommationJour;  // consommation journalière estimée
  final int safetyStock;          // stock de sécurité = ceil(conso × délai)
  final int currentQty;           // quantité actuelle en stock
  final bool mustOrder;           // true si qty actuelle <= stock de sécurité

  const SafetyStockResult({
    required this.reference,
    required this.delaiJours,
    required this.consommationJour,
    required this.safetyStock,
    required this.currentQty,
    required this.mustOrder,
  });
}

class SafetyStockService {
  /// Délais moyens chargés depuis le fichier Excel (référence → jours).
  static final Map<String, double> _delais = {};
  static bool _loaded = false;

  /// Charge le fichier Excel des délais DA depuis les assets.
  /// Structure attendue : colonne A = étiquette de ligne (référence),
  ///                      colonne B = moyenne du délai (en jours).
  static Future<void> loadDelais() async {
    if (_loaded) return;
    try {
      final ByteData data =
          await rootBundle.load('assets/data/délaidetraiementDA.xlsx');
      final xl.Excel excel = xl.Excel.decodeBytes(data.buffer.asUint8List());

      final sheet = excel.sheets.values.first;
      final rows = sheet.rows;

      // Ignorer la première ligne (en-tête)
      for (int i = 1; i < rows.length; i++) {
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
          _delais[label.toLowerCase()] = delai;
        }
      }
    } catch (_) {
      // Fichier absent ou mal formé → délai par défaut utilisé
    }
    _loaded = true;
  }

  /// Retourne le délai moyen pour une référence donnée.
  /// Cherche d'abord une correspondance exacte, puis partielle.
  /// Si aucune correspondance, retourne [defaultDelai].
  static double getDelai(String reference, {double defaultDelai = 30.0}) {
    final key = reference.trim().toLowerCase();
    if (_delais.containsKey(key)) return _delais[key]!;
    for (final entry in _delais.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return defaultDelai;
  }

  /// Calcule le stock de sécurité pour une liste de pièces.
  /// [parts]       : liste de maps avec "reference" et "quantity".
  /// [activities]  : liste des sorties avec "reference" et "quantity".
  /// [periodDays]  : nombre de jours couverts par les activités.
  static List<SafetyStockResult> compute({
    required List parts,
    required List activities,
    int periodDays = 90,
  }) {
    // Consommation totale par référence
    final Map<String, int> totalConsumed = {};
    for (final a in activities) {
      final ref = (a['reference'] ?? '').toString().trim().toLowerCase();
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

      final consumed = totalConsumed[ref.toLowerCase()] ?? 0;
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

  /// Retourne uniquement les pièces qui nécessitent une commande.
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
