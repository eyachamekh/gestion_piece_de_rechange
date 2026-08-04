import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gestion_piece_de_rechange/screens/result_page.dart';
import 'package:gestion_piece_de_rechange/screens/list_page.dart';
import 'package:gestion_piece_de_rechange/services/api_service.dart';
import 'package:gestion_piece_de_rechange/services/image_classifier_service.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';
import 'package:gestion_piece_de_rechange/widgets/shared_widgets.dart';
import 'package:gestion_piece_de_rechange/config/api_config.dart';

class LoadingPage extends StatefulWidget {
  final File? image;
  final String token;

  const LoadingPage({this.image, required this.token, super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  String? _error;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.05).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _identifyPart();
  }

  Future<void> _identifyPart() async {
    if (widget.image == null) {
      setState(() {
        _finished = true;
        _error = 'No image selected';
      });
      return;
    }
    try {
      final scannedEmbedding = await imageClassifierService.getEmbedding(widget.image!).timeout(const Duration(seconds: 45));

      Map<String, dynamic> data = {
        'piece': 'Unknown Part',
        'reference': 'Unknown',
        'location': '—',
        'quantity': 0,
        'confidence': 0.0,
      };

      try {
        final parts = await fetchParts(widget.token).timeout(const Duration(seconds: 8));

        // Collect candidate matches (score per part is the best among its embeddings)
        final List<Map<String, dynamic>> candidates = [];
        for (final p in parts) {
          double maxPartScore = -1.0;
          for (int i = 1; i <= 3; i++) {
            final embStr = p['embedding$i'];
            if (embStr != null && embStr.toString().isNotEmpty) {
              try {
                final List<dynamic> rawList = jsonDecode(embStr.toString());
                final List<double> emb = rawList.map((e) => (e as num).toDouble()).toList();
                final score = ImageClassifierService.cosineSimilarity(scannedEmbedding, emb);
                if (score > maxPartScore) {
                  maxPartScore = score;
                }
              } catch (e) {
                debugPrint('Error parsing embedding$i: $e');
              }
            }
          }
          if (maxPartScore > -0.5) {
            candidates.add({'part': Map<String, dynamic>.from(p), 'score': maxPartScore});
          }
        }

        // Sort candidates by descending score
        candidates.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

        // Thresholds
        const double acceptThreshold = 0.65; // high confidence -> auto select
        const double candidateThreshold = 0.45; // include as possible matches

        final filtered = candidates.where((c) => (c['score'] as double) >= candidateThreshold).toList();

        if (filtered.isEmpty) {
          // No candidates -> show 'doesn't exist' + list of parts for selection
          if (!mounted) return;
          _finished = true;
          final chosen = await _showNoMatchList(parts);
          if (!chosen) {
            if (!mounted) return;
            Navigator.pop(context); // go back to choose/take picture
          }
          return;
        } else if (filtered.length == 1) {
          final best = filtered.first;
          final p = best['part'] as Map<String, dynamic>;
          final sc = best['score'] as double;
          data = {
            'piece': p['reference'],
            'reference': p['reference'],
            'location': p['location'] ?? '—',
            'quantity': p['quantity'] ?? 0,
            'id': p['id'],
            'image1': p['image1'],
            'image2': p['image2'],
            'image3': p['image3'],
            'confidence': sc,
          };
          // if low confidence, append note
          if (sc < acceptThreshold) data['piece'] = '${data['piece']} (Low confidence)';
        } else {
          // Multiple similar candidates -> show selection sheet to user
          if (!mounted) return;
          _finished = true;
          final selected = await _showMatchesSelection(filtered);
          if (!selected) {
            if (!mounted) return;
            Navigator.pop(context);
          }
          return; // don't auto-navigate here; selection handler will navigate or return to previous page
        }
      } catch (e) {
        debugPrint('Database fetch/match error: $e');
      }

      if (!mounted) return;
      _finished = true;
      Navigator.pushReplacement(context, createRoute(ResultPage(data: data, token: widget.token)));
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _finished = true;
        _error = 'Analysis timed out. Try again with a smaller image.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _finished = true;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Unable to load asset') || msg.contains('model')) {
      return 'Model file missing. Ensure assets/ml/model_unquant.tflite exists, then rebuild.';
    }
    if (msg.contains('Unsupported')) {
      return 'Image recognition is not available on web. Use Windows, Android, or iOS.';
    }
    return msg.replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<bool> _showNoMatchList(List parts) async {
    if (!mounted) return false;
    final selected = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),
                const Text("No matching part found", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('The part does not exist in the database. You can select an existing part below or open the full list.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: parts.length,
                    separatorBuilder: (context, index) => const Divider(height: 12),
                    itemBuilder: (c, i) {
                      final p = parts[i] as Map<String, dynamic>;
                      final img = p['image1'] ?? p['image2'] ?? p['image3'];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        leading: img != null
                            ? Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(ApiConfig.uploadUrl(img), fit: BoxFit.cover)))
                            : Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]), child: const Icon(Icons.image_not_supported_outlined)),
                        title: Text(p['reference'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('Qty: ${p['quantity'] ?? 0}'),
                        onTap: () {
                          Navigator.pop(ctx, p);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, 'list'), child: const Text('Open full list')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return false;
    if (selected == 'list') {
      if (!mounted) return false;
      Navigator.pushReplacement(context, createRoute(ListPage(token: widget.token)));
      return true;
    }
    if (!mounted) return false;
    final sel = Map<String, dynamic>.from(selected as Map);
    sel['confidence'] = 0.0;
    Navigator.pushReplacement(context, createRoute(ResultPage(data: sel, token: widget.token)));
    return true;
  }

  Future<bool> _showMatchesSelection(List<Map<String, dynamic>> matches) async {
    if (!mounted) return false;
    final selectedPart = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),
                const Text('Multiple matches found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Select the part that best matches the photo', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: matches.length,
                    separatorBuilder: (context, index) => const Divider(height: 12),                    itemBuilder: (c, i) {
                      final m = matches[i];
                      final p = m['part'] as Map<String, dynamic>;
                      final sc = (m['score'] as double) * 100.0;
                      final img = p['image1'] ?? p['image2'] ?? p['image3'];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        leading: img != null
                            ? Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(ApiConfig.uploadUrl(img), fit: BoxFit.cover)))
                            : Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]), child: const Icon(Icons.image_not_supported_outlined)),
                        title: Text(p['reference'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${sc.toStringAsFixed(1)}% similarity'),
                        onTap: () {
                          final selected = Map<String, dynamic>.from(p);
                          selected['confidence'] = m['score'];
                          Navigator.pop(ctx, selected);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel'))),
              ],
            ),
          ),
        );
      },
    );

    if (selectedPart == null) return false;
    if (!mounted) return false;
    Navigator.pushReplacement(context, createRoute(ResultPage(data: selectedPart, token: widget.token)));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: STBG.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: stbgLogo(height: 44),
            ),
            const SizedBox(height: 40),
            if (!_finished)
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [STBG.steel, STBG.accent]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: STBG.accent.withAlpha((0.4 * 255).round()), blurRadius: 24, spreadRadius: 4)],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  ),
                ),
              )
            else
              Icon(
                _error != null ? Icons.error_outline_rounded : Icons.check_circle_outline,
                color: _error != null ? STBG.gold : STBG.success,
                size: 72,
              ),
            const SizedBox(height: 30),
            Text(
              _error != null ? 'Analysis failed' : 'Analyzing Part...',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                _error ?? 'Please wait while we identify your part',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _error != null ? STBG.gold : Colors.white.withAlpha((0.5 * 255).round()),
                  fontSize: 13,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
