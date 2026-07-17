import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:gestion_piece_de_rechange/config/api_config.dart';
import 'package:gestion_piece_de_rechange/services/image_classifier_service.dart';
import 'package:gestion_piece_de_rechange/services/safety_stock_service.dart';
import 'package:gestion_piece_de_rechange/widgets/order_alert_banner.dart';
final langNotifier = ValueNotifier<String>("fr");

const Map<String, Map<String, String>> _tr = {
  "Sign In": {"fr": "Connexion", "ar": "تسجيل الدخول"},
  "Enter your credentials to continue": {"fr": "Entrez vos identifiants", "ar": "أدخل بيانات الدخول"},
  "Login failed. Please check your credentials.": {"fr": "Échec de connexion.", "ar": "فشل تسجيل الدخول."},
  "Welcome back": {"fr": "Bon retour", "ar": "مرحباً بعودتك"},
  "Spare Parts Manager": {"fr": "Gestion des pièces", "ar": "إدارة قطع الغيار"},
  "Total Parts": {"fr": "Total pièces", "ar": "إجمالي القطع"},
  "Scanned": {"fr": "Scannés", "ar": "تم المسح"},
  "Low Stock": {"fr": "Stock bas", "ar": "مخزون منخفض"},
  "Quick Actions": {"fr": "Actions rapides", "ar": "إجراءات سريعة"},
  "Start Scanning": {"fr": "Démarrer le scan", "ar": "بدء المسح"},
  "Identify a part using your camera": {"fr": "Identifier une pièce avec la caméra", "ar": "تعرف على قطعة بالكاميرا"},
  "Spare Parts Inventory": {"fr": "Inventaire des pièces", "ar": "مخزون قطع الغيار"},
  "Browse, search, add and manage parts": {"fr": "Parcourir et gérer les pièces", "ar": "تصفح وإدارة القطع"},
  "Activity History": {"fr": "Historique des activités", "ar": "سجل الأنشطة"},
  "View recent part withdrawals": {"fr": "Voir les sorties récentes", "ar": "عرض السحوبات الأخيرة"},
  "Scan a Part": {"fr": "Scanner une pièce", "ar": "مسح قطعة"},
  "Identify a spare part using your camera or gallery": {"fr": "Identifier via caméra ou galerie", "ar": "تعرف عبر الكاميرا أو المعرض"},
  "Take a Photo": {"fr": "Prendre une photo", "ar": "التقاط صورة"},
  "Use your camera to capture the part": {"fr": "Utilisez la caméra", "ar": "استخدم الكاميرا"},
  "Choose from Gallery": {"fr": "Choisir depuis la galerie", "ar": "اختر من المعرض"},
  "Select an existing photo": {"fr": "Sélectionner une photo", "ar": "اختر صورة موجودة"},
  "Part Details": {"fr": "Détails de la pièce", "ar": "تفاصيل القطعة"},
  "Identified spare part information": {"fr": "Informations sur la pièce", "ar": "معلومات قطعة الغيار"},
  "Reference": {"fr": "Référence", "ar": "المرجع"},
  "Location": {"fr": "Emplacement", "ar": "الموقع"},
  "Quantity": {"fr": "Quantité", "ar": "الكمية"},
  "Low Stock — Reorder recommended": {"fr": "Stock bas — Réapprovisionnement recommandé", "ar": "مخزون منخفض — يُنصح بإعادة الطلب"},
  "In Stock — Available": {"fr": "En stock — Disponible", "ar": "متوفر في المخزون"},
  "In Stock": {"fr": "En stock", "ar": "متوفر"},
  "Analyzing Part...": {"fr": "Analyse en cours...", "ar": "جارٍ التحليل..."},
  "Please wait while we identify your part": {"fr": "Veuillez patienter", "ar": "يرجى الانتظار"},
  "Spare Parts": {"fr": "Pièces de rechange", "ar": "قطع الغيار"},
  "Inventory management": {"fr": "Gestion de l'inventaire", "ar": "إدارة المخزون"},
  "No parts found": {"fr": "Aucune pièce trouvée", "ar": "لا توجد قطع"},
  "Add New Part": {"fr": "Ajouter une pièce", "ar": "إضافة قطعة جديدة"},
  "Add Part": {"fr": "Ajouter", "ar": "إضافة"},
  "Cancel": {"fr": "Annuler", "ar": "إلغاء"},
  "Delete Part": {"fr": "Supprimer la pièce", "ar": "حذف القطعة"},
  "Are you sure you want to delete this part?": {"fr": "Voulez-vous vraiment supprimer?", "ar": "هل أنت متأكد من الحذف؟"},
  "Delete": {"fr": "Supprimer", "ar": "حذف"},
  "Edit Part": {"fr": "Modifier la pièce", "ar": "تعديل القطعة"},
  "Save": {"fr": "Enregistrer", "ar": "حفظ"},
  "Withdraw Parts": {"fr": "Prendre des pièces", "ar": "سحب قطع"},
  "Confirm": {"fr": "Confirmer", "ar": "تأكيد"},
  "Parts withdrawal log": {"fr": "Journal des sorties", "ar": "سجل السحوبات"},
  "No activity recorded yet": {"fr": "Aucune activité enregistrée", "ar": "لا يوجد نشاط بعد"},
};

String t(String key) {
  final lang = langNotifier.value;
  if (lang == "en") return key;
  return _tr[key]?[lang] ?? key;
}

class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  const TranslatedText(this.text, {this.style, this.textAlign});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: langNotifier,
    builder: (_, __, ___) => Text(t(text), style: style, textAlign: textAlign),
  );
}
class STBG {
  static const Color navy       = Color(0xFF0A1628);
  static const Color navyLight  = Color(0xFF112240);
  static const Color steel      = Color(0xFF1E4D8C);
  static const Color accent     = Color(0xFF2E86DE);
  static const Color gold       = Color(0xFFE8A400);
  static const Color surface    = Color(0xFFF4F6F9);
  static const Color card       = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color danger     = Color(0xFFE53935);
  static const Color success    = Color(0xFF1B8A5A);

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

// ─── Helpers ──────────────────────────────────────────────────────────────────
String formatLocalDateOnly(DateTime d) {
  final l = d.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2,'0')}-${l.day.toString().padLeft(2,'0')}';
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

