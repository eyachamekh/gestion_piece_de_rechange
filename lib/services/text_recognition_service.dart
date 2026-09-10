import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class TextRecognitionService {
  static Future<String> recognize(File imageFile) async {
    if (!await imageFile.exists()) {
      throw ArgumentError('OCR image file does not exist: ${imageFile.path}');
    }

    final texts = <String>[];
    final filesToScan = <File>[imageFile];
    final originalBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(originalBytes);
    if (originalImage == null) {
      throw StateError('Could not decode image for OCR: ${imageFile.path}');
    }
    final orientation = originalImage.exif.imageIfd.orientation;
    debugPrint('========== OCR DEBUG ==========');
    debugPrint('Original image: ${imageFile.path}');
    debugPrint('Width: ${originalImage.width}');
    debugPrint('Height: ${originalImage.height}');
    debugPrint('EXIF orientation: ${orientation ?? 'not present'}');

    try {
      final prepared = await _preprocess(imageFile);
      if (prepared != null) {
        filesToScan.add(prepared);
        final preparedImage = img.decodeImage(await prepared.readAsBytes());
        debugPrint('Preprocessed image: ${prepared.path}');
        debugPrint('Width: ${preparedImage?.width ?? 'unknown'}');
        debugPrint('Height: ${preparedImage?.height ?? 'unknown'}');
      }
    } catch (error, stackTrace) {
      debugPrint('OCR preprocessing failed for ${imageFile.path}: $error');
      debugPrint('$stackTrace');
    }

    try {
      debugPrint('OCR execution:');
      debugPrint('STARTED');

      for (final candidate in filesToScan) {
        try {
          final recognized = await _recognizeWithWindowsBridge(candidate);
          if (recognized.trim().isNotEmpty) {
            texts.add(recognized.trim());
          }
          debugPrint('COMPLETED');
        } catch (error, stackTrace) {
          debugPrint('OCR failed for ${candidate.path}: $error');
          debugPrint('$stackTrace');
        }
      }

      final combined = texts
          .where((text) => text.isNotEmpty)
          .join('\n')
          .trim();
      if (combined.isEmpty) {
        throw StateError('Windows OCR returned no text for ${imageFile.path}');
      }

      debugPrint('Raw OCR text:\n$combined');
      debugPrint('REFERENCE CANDIDATES:');
      final candidates = extractReferenceCandidates(combined);
      for (var i = 0; i < candidates.length && i < 4; i++) {
        debugPrint('${i + 1}. ${candidates[i]}');
      }
      debugPrint('OCR errors: NONE');
      debugPrint('==========================');
      return combined;
    } catch (error, stackTrace) {
      debugPrint('OCR failed for ${imageFile.path}: $error');
      debugPrint('$stackTrace');
      debugPrint('OCR errors: $error');
      debugPrint('================================');
      rethrow;
    }
  }

  static Future<String> _recognizeWithWindowsBridge(File imageFile) async {
    final executable = await _resolveBridgeExecutable();
    final result = await Process.run(executable, [imageFile.path]);

    if (result.exitCode != 0) {
      final details = [result.stdout, result.stderr]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join('\n')
          .trim();
      throw StateError(
        'Windows OCR bridge failed for ${imageFile.path} (exit ${result.exitCode}): $details',
      );
    }

    final rawOutput = (result.stdout as String).trim();
    final start = rawOutput.indexOf('OCR_TEXT_BEGIN');
    final end = rawOutput.indexOf('OCR_TEXT_END');
    if (start == -1 || end == -1 || end <= start) {
      throw StateError('Windows OCR bridge returned no OCR text: $rawOutput');
    }

    final text = rawOutput
        .substring(start + 'OCR_TEXT_BEGIN'.length, end)
        .trim();

    debugPrint('Windows OCR output for ${imageFile.path}:\n$rawOutput');
    return text;
  }

  static Future<File?> _preprocess(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode image for OCR: ${imageFile.path}');
    }

    var oriented = img.bakeOrientation(decoded);
    const minimumWidth = 1600;
    if (oriented.width < minimumWidth) {
      final scale = minimumWidth / oriented.width;
      oriented = img.copyResize(
        oriented,
        width: minimumWidth,
        height: (oriented.height * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    }

    final enhanced = img.adjustColor(
      img.grayscale(oriented),
      contrast: 1.25,
      brightness: 1.05,
    );

    final outputBytes = Uint8List.fromList(img.encodeJpg(enhanced, quality: 95));
    final tempFile = File(
      '${Directory.systemTemp.path}/ocr_preprocessed_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(outputBytes);
    return tempFile;
  }

  static Future<String> _resolveBridgeExecutable() async {
    final root = await _locateProjectRoot();
    final exe = File(
      '$root/tools/windows_ocr_bridge/bin/Release/net8.0-windows10.0.19041.0/win-x64/publish/WindowsOcrBridge.exe',
    );
    if (!await exe.exists()) {
      final projectFile = File('$root/tools/windows_ocr_bridge/WindowsOcrBridge.csproj');
      if (!await projectFile.exists()) {
        throw StateError('Windows OCR bridge project not found at ${projectFile.path}');
      }
      final build = await Process.run(
        'dotnet',
        [
          'publish',
          projectFile.path,
          '-c',
          'Release',
          '-r',
          'win-x64',
          '--self-contained',
          'false',
        ],
      );
      if (build.exitCode != 0) {
        throw StateError(
          'Failed to build Windows OCR bridge: ${build.stderr}',
        );
      }
      if (!await exe.exists()) {
        throw StateError('Windows OCR bridge was not created at ${exe.path}');
      }
    }
    return exe.path;
  }

  static Future<String> _locateProjectRoot() async {
    var dir = Directory.current;
    for (var i = 0; i < 10; i++) {
      if (File('${dir.path}${Platform.pathSeparator}pubspec.yaml').existsSync()) {
        return dir.path;
      }
      if (dir.parent.path == dir.path) {
        break;
      }
      dir = dir.parent;
    }
    final candidate = Directory(Platform.resolvedExecutable).parent;
    if (File('${candidate.path}${Platform.pathSeparator}pubspec.yaml').existsSync()) {
      return candidate.path;
    }
    throw StateError('Could not locate Flutter project root for Windows OCR bridge');
  }

  static List<String> extractReferenceCandidates(String rawText) {
    final occurrences = <String, int>{};
    final normalizedText = rawText.toUpperCase();
    final tokens = RegExp(r'[A-Z0-9]+')
        .allMatches(normalizedText)
        .map((match) => match.group(0)!)
        .where((token) => token.length >= 3)
        .toList();

    void addCandidate(String value) {
      final candidate = normalizeReferenceCandidate(value);
      if (candidate.isEmpty) return;
      occurrences[candidate] = (occurrences[candidate] ?? 0) + 1;
    }

    for (final token in tokens) {
      addCandidate(token);
    }

    for (int i = 0; i < tokens.length; i++) {
      for (
        int length = 2;
        length <= 3 && i + length <= tokens.length;
        length++
      ) {
        addCandidate(tokens.sublist(i, i + length).join());
      }
    }

    final candidates = occurrences.keys.toList()
      ..sort((a, b) {
        final frequency = occurrences[b]!.compareTo(occurrences[a]!);
        if (frequency != 0) return frequency;
        final score = _referenceScore(b).compareTo(_referenceScore(a));
        if (score != 0) return score;
        return b.length.compareTo(a.length);
      });
    return candidates;
  }

  static String normalizeReferenceCandidate(String value) {
    if (value.trim().isEmpty) return '';
    final compact = value
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .trim();
    if (compact.length < 3 || compact.length > 40) return '';
    if (RegExp(r'^[A-Z]+$').hasMatch(compact) &&
        _ignoredWords.contains(compact)) {
      return '';
    }
    return compact;
  }

  static String normalizeReference(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static double referenceMatchScore(String candidate, String reference) {
    final left = normalizeReference(candidate);
    final right = normalizeReference(reference);
    if (left.isEmpty || right.isEmpty) return 0;
    if (left == right) return 1;
    if (left.contains(right) || right.contains(left)) {
      final ratio = (left.length < right.length ? left.length : right.length) /
          (left.length > right.length ? left.length : right.length);
      return ratio >= 0.65 ? 0.92 : 0;
    }
    if (left.length != right.length) return 0;

    var penalty = 0.0;
    for (var i = 0; i < left.length; i++) {
      if (left[i] == right[i]) continue;
      if (_isOcrConfusion(left[i], right[i])) {
        penalty += 0.15;
      } else {
        penalty += 1.0;
      }
    }
    final score = 1.0 - (penalty / left.length);
    return score >= 0.8 ? score : 0;
  }

  static bool _isOcrConfusion(String a, String b) {
    return (a == 'O' && b == '0') ||
        (a == '0' && b == 'O') ||
        (a == 'I' && b == '1') ||
        (a == '1' && b == 'I') ||
        (a == 'S' && b == '5') ||
        (a == '5' && b == 'S') ||
        (a == 'B' && b == '8') ||
        (a == '8' && b == 'B');
  }

  static int _referenceScore(String candidate) {
    var score = 0;
    if (candidate.contains(RegExp(r'[A-Z]'))) score += 2;
    if (candidate.contains(RegExp(r'[0-9]'))) score += 3;
    if (candidate.length >= 6) score += 1;
    return score;
  }

  static const _ignoredWords = {
    'AND',
    'MADE',
    'PART',
    'PIECE',
    'REF',
    'STEEL',
    'TYPE',
  };
}
