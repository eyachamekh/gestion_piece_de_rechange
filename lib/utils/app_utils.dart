import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gestion_piece_de_rechange/services/mlkit_translation_service.dart';

final langNotifier = ValueNotifier<String>("fr");

String t(String key) {
  final lang = langNotifier.value;
  if (lang == "en") return key;
  final cached = MLKitTranslationService.instance.getCachedTranslation(key, lang);
  if (cached != null) return cached;
  MLKitTranslationService.instance.translate(key, targetLang: lang);
  return key;
}

void toggleLanguage() {
  final next = langNotifier.value == 'en' ? 'fr' : langNotifier.value == 'fr' ? 'ar' : 'en';
  langNotifier.value = next;
  MLKitTranslationService.instance.preTranslateAllKeys(next);
}

class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  const TranslatedText(this.text, {this.style, this.textAlign, super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: langNotifier,
        builder: (_, lang, __) => ValueListenableBuilder<int>(
          valueListenable: MLKitTranslationService.instance.translationVersion,
          builder: (_, __, ___) => Text(t(text), style: style, textAlign: textAlign),
        ),
      );
}

class STBG {
  static const Color navy = Color(0xFF0A1628);
  static const Color navyLight = Color(0xFF112240);
  static const Color steel = Color(0xFF1E4D8C);
  static const Color accent = Color(0xFF2E86DE);
  static const Color gold = Color(0xFFE8A400);
  static const Color surface = Color(0xFFF4F6F9);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color danger = Color(0xFFE53935);
  static const Color success = Color(0xFF1B8A5A);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [navy, steel],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [steel, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Helpers
String formatLocalDateOnly(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
}

String formatLocalDateTimeForApi(DateTime d) {
  final l = d.toLocal();
  String p(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${p(l.month)}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}:${p(l.second)}';
}

Route createRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(a),
        child: child,
      ),
    ),
  );
}

List<Map<String, dynamic>> _history = [];

Future<void> loadHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('history');
  if (raw != null) _history = List<Map<String, dynamic>>.from(jsonDecode(raw));
}

Future<void> saveHistory() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('history', jsonEncode(_history));
}

List<Map<String, dynamic>> get appHistory => _history;

void addToHistory(Map<String, dynamic> item) {
  _history.insert(0, item);
  if (_history.length > 200) _history = _history.sublist(0, 200);
  saveHistory();
}
