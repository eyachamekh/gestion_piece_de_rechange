import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:gestion_piece_de_rechange/services/image_classifier_service.dart';

class VisualGalleryMatch {
  final int partId;
  final double score;
  final String filename;

  const VisualGalleryMatch({
    required this.partId,
    required this.score,
    required this.filename,
  });
}

class VisualGalleryService {
  static const _manifestAsset = 'assets/ml/gallery_manifest.json';
  final Map<int, List<_GalleryEntry>> _entriesByPart = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final manifest =
        jsonDecode(await rootBundle.loadString(_manifestAsset)) as Map;
    final galleryBytes = await rootBundle.load(manifest['asset'] as String);
    final entries = manifest['entries'] as List;
    for (final raw in entries) {
      final item = Map<String, dynamic>.from(raw as Map);
      final offset = (item['offset'] as num).toInt();
      final length = (item['length'] as num).toInt();
      final values = Float32List.view(
        galleryBytes.buffer,
        galleryBytes.offsetInBytes + offset,
        length ~/ Float32List.bytesPerElement,
      ).toList();
      final entry = _GalleryEntry(
        partId: (item['partId'] as num).toInt(),
        filename: item['filename'] as String,
        embedding: values,
      );
      (_entriesByPart[entry.partId] ??= []).add(entry);
    }
    _loaded = true;
  }

  Future<List<VisualGalleryMatch>> findMatches(
    List<double> query, {
    int limit = 8,
  }) async {
    await load();
    final matches = <VisualGalleryMatch>[];
    for (final entries in _entriesByPart.values) {
      VisualGalleryMatch? best;
      for (final entry in entries) {
        final score = ImageClassifierService.cosineSimilarity(
          query,
          entry.embedding,
        );
        if (best == null || score > best.score) {
          best = VisualGalleryMatch(
            partId: entry.partId,
            score: score,
            filename: entry.filename,
          );
        }
      }
      if (best != null) matches.add(best);
    }
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(limit).toList();
  }
}

final visualGalleryService = VisualGalleryService();

class _GalleryEntry {
  final int partId;
  final String filename;
  final List<double> embedding;

  const _GalleryEntry({
    required this.partId,
    required this.filename,
    required this.embedding,
  });
}
