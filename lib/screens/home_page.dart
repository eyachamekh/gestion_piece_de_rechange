import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gestion_piece_de_rechange/screens/history_page.dart';
import 'package:gestion_piece_de_rechange/screens/list_page.dart';
import 'package:gestion_piece_de_rechange/screens/login_page.dart';
import 'package:gestion_piece_de_rechange/screens/scan_page.dart';
import 'package:gestion_piece_de_rechange/services/api_service.dart';
import 'package:gestion_piece_de_rechange/services/safety_stock_service.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';
import 'package:gestion_piece_de_rechange/widgets/shared_widgets.dart';
import 'package:gestion_piece_de_rechange/config/api_config.dart';

class HomePage extends StatefulWidget {
  final String role;
  final String token;

  const HomePage({required this.role, required this.token, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalParts = 0;
  int lowStockCount = 0;
  int scannedCount = 0;
  int orderAlertCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final parts = await fetchParts(widget.token);
      List activities = [];
      try {
        final res = await http.get(
          Uri.parse(ApiConfig.url('/api/activities')),
          headers: authHeaders(widget.token),
        );
        if (res.statusCode == 200) activities = jsonDecode(res.body);
      } catch (_) {}

      final alerts = SafetyStockService.getOrderAlerts(parts: parts, activities: activities);

      setState(() {
        totalParts = parts.length;
        lowStockCount = parts.where((p) => (p['quantity'] ?? 0) <= 5).length;
        scannedCount = parts.where((p) => p['scanned'] == true).length;
        orderAlertCount = alerts.length;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: STBG.surface,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: STBG.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Color(0x35000000), blurRadius: 20, offset: Offset(0, 6))],
            ),
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: stbgLogo(height: 28),
                    ),
                    Row(
                      children: [
                        HeaderIconBtn(icon: Icons.language_rounded, onTap: toggleLanguage),
                        const SizedBox(width: 8),
                        HeaderIconBtn(
                          icon: Icons.logout_rounded,
                          onTap: () => Navigator.pushAndRemoveUntil(context, createRoute(const LoginPage()), (_) => false),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TranslatedText(
                  'Welcome back',
                  style: TextStyle(color: Colors.white.withAlpha((0.6 * 255).round()), fontSize: 13),
                ),
                const SizedBox(height: 4),
                const TranslatedText(
                  'Spare Parts Manager',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
                const SizedBox(height: 20),
                if (loading)
                  const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else
                  Row(children: [
                    StatCard(label: 'Total Parts', value: '$totalParts', icon: Icons.inventory_2_outlined),
                    const SizedBox(width: 10),
                    StatCard(label: 'Scanned', value: '$scannedCount', icon: Icons.qr_code_scanner_rounded),
                    const SizedBox(width: 10),
                    StatCard(
                      label: 'À commander',
                      value: '$orderAlertCount',
                      icon: Icons.shopping_cart_outlined,
                      highlight: orderAlertCount > 0,
                    ),
                  ]),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TranslatedText(
                    'Quick Actions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: STBG.textPrimary, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 14),
                  ActionTile(
                    icon: Icons.document_scanner_rounded,
                    title: 'Start Scanning',
                    subtitle: 'Identify a part using your camera',
                    accent: STBG.steel,
                    onTap: () => Navigator.push(context, createRoute(ScanPage(token: widget.token))),
                  ),
                  if (widget.role == 'admin') ...[
                    const SizedBox(height: 12),
                    ActionTile(
                      icon: Icons.list_alt_rounded,
                      title: 'Spare Parts Inventory',
                      subtitle: 'Browse, search, add and manage parts',
                      accent: STBG.success,
                      onTap: () => Navigator.push(context, createRoute(ListPage(token: widget.token))),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ActionTile(
                    icon: Icons.history_rounded,
                    title: 'Activity History',
                    subtitle: 'View recent part withdrawals',
                    accent: STBG.gold,
                    onTap: () => Navigator.push(context, createRoute(HistoryPage(history: appHistory))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
