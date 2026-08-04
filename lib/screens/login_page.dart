import 'package:flutter/material.dart';
import 'package:gestion_piece_de_rechange/services/api_service.dart';
import 'package:gestion_piece_de_rechange/screens/home_page.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';
import 'package:gestion_piece_de_rechange/widgets/shared_widgets.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: STBG.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                      child: stbgLogo(height: 60),
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
                          if (res['success'] == true) {
                            Navigator.pushReplacement(
                              context,
                              createRoute(HomePage(role: res['role'], token: res['token'])),
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
                          builder: (_, lang, __) => _LangChip(lang: lang, onTap: toggleLanguage),
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
