import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:translator/translator.dart' as web_translator;

// Dynamic On-Device Translation Service powered strictly by Google ML Kit.
class MLKitTranslationService {
  static final MLKitTranslationService instance = MLKitTranslationService._internal();
  MLKitTranslationService._internal();

  // Cache: text -> (langCode -> translatedText)
  final Map<String, Map<String, String>> _cache = {};

  // Set of all discovered UI text keys to pre-translate when language changes
  final Set<String> _registeredKeys = {};

  // Active ML Kit translators pool
  final Map<String, OnDeviceTranslator> _translators = {};

  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();
  final web_translator.GoogleTranslator _webFallbackTranslator = web_translator.GoogleTranslator();

  final ValueNotifier<bool> isDownloadingModel = ValueNotifier<bool>(false);
  final ValueNotifier<int> translationVersion = ValueNotifier<int>(0);

  bool _isMlKitSupported =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  TranslateLanguage _mapCodeToLanguage(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'fr':
        return TranslateLanguage.french;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'en':
      default:
        return TranslateLanguage.english;
    }
  }

  // Check if an ML Kit language model is downloaded on device
  Future<bool> isModelDownloaded(String langCode) async {
    if (langCode == 'en' || !_isMlKitSupported) return true;
    try {
      final lang = _mapCodeToLanguage(langCode);
      return await _modelManager.isModelDownloaded(lang.bcpCode);
    } catch (e) {
      _isMlKitSupported = false;
      return false;
    }
  }

  // Downloads ML Kit language model to device if not present
  Future<bool> ensureModelDownloaded(String langCode) async {
    if (langCode == 'en' || !_isMlKitSupported) return true;
    try {
      final lang = _mapCodeToLanguage(langCode);
      final isDownloaded = await _modelManager.isModelDownloaded(lang.bcpCode);
      if (!isDownloaded) {
        isDownloadingModel.value = true;
        final downloaded = await _modelManager.downloadModel(lang.bcpCode);
        isDownloadingModel.value = false;
        return downloaded;
      }
      return true;
    } catch (e) {
      debugPrint("ML Kit model manager exception (Desktop/Web fallback active): $e");
      _isMlKitSupported = false;
      isDownloadingModel.value = false;
      return false;
    }
  }

  // Synchronously get cached translation from Google ML Kit
  String? getCachedTranslation(String text, String targetLang) {
    if (targetLang == 'en') return text;
    _registeredKeys.add(text);
    if (_cache.containsKey(text) && _cache[text]!.containsKey(targetLang)) {
      return _cache[text]![targetLang];
    }
    return null;
  }

  // Get fallback translation (returns original text until ML Kit finishes translating)
  String getFallback(String text, String targetLang) {
    if (targetLang == 'en') return text;
    if (_cache.containsKey(text) && _cache[text]!.containsKey(targetLang)) {
      return _cache[text]![targetLang]!;
    }
    return text;
  }

  // Translates text dynamically using Google ML Kit (on-device machine learning).
  // Falls back to web translator API if unsupported on desktop/web environment.
  Future<String> translate(String text, {required String targetLang, String sourceLang = 'en'}) async {
    if (text.trim().isEmpty) return text;
    _registeredKeys.add(text);
    if (targetLang == sourceLang) return text;

    // 1. Return cached translation if already resolved by ML Kit
    final cached = getCachedTranslation(text, targetLang);
    if (cached != null) return cached;

    // 2. Perform Google ML Kit on-device translation
    if (_isMlKitSupported) {
      try {
        final pairKey = '${sourceLang}_$targetLang';
        if (!_translators.containsKey(pairKey)) {
          final srcLang = _mapCodeToLanguage(sourceLang);
          final tgtLang = _mapCodeToLanguage(targetLang);
          _translators[pairKey] = OnDeviceTranslator(
            sourceLanguage: srcLang,
            targetLanguage: tgtLang,
          );
        }

        final translated = await _translators[pairKey]!.translateText(text);
        if (translated.isNotEmpty) {
          _cache[text] ??= {};
          _cache[text]![targetLang] = translated;
          translationVersion.value++;
          return translated;
        }
      } catch (e) {
        debugPrint("ML Kit translation error for '$text': $e");
        if (e.toString().contains("MissingPluginException") || e.toString().contains("Unimplemented")) {
          _isMlKitSupported = false;
        }
      }
    }

    // 3. Fallback to Google Translator HTTP API (web/desktop)
    try {
      final res = await _webFallbackTranslator.translate(text, from: sourceLang, to: targetLang);
      if (res.text.isNotEmpty) {
        _cache[text] ??= {};
        _cache[text]![targetLang] = res.text;
        translationVersion.value++;
        return res.text;
      }
    } catch (e) {
      debugPrint("HTTP translation fallback failed: $e");
    }

    // 4. Return original string if translation fails
    return text;
  }

  // Dynamically translates all registered UI keys using Google ML Kit when language changes
  Future<void> preTranslateAllKeys(String targetLang, [List<String>? customKeys]) async {
    if (targetLang == 'en' || !_isMlKitSupported) return;

    // Download Google ML Kit language model on device if required
    await ensureModelDownloaded(targetLang);

    final keysToTranslate = (customKeys ?? _registeredKeys.toList()).toList();
    for (final key in keysToTranslate) {
      await translate(key, targetLang: targetLang);
    }
  }

  void dispose() {
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
  }
}
