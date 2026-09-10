import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gestion_piece_de_rechange/screens/result_page.dart';
import 'package:gestion_piece_de_rechange/screens/list_page.dart';
import 'package:gestion_piece_de_rechange/services/api_service.dart';
import 'package:gestion_piece_de_rechange/services/image_classifier_service.dart';
import 'package:gestion_piece_de_rechange/services/visual_gallery_service.dart';
import 'package:gestion_piece_de_rechange/services/text_recognition_service.dart';
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

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  static const double minimumDisplayedSimilarity = 0.60;

  late AnimationController _ctrl;
  late Animation<double> _pulse;
  String? _error;
  String _progressMessage = 'Preparing image...';
  bool _finished = false;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.9,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // Debug: print whether an image was passed
    debugPrint(
      'LoadingPage.initState: widget.image path=${widget.image?.path}',
    );

    // Load the preview bytes from the local File so the image displays immediately and reliably
    if (widget.image != null) {
      _loadPreviewBytes();
    }

    _identifyPart();
  }

  Future<void> _loadPreviewBytes() async {
    try {
      final bytes = await widget.image!.readAsBytes();
      if (!mounted) return;
      setState(() {
        _previewBytes = bytes;
      });
      debugPrint(
        'LoadingPage._loadPreviewBytes: loaded ${_previewBytes?.lengthInBytes ?? 0} bytes for ${widget.image?.path}',
      );
    } catch (e) {
      debugPrint('LoadingPage._loadPreviewBytes error: $e');
    }
  }

  void _setProgress(String message) {
    if (mounted) setState(() => _progressMessage = message);
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
      debugPrint('========== RECOGNITION START ==========');
      debugPrint('Image: ${widget.image!.path}');
      debugPrint('Image size: ${await widget.image!.length()} bytes');

      _setProgress('Reading text...');
      String ocrText = '';
      try {
        ocrText = await TextRecognitionService.recognize(widget.image!);
      } catch (e) {
        debugPrint('OCR error: $e');
      }

      final List<String> ocrCandidates =
          TextRecognitionService.extractReferenceCandidates(ocrText);
      debugPrint('OCR text: $ocrText');
      debugPrint('OCR candidates:');
      for (var i = 0; i < ocrCandidates.length; i++) {
        debugPrint('  ${i + 1}. ${ocrCandidates[i]}');
      }
      if (ocrCandidates.isEmpty) {
        debugPrint('========== DATABASE MATCH ==========');
        debugPrint(
          'Database query: not executed because OCR produced no candidates',
        );
        debugPrint('Match type: NO_REFERENCE_MATCH');
        debugPrint('====================================');
      }

      _setProgress('Searching references...');
      // Search backend using normalized OCR candidate strings, not the full raw OCR blob.
      Map<String, dynamic>? foundExact;
      Map<int, Map<String, dynamic>> partialMatchesById = {};
      List<dynamic> parts = const [];
      if (ocrCandidates.isNotEmpty) {
        for (final candidate in ocrCandidates.take(8)) {
          try {
            debugPrint('Searching reference: $candidate');
            final res = await searchPartsByReference(
              widget.token,
              candidate,
            ).timeout(const Duration(seconds: 8));
            final bool exact = res['exact'] == true;
            final List<dynamic> results = res['results'] ?? [];
            debugPrint(
              'OCR candidate "$candidate" => exact=$exact, hits=${results.length}',
            );
            debugPrint('Database reference matches: ${results.length}');
            if (exact && results.isNotEmpty) {
              foundExact = Map<String, dynamic>.from(results.first as Map);
              debugPrint('EXACT OCR MATCH: part ID ${foundExact['id']}');
              break;
            }
            for (final r in results) {
              final part = Map<String, dynamic>.from(r as Map);
              partialMatchesById[part['id'] as int] = part;
            }
          } catch (e) {
            debugPrint(
              'Reference search API error for candidate "$candidate": $e',
            );
          }
        }
        if (foundExact == null) {
          debugPrint('NO EXACT OCR MATCH');
        }
      }

      if (foundExact == null && ocrCandidates.isNotEmpty) {
        parts = await fetchParts(
          widget.token,
        ).timeout(const Duration(seconds: 8));
        final fuzzyMatch = _findStrongReferenceMatch(parts, ocrCandidates);
        if (fuzzyMatch != null) {
          foundExact = fuzzyMatch;
          debugPrint(
            'FUZZY OCR REFERENCE MATCH: ${fuzzyMatch['reference']} '
            '(OCR_REFERENCE_MATCH)',
          );
        }
      }

      if (foundExact != null) {
        debugPrint('Final selected part: ${foundExact['reference']}');
        debugPrint('Final reason: OCR_REFERENCE_MATCH');
        debugPrint('========================================');
        if (!mounted) return;
        foundExact['matchSource'] = 'ocr_exact';
        foundExact['ocrText'] = ocrText;
        Navigator.pushReplacement(
          context,
          createRoute(ResultPage(data: foundExact, token: widget.token)),
        );
        return;
      }

      _setProgress('Comparing visual features...');
      parts = await fetchParts(
        widget.token,
      ).timeout(const Duration(seconds: 8));
      final embedding = await imageClassifierService.getEmbedding(
        widget.image!,
      );
      final gallery = await visualGalleryService.findMatches(embedding);
      final partsById = <int, Map<String, dynamic>>{
        for (final raw in parts)
          (raw['id'] as num).toInt(): Map<String, dynamic>.from(raw as Map),
      };
      final combined = <Map<String, dynamic>>[];
      for (final match in gallery) {
        if (match.score < minimumDisplayedSimilarity) continue;
        final part = partsById[match.partId];
        if (part == null) continue;
        final ocr = partialMatchesById.containsKey(match.partId);
        combined.add({
          'part': part,
          'score': match.score,
          'visualScore': match.score,
          'matchSource': ocr ? 'ocr_partial+visual' : 'visual',
        });
      }
      debugPrint(
        'Visual gallery candidates above '
        '${minimumDisplayedSimilarity * 100}%: ${combined.length}',
      );
      if (combined.isEmpty) {
        if (!mounted) return;
        _finished = true;
        _showNoMatchList(parts, widget.image);
        return;
      }
      final bestScore = combined.first['score'] as double;
      final secondScore = combined.length > 1
          ? combined[1]['score'] as double
          : 0.0;
      final confident = bestScore >= 0.85 && bestScore - secondScore >= 0.05;
      if (!confident || combined.length > 1) {
        if (!mounted) return;
        _finished = true;
        _showMatchesSelection(combined, widget.image);
        return;
      }

      final best = combined.first;
      final p = best['part'] as Map<String, dynamic>;
      final sc = best['score'] as double;

      Map<String, dynamic> data = {
        'piece': p['reference'],
        'reference': p['reference'],
        'location': p['location'] ?? '—',
        'quantity': p['quantity'] ?? 0,
        'id': p['id'],
        'image1': p['image1'],
        'image2': p['image2'],
        'image3': p['image3'],
        'image4': p['image4'],
        'image5': p['image5'],
        'image6': p['image6'],
        'image7': p['image7'],
        'confidence': sc,
        'matchSource': best['matchSource'],
      };

      if (!mounted) return;
      _finished = true;
      Navigator.pushReplacement(
        context,
        createRoute(ResultPage(data: data, token: widget.token)),
      );
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

  Map<String, dynamic>? _findStrongReferenceMatch(
    List<dynamic> parts,
    List<String> candidates,
  ) {
    Map<String, dynamic>? best;
    var bestScore = 0.0;
    for (final rawPart in parts) {
      final part = Map<String, dynamic>.from(rawPart as Map);
      final reference = (part['reference'] ?? '').toString();
      for (final candidate in candidates) {
        final score = TextRecognitionService.referenceMatchScore(
          candidate,
          reference,
        );
        if (score > bestScore) {
          bestScore = score;
          best = part;
        }
      }
    }
    debugPrint(
      'Controlled OCR reference match: '
      '${best == null ? 'none' : best['reference']} score=$bestScore',
    );
    return bestScore >= 0.9 ? best : null;
  }

  Widget _buildSimilarityThumb(String? img, {double size = 56}) {
    final imageBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: img != null && img.isNotEmpty
            ? Image.network(
                ApiConfig.uploadUrl(img),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  );
                },
              )
            : const Center(child: Icon(Icons.image_not_supported_outlined)),
      ),
    );

    return imageBox;
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Unable to load asset') || msg.contains('model')) {
      return 'Model file missing. Ensure assets/ml/model_unquant.tflite exists, then rebuild.';
    }
    if (msg.contains('Unsupported')) {
      return 'Image recognition is not available on this platform.';
    }
    return msg.replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<bool> _showNoMatchList(List parts, File? scannedImage) async {
    if (!mounted) return false;

    // Show the sheet and attach a callback that will pop the loading page if the user cancels the sheet
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "No matching part found",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The part does not exist in the database. You can select an existing part below or open the full list.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Show the scanned image at the top of the sheet if available
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: parts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 12),
                    itemBuilder: (c, i) {
                      final p = parts[i] as Map<String, dynamic>;
                      String? img;
                      for (int j = 1; j <= 7; j++) {
                        final candidate = p['image$j'];
                        if (candidate != null &&
                            candidate.toString().isNotEmpty) {
                          img = candidate.toString();
                          break;
                        }
                      }
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        leading: _buildSimilarityThumb(img),
                        title: Text(
                          p['reference'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('Qty: ${p['quantity'] ?? 0}'),
                        onTap: () {
                          // Push details on top of the sheet so when the user returns they see the same similarity list
                          final sel = Map<String, dynamic>.from(p);
                          sel['confidence'] = 0.0;
                          Navigator.of(ctx).push(
                            createRoute(
                              ResultPage(data: sel, token: widget.token),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, 'list'),
                      child: const Text('Open full list'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((selected) {
      // Sheet dismissed: if user cancelled, go back to image chooser
      if (selected == null) {
        if (mounted) Navigator.pop(context);
      }
      // if selected == 'list', open full list
      if (selected == 'list') {
        if (mounted)
          Navigator.pushReplacement(
            context,
            createRoute(ListPage(token: widget.token)),
          );
      }
    });

    return true;
  }

  Future<bool> _showMatchesSelection(
    List<Map<String, dynamic>> matches,
    File? scannedImage,
  ) async {
    if (!mounted) return false;

    // Show the sheet and attach a callback that will pop the loading page if the user cancels the sheet
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Multiple matches found',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select the part that best matches the photo',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Show scanned image at the top of the sheet if available
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: matches.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 12),
                    itemBuilder: (c, i) {
                      final m = matches[i];
                      final p = m['part'] as Map<String, dynamic>;
                      final sc = (m['score'] as double) * 100.0;
                      String? img;
                      for (int j = 1; j <= 7; j++) {
                        final candidate = p['image$j'];
                        if (candidate != null &&
                            candidate.toString().isNotEmpty) {
                          img = candidate.toString();
                          break;
                        }
                      }
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        leading: _buildSimilarityThumb(img),
                        title: Text(
                          p['reference'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        // subtitle: Text('${sc.toStringAsFixed(1)}% similarity'),
                        subtitle: Text('${sc.toStringAsFixed(1)}% similarity'),
                        onTap: () {
                          final selected = Map<String, dynamic>.from(p);
                          selected['confidence'] = m['score'];
                          selected['visualScore'] =
                              m['visualScore'] ?? m['score'];
                          selected['matchSource'] =
                              m['matchSource'] ?? 'visual';
                          // Push details on top of the sheet so Back returns to the same similarity list
                          Navigator.of(ctx).push(
                            createRoute(
                              ResultPage(data: selected, token: widget.token),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((val) {
      if (val == null) {
        if (mounted) Navigator.pop(context);
      }
    });

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: STBG.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Top-center fixed-size preview box for the last chosen/taken picture
            Center(
              child: SizedBox(
                width: 240,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _previewBytes != null
                      ? Image.memory(
                          _previewBytes!,
                          fit: BoxFit.cover,
                          width: 240,
                          height: 160,
                        )
                      : (widget.image != null
                            ? Image.file(
                                widget.image!,
                                fit: BoxFit.cover,
                                width: 240,
                                height: 160,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              )),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: stbgLogo(height: 44),
            ),
            const SizedBox(height: 20),
            if (!_finished)
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [STBG.steel, STBG.accent],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: STBG.accent.withAlpha((0.4 * 255).round()),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              )
            else
              Icon(
                _error != null
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline,
                color: _error != null ? STBG.gold : STBG.success,
                size: 72,
              ),
            const SizedBox(height: 30),
            Text(
              _error != null ? 'Analysis failed' : 'Analyzing Part...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                _error ?? _progressMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _error != null
                      ? STBG.gold
                      : Colors.white.withAlpha((0.5 * 255).round()),
                  fontSize: 13,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Go back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
