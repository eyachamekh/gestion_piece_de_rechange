/// Model representing the safety stock calculation results for a spare part.
class SafetyStockResult {
  final String reference;
  final double delaiJours;
  final double consommationJour;
  final int safetyStock;
  final int currentQty;
  final bool mustOrder;

  const SafetyStockResult({
    required this.reference,
    required this.delaiJours,
    required this.consommationJour,
    required this.safetyStock,
    required this.currentQty,
    required this.mustOrder,
  });
}
