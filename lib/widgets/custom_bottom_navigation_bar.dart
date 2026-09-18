import 'package:flutter/material.dart';
import 'package:gestion_piece_de_rechange/screens/history_page.dart';
import 'package:gestion_piece_de_rechange/screens/list_page.dart';
import 'package:gestion_piece_de_rechange/screens/scan_page.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';
import 'package:gestion_piece_de_rechange/widgets/shared_widgets.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final String? token;

  const CustomBottomNavigationBar({
    required this.currentIndex,
    this.token,
    super.key,
  });

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex || token == null || token!.isEmpty) return;
    final Widget page;
    switch (index) {
      case 0:
        page = ListPage(token: token!);
      case 1:
        page = ScanPage(token: token!);
      case 2:
        page = HistoryPage(history: appHistory, token: token!);
      default:
        return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.inventory_2_outlined, 'Inventaire'),
      (Icons.document_scanner_outlined, 'Scanner'),
      (Icons.history_outlined, 'Historique'),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 280,
            maxWidth: 330,
            minHeight: 60,
            maxHeight: 68,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.97),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: _NavigationItem(
                      icon: items[index].$1,
                      label: items[index].$2,
                      selected: currentIndex == index,
                      onTap: () => _navigate(context, index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE45445);
    final color = selected ? accent : STBG.navy;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 7 : 3,
          vertical: selected ? 1 : 3,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                width: selected ? 40 : 28,
                height: selected ? 40 : 28,
                transform: Matrix4.translationValues(0, selected ? -3 : 0, 0),
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: selected ? 21 : 18,
                  color: selected ? Colors.white : color,
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  color: color,
                  fontSize: selected ? 10 : 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: TranslatedText(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
