import 'package:flutter/material.dart';
import 'package:gestion_piece_de_rechange/models/safety_stock_result.dart';
import 'package:gestion_piece_de_rechange/services/mlkit_translation_service.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';

// Bannière affichée dans ListPage quand des pièces atteignent le stock de sécurité.
class OrderAlertBanner extends StatelessWidget {
  final List<SafetyStockResult> alerts;
  final VoidCallback? onDismiss;

  const OrderAlertBanner({required this.alerts, this.onDismiss, super.key});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<String>(
      valueListenable: langNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder<int>(
          valueListenable: MLKitTranslationService.instance.translationVersion,
          builder: (context, _, __) {
            final labelText = alerts.length > 1 ? t('parts to order') : t('part to order');
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8A400).withValues(alpha: 0.6)),
                boxShadow: const [
                  BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8A400).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.notification_important_rounded,
                              color: Color(0xFFE8A400), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${alerts.length} $labelText',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF7A4F00),
                                ),
                              ),
                              Text(
                                t('Safety stock reached — Place a purchase order'),
                                style: const TextStyle(fontSize: 11, color: Color(0xFFAA7000)),
                              ),
                            ],
                          ),
                        ),
                        if (onDismiss != null)
                          GestureDetector(
                            onTap: onDismiss,
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFFAA7000)),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8A400), thickness: 0.3),
                  // Liste des pièces
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: alerts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0x22E8A400)),
                    itemBuilder: (_, i) {
                      final a = alerts[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: Color(0xFFE8A400)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.reference,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF3E2800),
                                ),
                              ),
                            ),
                            AlertChip(label: '${t('Stock')}: ${a.currentQty}', color: const Color(0xFFE53935)),
                            const SizedBox(width: 6),
                            AlertChip(label: '${t('SS')}: ${a.safetyStock}', color: const Color(0xFF1E4D8C)),
                            const SizedBox(width: 6),
                            AlertChip(
                              label: '${a.delaiJours.toStringAsFixed(0)} ${t('days')}',
                              color: const Color(0xFF1B8A5A),
                              icon: Icons.schedule_rounded,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE0B2),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFAA7000)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t('Safety stock = daily consumption × purchase request processing time'),
                            style: const TextStyle(fontSize: 10, color: Color(0xFFAA7000)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AlertChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const AlertChip({required this.label, required this.color, this.icon, super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 3),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
