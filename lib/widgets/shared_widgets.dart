import 'package:flutter/material.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';
import 'package:gestion_piece_de_rechange/services/mlkit_translation_service.dart';

Widget stbgLogo({double height = 52}) => Image.asset(
  'assets/images/logo-stbg.jpg',
  height: height,
  fit: BoxFit.contain,
);

class STBGHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showBack;
  final List<Widget> actions;
  final Widget? bottom;
  final double extraPad;

  const STBGHeader({
    this.title,
    this.subtitle,
    this.showBack = false,
    this.actions = const [],
    this.bottom,
    this.extraPad = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: STBG.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(22, 44 + extraPad, 22, 18),
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
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              if (showBack) const SizedBox(width: 12),
              Expanded(child: Container()),
              ...actions,
              const SizedBox(width: 8),
              GestureDetector(
                onTap: toggleLanguage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      ValueListenableBuilder<String>(
                        valueListenable: langNotifier,
                        builder: (_, lang, __) => Text(
                          lang.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (title != null) ...[
            const SizedBox(height: 14),
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
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        TranslatedText(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
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

class HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Widget? label;
  const HeaderIconBtn({required this.icon, required this.onTap, this.label, super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          if (label != null) ...[
            const SizedBox(width: 4),
            label!,
          ],
        ],
      ),
    ),
  );
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight
            ? STBG.gold.withOpacity(0.18)
            : Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(color: STBG.gold.withOpacity(0.5))
            : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: highlight ? STBG.gold : Colors.white, size: 19),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: highlight ? STBG.gold : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          TranslatedText(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    super.key,
  });

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
          boxShadow: const [
            BoxShadow(
              color: Color(0x0E000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
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
                  TranslatedText(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: STBG.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  TranslatedText(
                    subtitle,
                    style: const TextStyle(
                      color: STBG.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: accent,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ScanOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ScanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

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
                gradient: const LinearGradient(
                  colors: [STBG.steel, STBG.accent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: STBG.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  TranslatedText(
                    subtitle,
                    style: const TextStyle(
                      color: STBG.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: STBG.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

class SSMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const SSMetric({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF7A4F00)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? badge;

  const InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: STBG.steel.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: STBG.steel, size: 17),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                label,
                style: const TextStyle(color: STBG.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: STBG.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (badge != null) badge!,
      ],
    ),
  );
}

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    color: STBG.surface,
    thickness: 1,
    indent: 18,
    endIndent: 18,
  );
}

class IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(7),
      child: Icon(icon, color: color, size: 20),
    ),
  );
}

class DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool numeric;
  final String? helper;

  const DialogField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.numeric = false,
    this.helper,
    super.key,
  });

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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: STBG.steel, width: 1.5),
      ),
    ),
  );
}

class DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;

  const DatePickerButton({
    required this.label,
    required this.date,
    required this.onPick,
    super.key,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPick,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: date != null ? STBG.steel : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(10),
        color: date != null ? STBG.steel.withOpacity(0.05) : Colors.white,
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 15, color: STBG.steel),
          const SizedBox(width: 7),
          Text(
            date == null ? label : '${date!.day}/${date!.month}/${date!.year}',
            style: TextStyle(
              fontSize: 13,
              color: date == null ? Colors.grey : STBG.textPrimary,
              fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}

class ExportCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const ExportCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    value: value,
    onChanged: onChanged,
    title: Text(
      label,
      style: const TextStyle(fontSize: 14, color: STBG.textPrimary),
    ),
    controlAffinity: ListTileControlAffinity.leading,
    activeColor: STBG.steel,
  );
}