// ─── App Entry ────────────────────────────────────────────────────────────────
List<Map<String, dynamic>> _history = [];

Future<void> _loadHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('history');
  if (raw != null) _history = List<Map<String, dynamic>>.from(jsonDecode(raw));
}

Future<void> _saveHistory() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('history', jsonEncode(_history));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadHistory();
  await SafetyStockService.loadDelais();
  if (ImageClassifierService.isPlatformSupported) {
    try {
      await _imageClassifier.load();
    } catch (_) {}
  }
  runApp(const STBGApp());
}

class STBGApp extends StatefulWidget {
  const STBGApp({super.key});
  static _STBGAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_STBGAppState>();
  @override
  _STBGAppState createState() => _STBGAppState();
}

class _STBGAppState extends State<STBGApp> {
  void changeLang() {
    if (langNotifier.value == "en") langNotifier.value = "fr";
    else if (langNotifier.value == "fr") langNotifier.value = "ar";
    else langNotifier.value = "en";
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

// ─── Shared Widgets ───────────────────────────────────────────────────────────

Widget _stbgLogo({double height = 52}) => Image.asset(
  'assets/images/logo-stbg.jpg',
  height: height,
  fit: BoxFit.contain,
);

class _STBGHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showBack;
  final List<Widget> actions;
  final Widget? bottom;
  final double extraPad;

  const _STBGHeader({
    this.title,
    this.subtitle,
    this.showBack = false,
    this.actions = const [],
    this.bottom,
    this.extraPad = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: STBG.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 6))],
      ),
      padding: EdgeInsets.fromLTRB(22, 54 + extraPad, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                  ),
                ),
              if (showBack) const SizedBox(width: 12),
              Expanded(child: Container()),
              ...actions,
            ],
          ),
          if (title != null) ...[
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        TranslatedText(
                          subtitle!,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (bottom != null) ...[const SizedBox(height: 16), bottom!],
        ],
      ),
    );
  }
}

