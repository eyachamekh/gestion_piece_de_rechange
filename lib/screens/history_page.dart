import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gestion_piece_de_rechange/config/api_config.dart';
import 'package:gestion_piece_de_rechange/services/auth_headers.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';
import 'package:gestion_piece_de_rechange/widgets/shared_widgets.dart';
import 'package:gestion_piece_de_rechange/widgets/custom_bottom_navigation_bar.dart';

class HistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> history;
  final String? token;
  final String role;

  const HistoryPage({
    required this.history,
    this.token,
    this.role = 'admin',
    super.key,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _searchController = TextEditingController();
  late List<Map<String, dynamic>> _history;
  String _type = 'all';
  int _page = 0;
  static const int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _history = List<Map<String, dynamic>>.from(widget.history);
    _loadServerHistory();
  }

  Future<void> _loadServerHistory() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.url('/api/activities')),
        headers: makeAuthHeaders(token),
      );
      if (response.statusCode != 200) {
        debugPrint(
          'Unable to load server history: HTTP ${response.statusCode}',
        );
        return;
      }

      final activities = jsonDecode(response.body);
      if (activities is! List || !mounted) return;

      final merged = <Map<String, dynamic>>[
        for (final activity in activities)
          if (activity is Map)
            {
              'reference': activity['reference'],
              'takenBy': activity['taken_by'],
              'quantity': activity['quantity'],
              'date': activity['date'],
            },
        ..._history,
      ];
      final seen = <String>{};
      final unique = merged.where((item) {
        final key =
            '${item['reference']}|${item['takenBy']}|'
            '${item['quantity']}|${item['date']}';
        return seen.add(key);
      }).toList();

      setState(() {
        _history = unique;
        _page = 0;
      });
    } catch (error) {
      debugPrint('Unable to load server history: $error');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _visibleHistory {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _history.where((h) {
      final action = h['action']?.toString();
      final matchesType =
          _type == 'all' ||
          (_type == 'admin' && (action == 'added' || action == 'reduced')) ||
          (_type == 'taken' && action != 'added' && action != 'reduced');
      final haystack = [
        h['reference'],
        h['name'],
        h['takenBy'],
        h['date'],
      ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
      return matchesType && (query.isEmpty || haystack.contains(query));
    }).toList();
    filtered.sort(
      (a, b) =>
          (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? ''),
    );
    return filtered;
  }

  void _showTypeMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: TranslatedText(
                'Filter history by type',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            RadioListTile<String>(
              value: 'all',
              groupValue: _type,
              title: const TranslatedText('All activity'),
              onChanged: (value) {
                setState(() {
                  _type = value!;
                  _page = 0;
                });
                Navigator.pop(sheetContext);
              },
            ),
            RadioListTile<String>(
              value: 'admin',
              groupValue: _type,
              title: const TranslatedText('Mouvement de stock'),
              onChanged: (value) {
                setState(() {
                  _type = value!;
                  _page = 0;
                });
                Navigator.pop(sheetContext);
              },
            ),
            RadioListTile<String>(
              value: 'taken',
              groupValue: _type,
              title: const TranslatedText('Historique de sortie'),
              onChanged: (value) {
                setState(() {
                  _type = value!;
                  _page = 0;
                });
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleHistory = _visibleHistory;
    final pageCount = visibleHistory.isEmpty
        ? 1
        : (visibleHistory.length / _pageSize).ceil();
    if (_page >= pageCount) _page = pageCount - 1;
    final start = _page * _pageSize;
    final pageItems = visibleHistory.sublist(
      start,
      (start + _pageSize).clamp(start, visibleHistory.length),
    );
    return Scaffold(
      backgroundColor: STBG.surface,
      body: Stack(
        children: [
          Column(
            children: [
              STBGHeader(
                title: 'Activity History',
                subtitle: 'Parts withdrawal log',
                showBack: true,
                bottom: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: t(
                            'Search reference, name, person, or date',
                          ),
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        IconButton(
                          tooltip: t('Filter by type'),
                          onPressed: _showTypeMenu,
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.14),
                          ),
                        ),
                        if (_type != 'all')
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: STBG.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleHistory.isEmpty
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
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                12,
                              ),
                              itemCount: pageItems.length,
                              itemBuilder: (_, i) {
                                final h = pageItems[i];
                                final action = h['action']?.toString();
                                final isAdded = action == 'added';
                                final isReduced = action == 'reduced';
                                final isAdjustment = isAdded || isReduced;
                                final quantityColor = isAdded
                                    ? STBG.success
                                    : STBG.danger;
                                final activityLabel = isAdded
                                    ? 'Mouvement de stock - ajout'
                                    : isReduced
                                    ? 'Mouvement de stock - réduction'
                                    : h['takenBy'] ?? '-';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0D000000),
                                        blurRadius: 8,
                                      ),
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          isAdded
                                              ? Icons.add_circle_outline
                                              : isReduced
                                              ? Icons.remove_circle_outline
                                              : Icons.person_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              isAdjustment
                                                  ? '${t(activityLabel)}: ${h['previousQuantity'] ?? '-'} → ${h['newQuantity'] ?? '-'}'
                                                  : activityLabel,
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
                                          color: quantityColor.withOpacity(
                                            0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: quantityColor.withOpacity(
                                              0.2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          isAdjustment
                                              ? '${isAdded ? '+' : '-'}${h['quantity']}'
                                              : '-${h['quantity']}',
                                          style: TextStyle(
                                            color: quantityColor,
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  tooltip: t('Previous page'),
                                  onPressed: _page == 0
                                      ? null
                                      : () => setState(() => _page--),
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('${_page + 1} / $pageCount'),
                                IconButton(
                                  tooltip: t('Next page'),
                                  onPressed: _page >= pageCount - 1
                                      ? null
                                      : () => setState(() => _page++),
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ),
                        ],
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
              token: widget.token,
              role: widget.role,
            ),
          ),
        ],
      ),
    );
  }
}
