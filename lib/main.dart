import 'package:flutter/material.dart';
import 'package:gestion_piece_de_rechange/screens/login_page.dart';
import 'package:gestion_piece_de_rechange/services/mlkit_translation_service.dart';
import 'package:gestion_piece_de_rechange/services/safety_stock_service.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeAppData();
  runApp(const STBGApp());
}

Future<void> _initializeAppData() async {
  try {
    await loadHistory();
  } catch (error, stackTrace) {
    debugPrint('Unable to load saved history: $error\n$stackTrace');
  }

  try {
    await SafetyStockService.loadDelais();
  } catch (error, stackTrace) {
    debugPrint('Unable to load safety-stock delays: $error\n$stackTrace');
  }
}

class STBGApp extends StatefulWidget {
  const STBGApp({super.key});

  @override
  State<STBGApp> createState() => _STBGAppState();
}

class _STBGAppState extends State<STBGApp> {
  @override
  void initState() {
    super.initState();
    langNotifier.addListener(_onLangChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MLKitTranslationService.instance.preTranslateAllKeys(langNotifier.value);
    });
  }

  @override
  void dispose() {
    langNotifier.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    MLKitTranslationService.instance.preTranslateAllKeys(langNotifier.value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'STBG — Spare Parts',
      theme: ThemeData(
        primaryColor: STBG.steel,
        scaffoldBackgroundColor: STBG.surface,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(
          primary: STBG.steel,
          secondary: STBG.accent,
          surface: STBG.surface,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: STBG.steel,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