// ─── LOGIN PAGE ───────────────────────────────────────────────────────────────
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl  = TextEditingController();

    return Scaffold(
      backgroundColor: STBG.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top branding block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 24, offset: Offset(0, 8))],
                      ),
                      child: _stbgLogo(height: 60),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'STBG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Spare Parts Management',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // Form card
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 32, offset: Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      'Sign In',
                      style: const TextStyle(
                        color: STBG.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TranslatedText(
                      'Enter your credentials to continue',
                      style: const TextStyle(color: STBG.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 28),
                    _LoginField(controller: emailCtrl, label: 'Email', icon: Icons.alternate_email),
                    const SizedBox(height: 16),
                    _LoginField(controller: passCtrl, label: 'Password', icon: Icons.lock_outline, obscure: true),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final res = await login(emailCtrl.text, passCtrl.text);
                          if (res["success"] == true) {
                            Navigator.pushReplacement(
                              context,
                              createRoute(HomePage(role: res["role"], token: res["token"])),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const TranslatedText('Login failed. Please check your credentials.'),
                                backgroundColor: STBG.danger,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: STBG.navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const TranslatedText(
                          'Sign In',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: langNotifier,
                          builder: (_, lang, __) => _LangChip(lang: lang, onTap: () => STBGApp.of(context)?.changeLang()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '© ${DateTime.now().year} STBG — All rights reserved',
                style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  const _LoginField({required this.controller, required this.label, required this.icon, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: langNotifier,
      builder: (_, lang, __) {
        String lbl = label;
        if (label == 'Email') lbl = lang == 'fr' ? 'E-mail' : lang == 'ar' ? 'البريد الإلكتروني' : label;
        if (label == 'Password') lbl = lang == 'fr' ? 'Mot de passe' : lang == 'ar' ? 'كلمة المرور' : label;
        return TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: lbl,
            labelStyle: const TextStyle(color: STBG.textSecondary, fontSize: 14),
            prefixIcon: Icon(icon, color: STBG.steel, size: 20),
            filled: true,
            fillColor: STBG.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: STBG.steel, width: 2),
            ),
          ),
        );
      },
    );
  }
}

class _LangChip extends StatelessWidget {
  final String lang;
  final VoidCallback onTap;
  const _LangChip({required this.lang, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final labels = {'en': '🇬🇧 English', 'fr': '🇫🇷 Français', 'ar': '🇩🇿 العربية'};
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: STBG.steel.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
          color: STBG.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labels[lang] ?? '', style: const TextStyle(fontSize: 13, color: STBG.textPrimary)),
            const SizedBox(width: 6),
            const Icon(Icons.swap_horiz, size: 14, color: STBG.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── HOME PAGE ────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  final String role;
  final String token;
  const HomePage({required this.role, required this.token});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalParts = 0;
  int lowStockCount = 0;
  int scannedCount = 0;
  int orderAlertCount = 0;
  bool loading = true;

  @override
  void initState() { super.initState(); _loadStats(); }

  Future<void> _loadStats() async {
    try {
      final parts = await fetchParts(widget.token);
      // Récupérer les activités pour calculer la consommation
      List activities = [];
      try {
        final res = await http.get(
          Uri.parse(ApiConfig.url('/api/activities')),
          headers: {"Authorization": "Bearer ${widget.token}"},
        );
        if (res.statusCode == 200) activities = jsonDecode(res.body);
      } catch (_) {}

      final alerts = SafetyStockService.getOrderAlerts(
        parts: parts,
        activities: activities,
      );

      setState(() {
        totalParts = parts.length;
        lowStockCount = parts.where((p) => (p["quantity"] ?? 0) <= 5).length;
        scannedCount = parts.where((p) => p["scanned"] == true).length;
        orderAlertCount = alerts.length;
        loading = false;
      });
    } catch (_) { setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: STBG.surface,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: STBG.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Color(0x35000000), blurRadius: 20, offset: Offset(0, 6))],
            ),
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo in header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _stbgLogo(height: 28),
                    ),
                    Row(
                      children: [
                        _HeaderIconBtn(
                          icon: Icons.language_rounded,
                          onTap: () => STBGApp.of(context)?.changeLang(),
                        ),
                        const SizedBox(width: 8),
                        _HeaderIconBtn(
                          icon: Icons.logout_rounded,
                          onTap: () => Navigator.pushAndRemoveUntil(
                            context, createRoute(const LoginPage()), (_) => false),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TranslatedText(
                  'Welcome back',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
                const SizedBox(height: 4),
                const TranslatedText(
                  'Spare Parts Manager',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
                const SizedBox(height: 20),
                if (loading)
                  const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else
                  Row(children: [
                    _StatCard(label: 'Total Parts', value: '$totalParts', icon: Icons.inventory_2_outlined),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Scanned', value: '$scannedCount', icon: Icons.qr_code_scanner_rounded),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'À commander',
                      value: '$orderAlertCount',
                      icon: Icons.shopping_cart_outlined,
                      highlight: orderAlertCount > 0,
                    ),
                  ]),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Quick actions
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TranslatedText(
                    'Quick Actions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: STBG.textPrimary, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 14),
                  _ActionTile(
                    icon: Icons.document_scanner_rounded,
                    title: 'Start Scanning',
                    subtitle: 'Identify a part using your camera',
                    accent: STBG.steel,
                    onTap: () => Navigator.push(context, createRoute(ScanPage(token: widget.token))),
                  ),
                  if (widget.role == 'admin') ...[
                    const SizedBox(height: 12),
                    _ActionTile(
                      icon: Icons.list_alt_rounded,
                      title: 'Spare Parts Inventory',
                      subtitle: 'Browse, search, add and manage parts',
                      accent: STBG.success,
                      onTap: () => Navigator.push(context, createRoute(ListPage(token: widget.token))),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.history_rounded,
                    title: 'Activity History',
                    subtitle: 'View recent part withdrawals',
                    accent: STBG.gold,
                    onTap: () => Navigator.push(context, createRoute(HistoryPage(history: _history))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const _StatCard({required this.label, required this.value, required this.icon, this.highlight = false});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? STBG.gold.withOpacity(0.18) : Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border: highlight ? Border.all(color: STBG.gold.withOpacity(0.5)) : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: highlight ? STBG.gold : Colors.white, size: 19),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: highlight ? STBG.gold : Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          TranslatedText(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 10)),
        ],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.accent, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0E000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: STBG.textPrimary)),
                  const SizedBox(height: 3),
                  TranslatedText(subtitle, style: const TextStyle(color: STBG.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 14),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── SCAN PAGE ────────────────────────────────────────────────────────────────
final _imageClassifier = ImageClassifierService();

class ScanPage extends StatefulWidget {
  final String token;
  const ScanPage({required this.token});
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected image. Try again.')),
      );
      return;
    }
    setState(() => _image = file);
    Navigator.push(context, createRoute(LoadingPage(image: file, token: widget.token)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: STBG.surface,
      body: Column(
        children: [
          _STBGHeader(
            title: 'Scan a Part',
            subtitle: 'Identify a spare part using your camera or gallery',
            showBack: true,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Scan indicator visual
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [STBG.steel.withOpacity(0.15), STBG.steel.withOpacity(0.03)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: STBG.steel.withOpacity(0.2), width: 2),
                    ),
                    child: Icon(Icons.document_scanner_rounded, size: 58, color: STBG.steel.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 36),
                  _ScanOption(
                    icon: Icons.camera_alt_rounded,
                    title: 'Take a Photo',
                    subtitle: 'Use your camera to capture the part',
                    onTap: () => pickImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 14),
                  _ScanOption(
                    icon: Icons.photo_library_rounded,
                    title: 'Choose from Gallery',
                    subtitle: 'Select an existing photo',
                    onTap: () => pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ScanOption({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [STBG.steel, STBG.accent]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: STBG.textPrimary)),
                  const SizedBox(height: 3),
                  TranslatedText(subtitle, style: const TextStyle(color: STBG.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: STBG.textSecondary),
          ],
        ),
      ),
    ),
  );
}

// ─── LOADING PAGE ─────────────────────────────────────────────────────────────
class LoadingPage extends StatefulWidget {
  final File? image;
  final String token;
  const LoadingPage({this.image, required this.token});
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  String? _error;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.05).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _identifyPart();
  }

  Map<String, dynamic>? _findPartMatch(List parts, String label) {
    final normalized = label.trim().toLowerCase();
    for (final p in parts) {
      final ref = (p['reference'] ?? '').toString().trim().toLowerCase();
      if (ref.isEmpty) continue;
      if (ref == normalized || ref.contains(normalized) || normalized.contains(ref)) {
        return Map<String, dynamic>.from(p);
      }
    }
    return null;
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
      final scannedEmbedding = await _imageClassifier
          .getEmbedding(widget.image!)
          .timeout(const Duration(seconds: 45));

      Map<String, dynamic> data = {
        'piece': 'Unknown Part',
        'reference': 'Unknown',
        'location': '—',
        'quantity': 0,
        'confidence': 0.0,
      };

      try {
        final parts = await fetchParts(widget.token)
            .timeout(const Duration(seconds: 8));
        
        Map<String, dynamic>? bestMatch;
        double bestScore = -1.0;

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
                print("Error parsing embedding$i: $e");
              }
            }
          }
          if (maxPartScore > bestScore) {
            bestScore = maxPartScore;
            bestMatch = Map<String, dynamic>.from(p);
          }
        }

        if (bestMatch != null && bestScore >= 0.65) {
          data = {
            'piece': bestMatch['reference'],
            'reference': bestMatch['reference'],
            'location': bestMatch['location'] ?? '—',
            'quantity': bestMatch['quantity'] ?? 0,
            'id': bestMatch['id'],
            'image1': bestMatch['image1'],
            'image2': bestMatch['image2'],
            'image3': bestMatch['image3'],
            'confidence': bestScore,
          };
        } else if (bestMatch != null) {
          data = {
            'piece': '${bestMatch['reference']} (Low confidence)',
            'reference': bestMatch['reference'],
            'location': bestMatch['location'] ?? '—',
            'quantity': bestMatch['quantity'] ?? 0,
            'id': bestMatch['id'],
            'image1': bestMatch['image1'],
            'image2': bestMatch['image2'],
            'image3': bestMatch['image3'],
            'confidence': bestScore,
          };
        }
      } catch (e) {
        print("Database fetch/match error: $e");
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
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
              child: _stbgLogo(height: 44),
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
                    boxShadow: [BoxShadow(color: STBG.accent.withOpacity(0.4), blurRadius: 24, spreadRadius: 4)],
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
                  color: _error != null ? STBG.gold : Colors.white.withOpacity(0.5),
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

// ─── RESULT PAGE ──────────────────────────────────────────────────────────────
class ResultPage extends StatefulWidget {
  final Map data;
  final String? token;
  const ResultPage({required this.data, this.token});
  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  SafetyStockResult? _ssResult;

  @override
  void initState() {
    super.initState();
    _computeSafetyStock();
  }

  Future<void> _computeSafetyStock() async {
    final ref = (widget.data['reference'] ?? '').toString();
    if (ref.isEmpty || ref == 'Unknown') return;
    List activities = [];
    if (widget.token != null) {
      try {
        final res = await http.get(
          Uri.parse(ApiConfig.url('/api/activities')),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        if (res.statusCode == 200) activities = jsonDecode(res.body);
      } catch (_) {}
    }
    final results = SafetyStockService.compute(
      parts: [widget.data],
      activities: activities,
    );
    if (results.isNotEmpty && mounted) {
      setState(() => _ssResult = results.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int qty = widget.data["quantity"] ?? 0;
    final bool lowStock = qty <= 5;
    final bool mustOrder = _ssResult?.mustOrder ?? lowStock;
    final bool isOrderAlert = _ssResult != null && _ssResult!.mustOrder;

    // Determine status level: order alert (orange) > low stock (red) > ok (green)
    final Color statusColor = isOrderAlert
        ? STBG.gold
        : mustOrder
            ? STBG.danger
            : STBG.success;
    final IconData statusIcon = isOrderAlert
        ? Icons.shopping_cart_outlined
        : mustOrder
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline_rounded;
    final String statusText = isOrderAlert
        ? 'Stock de sécurité atteint — Passer une commande DA'
        : mustOrder
            ? 'Low Stock — Reorder recommended'
            : 'In Stock — Available';

    return Scaffold(
      backgroundColor: STBG.surface,
      body: Column(
        children: [
          _STBGHeader(title: 'Part Details', subtitle: 'Identified spare part information', showBack: true),

          // Images carousel
          if (["image1","image2","image3"].any((k) => widget.data[k] != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ["image1","image2","image3"]
                      .where((k) => widget.data[k] != null)
                      .map((k) => Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 110,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[200]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        ApiConfig.uploadUrl('${widget.data[k]}'),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Status banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Safety stock detail card (only when alert) ──
                  if (isOrderAlert && _ssResult != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: STBG.gold.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics_outlined, size: 14, color: STBG.gold),
                              const SizedBox(width: 6),
                              const Text(
                                'Analyse stock de sécurité',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF7A4F00)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _SSMetric(
                                label: 'Stock actuel',
                                value: '${_ssResult!.currentQty}',
                                color: STBG.danger,
                              ),
                              const SizedBox(width: 8),
                              _SSMetric(
                                label: 'Stock sécurité',
                                value: '${_ssResult!.safetyStock}',
                                color: STBG.steel,
                              ),
                              const SizedBox(width: 8),
                              _SSMetric(
                                label: 'Délai DA',
                                value: '${_ssResult!.delaiJours.toStringAsFixed(0)} j',
                                color: STBG.success,
                              ),
                              const SizedBox(width: 8),
                              _SSMetric(
                                label: 'Conso/jour',
                                value: _ssResult!.consommationJour.toStringAsFixed(2),
                                color: const Color(0xFF7B1FA2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: STBG.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '⚠️  Quantité actuelle ≤ stock de sécurité\nUne demande d\'achat (DA) doit être passée immédiatement.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF7A4F00), height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Info card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _InfoRow(icon: Icons.tag_rounded, label: 'Reference', value: widget.data["reference"] ?? '-'),
                        _Divider(),
                        _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: widget.data["location"] ?? '-'),
                        _Divider(),
                        _InfoRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Quantity',
                          value: qty.toString(),
                          badge: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 11, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  isOrderAlert ? 'À commander' : mustOrder ? 'Low Stock' : 'In Stock',
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
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
        ],
      ),
    );
  }
}

class _SSMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SSMetric({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF7A4F00)), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? badge;
  const _InfoRow({required this.icon, required this.label, required this.value, this.badge});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: STBG.steel.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: STBG.steel, size: 17),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(label, style: const TextStyle(color: STBG.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: STBG.textPrimary)),
            ],
          ),
        ),
        if (badge != null) badge!,
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(height: 1, color: STBG.surface, thickness: 1, indent: 18, endIndent: 18);
}

// ─── LIST PAGE ────────────────────────────────────────────────────────────────
class ListPage extends StatefulWidget {
  final String token;
  const ListPage({required this.token});
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List allParts = [];
  List filteredList = [];
  List _activities = [];
  List<SafetyStockResult> _orderAlerts = [];
  bool _bannerDismissed = false;
  bool loading = true;

  @override
  void initState() { super.initState(); loadParts(); }

  Future<void> loadParts() async {
    final data = await fetchParts(widget.token);
    // Charger les activités pour le calcul de stock de sécurité
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.url('/api/activities')),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (res.statusCode == 200) _activities = jsonDecode(res.body);
    } catch (_) {}

    final alerts = SafetyStockService.getOrderAlerts(
      parts: data,
      activities: _activities,
    );

    setState(() {
      allParts = data;
      filteredList = data;
      _orderAlerts = alerts;
      _bannerDismissed = false;
      loading = false;
    });
  }

  Future<void> _deletePart(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const TranslatedText('Delete Part'),
        content: const TranslatedText('Are you sure you want to delete this part?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const TranslatedText('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: STBG.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const TranslatedText('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // await http.delete(Uri.parse("http://10.0.2.2:3000/api/parts/$id"), 
    await http.delete(Uri.parse(ApiConfig.url('/api/parts/$id')),
        headers: {"Authorization": "Bearer ${widget.token}"});
    setState(() {
      allParts.removeWhere((p) => p["id"] == id);
      filteredList.removeWhere((p) => p["id"] == id);
    });
  }

  void _showAddDialog() {
    final refCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final List<File?> images = [null, null, null];
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const TranslatedText('Add New Part'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: langNotifier,
                  builder: (_, lang, __) => Column(
                    children: [
                      _DialogField(ctrl: refCtrl, label: lang == 'fr' ? 'Référence' : lang == 'ar' ? 'المرجع' : 'Reference', icon: Icons.tag_rounded),
                      const SizedBox(height: 10),
                      _DialogField(ctrl: locCtrl, label: lang == 'fr' ? 'Emplacement' : lang == 'ar' ? 'الموقع' : 'Location', icon: Icons.location_on_outlined),
                      const SizedBox(height: 10),
                      _DialogField(ctrl: qtyCtrl, label: lang == 'fr' ? 'Quantité' : lang == 'ar' ? 'الكمية' : 'Quantity', icon: Icons.numbers_rounded, numeric: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(3, (i) => Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final p = await picker.pickImage(source: ImageSource.gallery);
                        if (p != null) setD(() => images[i] = File(p.path));
                      },
                      child: Container(
                        height: 72,
                        margin: EdgeInsets.only(left: i > 0 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: STBG.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: STBG.steel.withOpacity(0.25)),
                          image: images[i] != null
                              ? DecorationImage(image: FileImage(images[i]!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: images[i] == null
                            ? const Icon(Icons.add_a_photo_outlined, color: STBG.steel, size: 24)
                            : null,
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const TranslatedText('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: STBG.navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                final uri = Uri.parse(ApiConfig.url('/api/parts'));
                final req = http.MultipartRequest("POST", uri)
                  ..headers["Authorization"] = "Bearer ${widget.token}"
                  ..fields["reference"] = refCtrl.text
                  ..fields["location"] = locCtrl.text
                  ..fields["quantity"] = qtyCtrl.text;
                for (int i = 0; i < 3; i++) {
                  if (images[i] != null) {
                    req.files.add(await http.MultipartFile.fromPath("image${i+1}", images[i]!.path));
                    try {
                      final emb = await _imageClassifier.getEmbedding(images[i]!);
                      req.fields["embedding${i+1}"] = jsonEncode(emb);
                    } catch (e) {
                      print("Embedding calculation error: $e");
                    }
                  }
                }
                await req.send();
                Navigator.pop(context);
                loadParts();
              },
              child: const TranslatedText('Add Part'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map item) {
    final refCtrl = TextEditingController(text: item['reference'] ?? '');
    final locCtrl = TextEditingController(text: item['location'] ?? '');
    final qtyCtrl = TextEditingController(text: item['quantity'].toString());
    final List<XFile?> newImages = [null, null, null];
    final picker = ImagePicker();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const TranslatedText('Edit Part'),
          content: SingleChildScrollView(
            child: ValueListenableBuilder<String>(
              valueListenable: langNotifier,
              builder: (_, lang, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogField(ctrl: refCtrl, label: lang == 'fr' ? 'Reference' : lang == 'ar' ? '\u0627\u0644\u0645\u0631\u062c\u0639' : 'Reference', icon: Icons.tag_rounded),
                  const SizedBox(height: 10),
                  _DialogField(ctrl: locCtrl, label: lang == 'fr' ? 'Emplacement' : lang == 'ar' ? '\u0627\u0644\u0645\u0648\u0642\u0639' : 'Location', icon: Icons.location_on_outlined),
                  const SizedBox(height: 10),
                  _DialogField(ctrl: qtyCtrl, label: lang == 'fr' ? 'Quantite' : lang == 'ar' ? '\u0627\u0644\u0643\u0645\u064a\u0629' : 'Quantity', icon: Icons.numbers_rounded, numeric: true),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (i) {
                      final existingUrl = item['image${i + 1}'] as String?;
                      final newFile = newImages[i];
                      return GestureDetector(
                        onTap: () async {
                          final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (f != null) setS(() => newImages[i] = f);
                        },
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: newFile != null ? Colors.green : (existingUrl != null ? STBG.navy : Colors.red),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: newFile != null
                                ? Image.file(File(newFile.path), fit: BoxFit.cover)
                                : existingUrl != null
                                    ? Image.network(ApiConfig.uploadUrl(existingUrl), fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey))
                                    : const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const TranslatedText('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: STBG.navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                final hasNew = newImages.any((f) => f != null);
                if (hasNew) {
                  final req = http.MultipartRequest('PUT', Uri.parse(ApiConfig.url('/api/parts/${item["id"]}')));
                  req.headers['Authorization'] = 'Bearer ${widget.token}';
                  req.fields['reference'] = refCtrl.text;
                  req.fields['location'] = locCtrl.text;
                  req.fields['quantity'] = (int.tryParse(qtyCtrl.text) ?? 0).toString();
                  for (int i = 0; i < 3; i++) {
                    if (newImages[i] != null) {
                      req.files.add(await http.MultipartFile.fromPath('image${i + 1}', newImages[i]!.path));
                      try {
                        final emb = await _imageClassifier.getEmbedding(File(newImages[i]!.path));
                        req.fields['embedding\${i + 1}'] = jsonEncode(emb);
                      } catch (_) {}
                    }
                  }
                  final streamed = await req.send();
                  if (streamed.statusCode == 200) { Navigator.pop(context); loadParts(); }
                } else {
                  final res = await http.put(
                    Uri.parse(ApiConfig.url('/api/parts/${item["id"]}')),
                    headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
                    body: jsonEncode({'reference': refCtrl.text, 'location': locCtrl.text, 'quantity': int.tryParse(qtyCtrl.text) ?? 0}),
                  );
                  if (res.statusCode == 200) { Navigator.pop(context); loadParts(); }
                }
              },
              child: const TranslatedText('Save'),
            ),
          ],
        ),
      ),
    );
  }
  void _showTakeDialog(Map item) {
    final qtyCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final int available = item["quantity"] ?? 0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const TranslatedText('Withdraw Parts'),
        content: ValueListenableBuilder<String>(
          valueListenable: langNotifier,
          builder: (_, lang, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(ctrl: nameCtrl, label: lang == 'fr' ? 'Nom de la personne' : lang == 'ar' ? 'اسم الشخص' : 'Taken by', icon: Icons.person_outline),
              const SizedBox(height: 10),
              _DialogField(
                ctrl: qtyCtrl,
                label: lang == 'fr' ? 'Quantité' : lang == 'ar' ? 'الكمية' : 'Quantity',
                icon: Icons.remove_circle_outline,
                numeric: true,
                helper: lang == 'fr' ? 'Disponible: $available' : lang == 'ar' ? 'المتاح: $available' : 'Available: $available',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const TranslatedText('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: STBG.navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final take = int.tryParse(qtyCtrl.text) ?? 0;
              if (take <= 0 || take > available || nameCtrl.text.trim().isEmpty) return;
              final newQty = available - take;
              final res = await http.put(
                // Uri.parse("http://10.0.2.2:3000/api/parts/${item["id"]}"), 
                Uri.parse(ApiConfig.url('/api/parts/${item["id"]}')),
                headers: {"Authorization": "Bearer ${widget.token}", "Content-Type": "application/json"},
                body: jsonEncode({"reference": item["reference"], "location": item["location"], "quantity": newQty}),
              );
              if (res.statusCode == 200) {
                final now = formatLocalDateTimeForApi(DateTime.now());
                await http.post(
                  // Uri.parse("http://10.0.2.2:3000/api/activities"), 
                  Uri.parse(ApiConfig.url('/api/activities')),
                  headers: {"Authorization": "Bearer ${widget.token}", "Content-Type": "application/json"},
                  body: jsonEncode({"part_id": item["id"], "reference": item["reference"], "taken_by": nameCtrl.text.trim(), "quantity": take, "date": now}),
                );
                setState(() { _history.insert(0, {"reference": item["reference"], "takenBy": nameCtrl.text.trim(), "quantity": take, "date": now}); });
                _saveHistory();
                Navigator.pop(context);
                loadParts();
              }
            },
            child: const TranslatedText('Confirm'),
          ),
        ],
      ),
    );
  }

  // Export sheet (unchanged logic, redesigned UI)
  void _showExportSheet(BuildContext context) {
    DateTime? from;
    DateTime? to;
    bool incE = true, incS = true, incSt = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 36 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: STBG.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.download_rounded, color: STBG.success, size: 20)),
                  const SizedBox(width: 12),
                  const Text('Export to Excel', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: STBG.textPrimary)),
                ]),
                const SizedBox(height: 6),
                Text('Generate a report with Entrée, Sortie, and Stock sheets.', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 20),
                const Text('Period', style: TextStyle(fontWeight: FontWeight.w600, color: STBG.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _DatePickerBtn(label: 'From', date: from, onPick: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) setS(() => from = d);
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _DatePickerBtn(label: 'To', date: to, onPick: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) setS(() => to = d);
                  })),
                ]),
                const SizedBox(height: 16),
                const Text('Include in export', style: TextStyle(fontWeight: FontWeight.w600, color: STBG.textSecondary, fontSize: 13)),
                _ExportCheckbox(label: 'Entrées', value: incE, onChanged: (v) => setS(() => incE = v ?? true)),
                _ExportCheckbox(label: 'Sorties', value: incS, onChanged: (v) => setS(() => incS = v ?? true)),
                _ExportCheckbox(label: 'État de stock', value: incSt, onChanged: (v) => setS(() => incSt = v ?? true)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: STBG.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded, color: Colors.white),
                    label: const Text('Download Excel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    onPressed: () async {
                      if (from == null || to == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date range')));
                        return;
                      }
                      if (!incE && !incS && !incSt) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one section')));
                        return;
                      }
                      Navigator.pop(context);
                      await _generateExcel(from!, to!, includeEntree: incE, includeSortie: incS, includeStock: incSt);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _saveExcelBytes(List<int> bytes, String fileName) async {
    final data = Uint8List.fromList(bytes);
    try {
      final picked = await FilePicker.platform.saveFile(dialogTitle: 'Save Excel File', fileName: fileName, type: FileType.custom, allowedExtensions: ['xlsx']);
      if (picked == null) return null;
      final path = picked.toLowerCase().endsWith('.xlsx') ? picked : '$picked.xlsx';
      await File(path).writeAsBytes(data);
      return path;
    } catch (_) {}
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) { final path = '${dir.path}/$fileName'; await File(path).writeAsBytes(data); return path; }
    } catch (_) {}
    final doc = await getApplicationDocumentsDirectory();
    final path = '${doc.path}/$fileName';
    await File(path).writeAsBytes(data);
    return path;
  }

  void _revealFileInFolder(String filePath) {
    if (kIsWeb) return;
    try {
      if (Platform.isWindows) Process.run('explorer', ['/select,', filePath]);
      else if (Platform.isMacOS) Process.run('open', ['-R', filePath]);
      else if (Platform.isLinux) Process.run('xdg-open', [File(filePath).parent.path]);
    } catch (_) {}
  }

  Future<void> _generateExcel(DateTime from, DateTime to, {required bool includeEntree, required bool includeSortie, required bool includeStock}) async {
    String fromStr = formatLocalDateOnly(from);
    String toStr = formatLocalDateOnly(to);
    if (fromStr.compareTo(toStr) > 0) { final t = fromStr; fromStr = toStr; toStr = t; }
    // final res = await http.get(Uri.parse("http://10.0.2.2:3000/api/export?from=$fromStr&to=$toStr"), headers: {"Authorization": "Bearer ${widget.token}"}); 
    final res = await http.get(Uri.parse(ApiConfig.url('/api/export?from=$fromStr&to=$toStr')), headers: {"Authorization": "Bearer ${widget.token}"});
    if (res.statusCode != 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: ${res.statusCode}")));
      return;
    }
    try {
      final data = jsonDecode(res.body);
      final List entrees = data["entrees"] ?? [];
      List<Map<String, dynamic>> sorties = [];
      for (final e in (data["sorties"] ?? []) as List) { if (e is Map) sorties.add(Map<String, dynamic>.from(e)); }
      final List stock = data["stock"] ?? [];
      if (includeSortie) {
        final keys = <String>{};
        for (final s in sorties) keys.add('${s["reference"]}|${s["taken_by"]}|${s["quantity"]}|${s["date"]}');
        for (final h in _history) {
          final raw = h["date"]?.toString() ?? '';
          if (raw.length < 10) continue;
          final day = raw.substring(0, 10);
          if (day.compareTo(fromStr) < 0 || day.compareTo(toStr) > 0) continue;
          final row = <String, dynamic>{"reference": h["reference"], "taken_by": h["takenBy"], "quantity": h["quantity"], "date": h["date"]};
          final k = '${row["reference"]}|${row["taken_by"]}|${row["quantity"]}|${row["date"]}';
          if (!keys.contains(k)) { keys.add(k); sorties.add(row); }
        }
        sorties.sort((a, b) => (a["date"]?.toString() ?? "").compareTo(b["date"]?.toString() ?? ""));
      }
      final excel = xl.Excel.createExcel();
      final shE = excel['Entrée']; final shS = excel['Sortie']; final shSt = excel['État de stock'];
      excel.delete('Sheet1');
      final titleStyle = xl.CellStyle(bold: true, fontSize: 13, backgroundColorHex: xl.ExcelColor.fromHexString("#0A1628"), fontColorHex: xl.ExcelColor.fromHexString("#FFFFFF"));
      final headerStyle = xl.CellStyle(bold: true, backgroundColorHex: xl.ExcelColor.fromHexString("#BBDEFB"), fontColorHex: xl.ExcelColor.fromHexString("#0D47A1"));

      void fill(xl.Sheet sh, bool inc, void Function(void Function(String) wT, void Function(List<String>) wH, void Function(List) wR) build) {
        int row = 0;
        void wT(String t) { final c = sh.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)); c.value = xl.TextCellValue(t); c.cellStyle = titleStyle; row++; }
        void wH(List<String> hs) { for (int i = 0; i < hs.length; i++) { final c = sh.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row)); c.value = xl.TextCellValue(hs[i]); c.cellStyle = headerStyle; } row++; }
        void wR(List vs) { for (int i = 0; i < vs.length; i++) { final v = vs[i]; sh.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row)).value = v is int ? xl.IntCellValue(v) : xl.TextCellValue(v?.toString() ?? ""); } row++; }
        if (!inc) { wT('—'); wR(['Section not included in this export.', '', '', '']); return; }
        build(wT, wH, wR);
      }

      fill(shE, includeEntree, (wT, wH, wR) {
        wT('ENTRÉE  ($fromStr → $toStr)'); wH(['Référence', 'Emplacement', 'Quantité ajoutée', 'Date']);
        if (entrees.isEmpty) wR(['Aucune entrée dans cette période', '', '', '']);
        else for (final e in entrees) wR([e['reference'], e['location'], e['quantity'], e['created_at']]);
      });
      fill(shS, includeSortie, (wT, wH, wR) {
        wT('SORTIE  ($fromStr → $toStr)'); wH(['Référence', 'Pris par', 'Quantité prise', 'Date']);
        if (sorties.isEmpty) wR(['Aucune sortie dans cette période', '', '', '']);
        else for (final s in sorties) wR([s['reference'], s['taken_by'], s['quantity'], s['date']]);
      });
      fill(shSt, includeStock, (wT, wH, wR) {
        wT('ÉTAT DE STOCK au $toStr'); wH(['Référence', 'Emplacement', 'Quantité actuelle']);
        if (stock.isEmpty) wR(['Aucune pièce', '', '']);
        else for (final s in stock) wR([s['reference'], s['location'], s['quantity']]);
      });

      final encoded = excel.encode();
      if (encoded == null) throw Exception('Excel encoding failed');
      final fileName = 'rapport_${fromStr}_${toStr}.xlsx';
      final savedPath = await _saveExcelBytes(encoded, fileName);
      if (!mounted || savedPath == null) return;
      final desktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(desktop ? 'File saved successfully.' : '✅ $savedPath'),
        backgroundColor: STBG.success,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: desktop ? SnackBarAction(label: 'Show in folder', textColor: Colors.white, onPressed: () => _revealFileInFolder(savedPath)) : null,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: STBG.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: STBG.surface,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'export',
            onPressed: () => _showExportSheet(context),
            backgroundColor: STBG.success,
            child: const Icon(Icons.download_rounded, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'history',
            onPressed: () => Navigator.push(context, createRoute(HistoryPage(history: _history))),
            backgroundColor: STBG.gold,
            child: const Icon(Icons.history_rounded, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _showAddDialog,
            backgroundColor: STBG.navy,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: STBG.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Color(0x35000000), blurRadius: 20, offset: Offset(0, 6))],
            ),
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const TranslatedText('Spare Parts', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TranslatedText('Inventory management', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: ValueListenableBuilder<String>(
                    valueListenable: langNotifier,
                    builder: (_, lang, __) => TextField(
                      decoration: InputDecoration(
                        hintText: lang == 'fr' ? 'Rechercher une pièce...' : lang == 'ar' ? 'بحث...' : 'Search parts...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (v) => setState(() => filteredList = allParts.where((item) => (item["reference"] ?? "").toLowerCase().contains(v.toLowerCase())).toList()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: STBG.steel))
                : Column(
                    children: [
                      // Bannière alertes stock de sécurité
                      if (_orderAlerts.isNotEmpty && !_bannerDismissed)
                        OrderAlertBanner(
                          alerts: _orderAlerts,
                          onDismiss: () => setState(() => _bannerDismissed = true),
                        ),
                      Expanded(
                        child: filteredList.isEmpty
                            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                const TranslatedText('No parts found', style: TextStyle(color: STBG.textSecondary, fontSize: 15)),
                              ]))
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                                itemCount: filteredList.length,
                                itemBuilder: (ctx, i) {
                                  final item = filteredList[i];
                                  final int qty = item["quantity"] ?? 0;
                                  final bool low = qty <= 5;
                                  // Vérifier si cette pièce a une alerte stock de sécurité
                                  final SafetyStockResult? alert = _orderAlerts
                                      .where((a) => a.reference.toLowerCase() == (item["reference"] ?? '').toString().toLowerCase())
                                      .firstOrNull;
                                  return Dismissible(
                                    key: Key(item["id"].toString()),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(color: STBG.danger, borderRadius: BorderRadius.circular(16)),
                                      child: const Icon(Icons.delete_rounded, color: Colors.white),
                                    ),
                                    onDismissed: (_) => _deletePart(item["id"]),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: alert != null
                                            ? Border.all(color: const Color(0xFFE8A400).withValues(alpha: 0.5), width: 1.5)
                                            : low
                                                ? Border.all(color: STBG.danger.withValues(alpha: 0.25))
                                                : null,
                                        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
                                      ),
                                      child: Column(
                                        children: [
                                          // No-photo banner
                                          if (item['image1'] == null && item['image2'] == null && item['image3'] == null)
                                            GestureDetector(
                                              onTap: () => _showEditDialog(item),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                                decoration: BoxDecoration(
                                                  color: STBG.danger.withValues(alpha: 0.08),
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                  border: Border(bottom: BorderSide(color: STBG.danger.withValues(alpha: 0.15))),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.image_not_supported_outlined, size: 13, color: STBG.danger),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        'Aucune photo — Appuyez pour ajouter',
                                                        style: TextStyle(fontSize: 11, color: STBG.danger, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                    Icon(Icons.add_photo_alternate_outlined, size: 14, color: STBG.danger),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(colors: [STBG.navy, STBG.steel]),
                                                  borderRadius: BorderRadius.circular(11),
                                                ),
                                                child: const Icon(Icons.settings_outlined, color: Colors.white, size: 19),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(item["reference"] ?? "-", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: STBG.textPrimary)),
                                                    const SizedBox(height: 3),
                                                    Text(item["location"] ?? "-", style: const TextStyle(color: STBG.textSecondary, fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              // Badge stock de sécurité ou stock bas
                                              if (alert != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE8A400).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: const Color(0xFFE8A400).withOpacity(0.4)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.shopping_cart_outlined, size: 11, color: Color(0xFFE8A400)),
                                                      const SizedBox(width: 4),
                                                      Text('$qty / SS:${alert.safetyStock}',
                                                          style: const TextStyle(color: Color(0xFFE8A400), fontWeight: FontWeight.w700, fontSize: 11)),
                                                    ],
                                                  ),
                                                )
                                              else
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: low ? STBG.danger.withOpacity(0.1) : STBG.success.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    '$qty',
                                                    style: TextStyle(color: low ? STBG.danger : STBG.success, fontWeight: FontWeight.w700, fontSize: 13),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              _IconBtn(icon: Icons.remove_circle_outline_rounded, color: Colors.orange, onTap: () => _showTakeDialog(item)),
                                              _IconBtn(icon: Icons.visibility_outlined, color: STBG.steel, onTap: () => Navigator.push(ctx, createRoute(ResultPage(data: item, token: widget.token)))),
                                              _IconBtn(icon: Icons.edit_outlined, color: STBG.success, onTap: () => _showEditDialog(item)),
                                              _IconBtn(icon: Icons.delete_outline_rounded, color: STBG.danger, onTap: () => _deletePart(item["id"])),
                                            ],
                                          ),
                                        ],
                                      ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, color: color, size: 20)),
  );
}

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool numeric;
  final String? helper;
  const _DialogField({required this.ctrl, required this.label, required this.icon, this.numeric = false, this.helper});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Icon(icon, size: 18, color: STBG.steel),
      filled: true,
      fillColor: STBG.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: STBG.steel, width: 1.5)),
    ),
  );
}

