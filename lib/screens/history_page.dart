import 'package:flutter/material.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';
import 'package:gestion_piece_de_rechange/widgets/shared_widgets.dart';
import 'package:gestion_piece_de_rechange/widgets/custom_bottom_navigation_bar.dart';

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final String? token;

  const HistoryPage({required this.history, this.token, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: STBG.surface,
      body: Stack(
        children: [
          Column(
            children: [
          const STBGHeader(
            title: 'Activity History',
            subtitle: 'Parts withdrawal log',
            showBack: true,
          ),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 56,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        const TranslatedText(
                          'No activity recorded yet',
                          style: TextStyle(
                            color: STBG.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: history.length,
                    itemBuilder: (_, i) {
                      final h = history[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0D000000), blurRadius: 8),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    STBG.gold.withOpacity(0.8),
                                    STBG.gold,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h['reference'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: STBG.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    h['takenBy'] ?? '-',
                                    style: const TextStyle(
                                      color: STBG.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    h['date'] ?? '-',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: STBG.danger.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: STBG.danger.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                '-${h['quantity']}',
                                style: const TextStyle(
                                  color: STBG.danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigationBar(
              currentIndex: 2,
              token: token,
            ),
          ),
        ],
      ),
    );
  }
}
