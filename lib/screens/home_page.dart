import 'dart:convert';
import 'dart:math';

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

      final alerts = SafetyStockService.getOrderAlerts(
        parts: parts,
        activities: activities,
      );

      setState(() {
        totalParts = parts.length;
        lowStockCount = parts.where((p) => (p['quantity'] ?? 0) <= 5).length;
        orderAlertCount = alerts.length;
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final statsStacked = screenWidth < 760;

    return Scaffold(
      backgroundColor: const Color(0xFFB9BDC0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxContentWidth = 1220.0;
          final cardsColumns = constraints.maxWidth > 1040
              ? 3
              : constraints.maxWidth > 700
              ? 2
              : 1;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    22,
                    screenWidth < 600 ? 14 : 26,
                    22,
                    14,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF071A30), Color(0xFF0D2946)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2D3438),
                                    Color(0xFF13191D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFC5B9A8),
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: stbgLogo(height: 40),
                              ),
                            ),
                            Row(
                              children: [
                                HeaderIconBtn(
                                  icon: Icons.language_rounded,
                                  onTap: toggleLanguage,
                                  label: ValueListenableBuilder<String>(
                                    valueListenable: langNotifier,
                                    builder: (_, lang, __) => Text(
                                      lang.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                HeaderIconBtn(
                                  icon: Icons.logout_rounded,
                                  onTap: () => Navigator.pushAndRemoveUntil(
                                    context,
                                    createRoute(const LoginPage()),
                                    (_) => false,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TranslatedText(
                          'Welcome back',
                          style: const TextStyle(
                            color: Color(0xFFD8B394),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TranslatedText(
                          'Spare Parts Manager',
                          style: const TextStyle(
                            color: Color(0xFFD8B394),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.05,
                          ),
                        ),
                        Visibility(
                          visible: widget.role == 'admin',
                          child: Column(
                            children: [
                              const SizedBox(height: 14),
                              if (loading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFD8B394),
                                      strokeWidth: 2.2,
                                    ),
                                  ),
                                )
                              else
                                Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 700,
                                    ),
                                    child: statsStacked
                                        ? Column(
                                            children: [
                                              GestureDetector(
                                                onTap: () => Navigator.push(
                                                  context,
                                                  createRoute(
                                                    ListPage(
                                                      token: widget.token,
                                                    ),
                                                  ),
                                                ),
                                                child: MetricPanel(
                                                  title: 'Total Parts',
                                                  value: '$totalParts',
                                                  accent: const Color(
                                                    0xFF78BCEB,
                                                  ),
                                                  icon:
                                                      Icons.inventory_2_rounded,
                                                ),
                                              ),
                                              const SizedBox(height: 14),
                                              GestureDetector(
                                                onTap: () => Navigator.push(
                                                  context,
                                                  createRoute(
                                                    ListPage(
                                                      token: widget.token,
                                                    ),
                                                  ),
                                                ),
                                                child: MetricPanel(
                                                  title: 'To Order',
                                                  value: '$orderAlertCount',
                                                  accent: const Color(
                                                    0xFFE8A33D,
                                                  ),
                                                  icon: Icons
                                                      .shopping_cart_rounded,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => Navigator.push(
                                                    context,
                                                    createRoute(
                                                      ListPage(
                                                        token: widget.token,
                                                      ),
                                                    ),
                                                  ),
                                                  child: MetricPanel(
                                                    title: 'Total Parts',
                                                    value: '$totalParts',
                                                    accent: const Color(
                                                      0xFF78BCEB,
                                                    ),
                                                    icon: Icons
                                                        .inventory_2_rounded,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => Navigator.push(
                                                    context,
                                                    createRoute(
                                                      ListPage(
                                                        token: widget.token,
                                                      ),
                                                    ),
                                                  ),
                                                  child: MetricPanel(
                                                    title: 'To Order',
                                                    value: '$orderAlertCount',
                                                    accent: const Color(
                                                      0xFFE8A33D,
                                                    ),
                                                    icon: Icons
                                                        .shopping_cart_rounded,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB9BDC0), Color(0xFFD7D8D6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TranslatedText(
                              'Quick Actions',
                              style: const TextStyle(
                                color: Color(0xFF111820),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ValueListenableBuilder<String>(
                              valueListenable: langNotifier,
                              builder: (_, lang, __) => GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: cardsColumns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.3,
                                children: [
                                  QuickActionCard(
                                    title: 'Start Scanning',
                                    accent: const Color(0xFFB9855D),
                                    onTap: () => Navigator.push(
                                      context,
                                      createRoute(
                                        ScanPage(
                                          token: widget.token,
                                          role: widget.role,
                                        ),
                                      ),
                                    ),
                                    child: _ScanCardBody(),
                                  ),
                                  QuickActionCard(
                                    title: 'Parts Inventory',
                                    accent: const Color(0xFFB9855D),
                                    onTap: () => Navigator.push(
                                      context,
                                      createRoute(
                                        ListPage(
                                          token: widget.token,
                                          role: widget.role,
                                        ),
                                      ),
                                    ),
                                    child: _InventoryCardBody(),
                                  ),
                                  if (widget.role == 'admin')
                                    QuickActionCard(
                                      title: 'Activity History',
                                      accent: const Color(0xFFB9855D),
                                      onTap: () => Navigator.push(
                                        context,
                                        createRoute(
                                          HistoryPage(
                                            history: appHistory,
                                            token: widget.token,
                                            role: widget.role,
                                          ),
                                        ),
                                      ),
                                      child: _ActivityCardBody(),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MetricPanel extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  const MetricPanel({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B3136), Color(0xFF171C20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF71787D), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 1.2),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TranslatedText(
                title,
                style: const TextStyle(
                  color: Color(0xFFE5E9EC),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final String title;
  final Color accent;
  final Widget child;
  final VoidCallback onTap;

  const QuickActionCard({
    required this.title,
    required this.accent,
    required this.child,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFFF3F1EC), Color(0xFFE8E4E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF7E8487), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2A000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TranslatedText(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF111820),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.15,
                            ),
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: accent,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanCardBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/box.png',
        width: 95,
        height: 95,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _InventoryCardBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/spare-parts.png',
        width: 95,
        height: 95,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ActivityCardBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: 150,
              height: 120,
              child: CustomPaint(painter: ClockPainter()),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 34,
          width: double.infinity,
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              const Expanded(
                child: SizedBox(
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFF243A4F)),
                  ),
                ),
              ),
              ...List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == 2
                          ? const Color(0xFFB9855D)
                          : const Color(0xFFB9BDC0),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 10),
              const TranslatedText(
                'Activity',
                style: TextStyle(
                  color: Color(0xFF6A7177),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = Paint()
      ..color = const Color(0xFFEBF2F8)
      ..style = PaintingStyle.fill;
    final inner = Paint()
      ..color = const Color(0xFFCBD6DE)
      ..style = PaintingStyle.fill;
    final rim = Paint()
      ..color = const Color(0xFF1F3043)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 42, outer);
    canvas.drawCircle(center, 32, inner);
    canvas.drawCircle(center, 42, rim);

    final hand = Paint()
      ..color = const Color(0xFFB9855D)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final shortHand = Paint()
      ..color = const Color(0xFF1F3043)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, Offset(center.dx + 14, center.dy - 18), hand);
    canvas.drawLine(center, Offset(center.dx - 18, center.dy + 14), shortHand);

    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * (3.14159 * 2) - 1.57;
      final start = Offset(
        center.dx + cos(angle) * 30,
        center.dy + sin(angle) * 30,
      );
      final end = Offset(
        center.dx + cos(angle) * 38,
        center.dy + sin(angle) * 38,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFF7B8792)
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