class _DatePickerBtn extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;
  const _DatePickerBtn({required this.label, required this.date, required this.onPick});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPick,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: date != null ? STBG.steel : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
        color: date != null ? STBG.steel.withOpacity(0.05) : Colors.white,
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 15, color: STBG.steel),
          const SizedBox(width: 7),
          Text(
            date == null ? label : '${date!.day}/${date!.month}/${date!.year}',
            style: TextStyle(fontSize: 13, color: date == null ? Colors.grey : STBG.textPrimary, fontWeight: date != null ? FontWeight.w600 : FontWeight.normal),
          ),
        ],
      ),
    ),
  );
}

class _ExportCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _ExportCheckbox({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    value: value,
    onChanged: onChanged,
    title: Text(label, style: const TextStyle(fontSize: 14, color: STBG.textPrimary)),
    controlAffinity: ListTileControlAffinity.leading,
    activeColor: STBG.steel,
  );
}

// ─── HISTORY PAGE ─────────────────────────────────────────────────────────────
class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const HistoryPage({required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: STBG.surface,
      body: Column(
        children: [
          _STBGHeader(title: 'Activity History', subtitle: 'Parts withdrawal log', showBack: true),
          Expanded(
            child: history.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.history_rounded, size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const TranslatedText('No activity recorded yet', style: TextStyle(color: STBG.textSecondary, fontSize: 15)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (_, i) {
                      final h = history[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [STBG.gold.withOpacity(0.8), STBG.gold]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(h["reference"] ?? "-", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: STBG.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text(h["takenBy"] ?? "-", style: const TextStyle(color: STBG.textSecondary, fontSize: 12)),
                                  Text(h["date"] ?? "-", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: STBG.danger.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: STBG.danger.withOpacity(0.2)),
                              ),
                              child: Text("-${h["quantity"]}", style: const TextStyle(color: STBG.danger, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── API Functions ────────────────────────────────────────────────────────────
Future<List> fetchParts(String token) async {
  // final res = await http.get(Uri.parse("http://10.0.2.2:3000/api/parts"), headers: {"Authorization": "Bearer $token"}); 
  final res = await http.get(Uri.parse(ApiConfig.url('/api/parts')), headers: {"Authorization": "Bearer $token"});
  if (res.statusCode == 200) return json.decode(res.body);
  throw Exception("Failed to load parts");
}

Future<Map<String, dynamic>> login(String email, String password) async {
  final res = await http.post(
    // Uri.parse("http://10.0.2.2:3000/api/login"), 
    Uri.parse(ApiConfig.url('/api/login')),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email, "password": password}),
  );
  return jsonDecode(res.body);
}