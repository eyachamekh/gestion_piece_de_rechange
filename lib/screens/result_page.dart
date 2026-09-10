import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gestion_piece_de_rechange/config/api_config.dart';
import 'package:gestion_piece_de_rechange/models/safety_stock_result.dart';
import 'package:gestion_piece_de_rechange/services/safety_stock_service.dart';
import 'package:gestion_piece_de_rechange/services/auth_headers.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';
import 'package:gestion_piece_de_rechange/widgets/shared_widgets.dart';
import 'package:gestion_piece_de_rechange/widgets/custom_bottom_navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class _GalleryScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class ResultPage extends StatefulWidget {
  final Map data;
  final String? token;

  const ResultPage({required this.data, this.token, super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  SafetyStockResult? _ssResult;
  late final PageController _imageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
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
          headers: makeAuthHeaders(widget.token ?? ''),
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

  /// Build and launch an email to request replenishment for this part.
  Future<void> _sendOrderEmail() async {
    if (_ssResult == null) return;
    final ref = (widget.data['reference'] ?? '').toString();
    final loc = (widget.data['location'] ?? '').toString();
    final qty = (widget.data['quantity'] ?? 0).toString();
    final ss = _ssResult!.safetyStock.toString();

    final lang = langNotifier.value;

    late String subject;
    late String body;

    if (lang == 'fr') {
      subject = 'STBG — Demande de réapprovisionnement : $ref';
      body =
          '''Madame, Monsieur,

Nous vous informons que le stock de la pièce de rechange suivante a atteint son niveau de sécurité au sein de la société STBG.

Détails de la pièce :
Référence : $ref
Emplacement : $loc
Quantité disponible : $qty
Stock de sécurité : $ss
Quantité demandée : 

Afin d'éviter toute rupture de stock et d'assurer la continuité de nos opérations, nous vous remercions de bien vouloir nous transmettre votre disponibilité ainsi qu'un devis, ou de procéder au réapprovisionnement dans les meilleurs délais, conformément à nos accords.

Nous restons à votre disposition pour toute information complémentaire.

Cordialement,
Service Magasin / Maintenance
Société STBG
E-mail : stbg@stbg.com.tn

Téléphone : 71 434 880
''';
    } else if (lang == 'ar') {
      subject = 'STBG — طلب إعادة تزويد : $ref';
      body =
          '''السيد/السيدة،

نحيطكم علماً أن مخزون قطعة الغيار التالية قد وصل إلى مستوى الأمان لدى شركة STBG.

تفاصيل القطعة:
المرجع : $ref
الموقع : $loc
الكمية المتاحة : $qty
مخزون الأمان : $ss
الكمية المطلوبة : 

ولتفادي نقص المخزون وضمان استمرارية عملياتنا، نرجو تزويدنا بتوفركم وعرض أسعار، أو القيام بإعادة التزويد في أقرب وقت ممكن، وفقاً لاتفاقياتنا.

نحن في خدمتكم لأي معلومات إضافية.

مع التحية،
قسم المخزن / الصيانة
شركة STBG
البريد الإلكتروني: stbg@stbg.com.tn

الهاتف: 71 434 880
''';
    } else {
      // Default to English
      subject = 'STBG — Replenishment request: $ref';
      body =
          '''Dear Sir / Madam,

We inform you that the stock of the following spare part has reached its safety level within STBG.

Part details:
Reference: $ref
Location: $loc
Available quantity: $qty
Safety stock: $ss
Requested quantity: 

To avoid stock outs and ensure continuity of our operations, please provide your availability and a quotation, or proceed with replenishment as soon as possible according to our agreements.

We remain at your disposal for any further information.

Sincerely,
Store / Maintenance Department
STBG Company
E-mail: stbg@stbg.com.tn

Tel: 71 434 880
''';
    }

    // Encode subject and body using percent-encoding so spaces become %20 (not '+')
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final uriStr = 'mailto:?subject=$encodedSubject&body=$encodedBody';
    final uri = Uri.parse(uriStr);

    try {
      if (!await launchUrl(uri)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open mail app')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _openImage(String url, String tag) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          child: Center(
            child: Hero(
              tag: tag,
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int qty = widget.data['quantity'] ?? 0;
    final bool lowStock = qty <= 5;
    final bool mustOrder = _ssResult?.mustOrder ?? lowStock;
    final bool isOrderAlert = _ssResult != null && _ssResult!.mustOrder;
    final imageValues = List.generate(7, (index) => 'image${index + 1}')
        .map((key) => widget.data[key])
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString())
        .toList();
    final galleryHeight = MediaQuery.sizeOf(context).width < 600
        ? 320.0
        : 350.0;

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
      body: Stack(
        children: [
          Column(
            children: [
          STBGHeader(
            title: 'Part Details',
            subtitle: 'Identified spare part information',
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  if (widget.data['matchSource'] != null ||
                      widget.data['confidence'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.insights_outlined),
                          title: Text(
                            widget.data['matchSource'] == 'visual'
                                ? 'Visual gallery match'
                                : 'OCR and visual evidence',
                          ),
                          subtitle: Text(
                            widget.data['confidence'] is num
                                ? 'Similarity: '
                                      '${((widget.data['confidence'] as num).toDouble() * 100).toStringAsFixed(1)}%'
                                : (widget.data['ocrText'] ??
                                          'Reference evidence used')
                                      .toString(),
                          ),
                        ),
                      ),
                    ),
                  if (widget.data['matchSource'] != null ||
                      widget.data['confidence'] != null)
                    const SizedBox(height: 8),
                  if (imageValues.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _ActionBtn(
                                icon: Icons.remove_circle_outline_rounded,
                                label: 'Take',
                                color: Colors.orange,
                                onTap: _showTakeDialog,
                              ),
                              const SizedBox(width: 8),
                              _ActionBtn(
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                                color: STBG.success,
                                onTap: _showEditDialog,
                              ),
                              const SizedBox(width: 8),
                              _ActionBtn(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                color: STBG.danger,
                                onTap: _deletePart,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: galleryHeight,
                            child: ScrollConfiguration(
                              behavior: _GalleryScrollBehavior(),
                              child: PageView.builder(
                                controller: _imageController,
                                physics: const PageScrollPhysics(),
                                itemCount: imageValues.length,
                                onPageChanged: (index) =>
                                    setState(() => _currentImageIndex = index),
                                itemBuilder: (context, index) {
                                  final url = ApiConfig.uploadUrl(imageValues[index]);
                                  final tag = 'part-${widget.data['id']}-img-$index';
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.grey[200],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: GestureDetector(
                                        onTap: () => _openImage(url, tag),
                                        child: Hero(
                                          tag: tag,
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stack) =>
                                                const Icon(Icons.broken_image, color: Colors.grey, size: 42),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (imageValues.length > 1) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                '${_currentImageIndex + 1} / ${imageValues.length}',
                                style: const TextStyle(
                                  color: STBG.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                imageValues.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: _currentImageIndex == index ? 18 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index ? STBG.navy : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOrderAlert && _ssResult != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: STBG.gold.withOpacity(0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 14,
                                      color: STBG.gold,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Analyse stock de sécurité',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Color(0xFF7A4F00),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    SSMetric(
                                      label: 'Stock actuel',
                                      value: '${_ssResult!.currentQty}',
                                      color: STBG.danger,
                                    ),
                                    const SizedBox(width: 8),
                                    SSMetric(
                                      label: 'Stock sécurité',
                                      value: '${_ssResult!.safetyStock}',
                                      color: STBG.steel,
                                    ),
                                    const SizedBox(width: 8),
                                    SSMetric(
                                      label: 'Délai DA',
                                      value:
                                          '${_ssResult!.delaiJours.toStringAsFixed(0)} j',
                                      color: STBG.success,
                                    ),
                                    const SizedBox(width: 8),
                                    SSMetric(
                                      label: 'Conso/jour',
                                      value: _ssResult!.consommationJour
                                          .toStringAsFixed(2),
                                      color: const Color(0xFF7B1FA2),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: STBG.gold.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '⚠️  Quantité actuelle ≤ stock de sécurité\nUne demande d\'achat (DA) doit être passée immédiatement.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF7A4F00),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              InfoRow(
                                icon: Icons.tag_rounded,
                                label: 'Reference',
                                value: widget.data['reference'] ?? '-',
                              ),
                              const SectionDivider(),
                              InfoRow(
                                icon: Icons.location_on_outlined,
                                label: 'Location',
                                value: widget.data['location'] ?? '-',
                              ),
                              const SectionDivider(),
                              InfoRow(
                                icon: Icons.inventory_2_outlined,
                                label: 'Quantity',
                                value: qty.toString(),
                                badge: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (ctx) {
                                      final lang = langNotifier.value;
                                      final String badgeLabel;
                                      if (isOrderAlert) {
                                        badgeLabel = lang == 'fr'
                                            ? 'À commander'
                                            : (lang == 'ar' ? 'طلب' : 'Order');
                                      } else {
                                        badgeLabel = lang == 'fr'
                                            ? (mustOrder
                                                  ? 'Stock faible'
                                                  : 'En stock')
                                            : (lang == 'ar'
                                                  ? (mustOrder
                                                        ? 'مخزون منخفض'
                                                        : 'متوفر')
                                                  : (mustOrder
                                                        ? 'Low Stock'
                                                        : 'In Stock'));
                                      }

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: isOrderAlert
                                            ? _sendOrderEmail
                                            : null,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0,
                                            vertical: 2.0,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                statusIcon,
                                                size: 11,
                                                color: statusColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                badgeLabel,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigationBar(
              currentIndex: 0,
              token: widget.token,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final referenceCtrl = TextEditingController(
      text: widget.data['reference']?.toString() ?? '',
    );
    final locationCtrl = TextEditingController(
      text: widget.data['location']?.toString() ?? '',
    );
    final quantityCtrl = TextEditingController(
      text: widget.data['quantity']?.toString() ?? '0',
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const TranslatedText('Edit Part'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogField(
              ctrl: referenceCtrl,
              label: t('Reference'),
              icon: Icons.tag_rounded,
            ),
            const SizedBox(height: 10),
            DialogField(
              ctrl: locationCtrl,
              label: t('Location'),
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 10),
            DialogField(
              ctrl: quantityCtrl,
              label: t('Quantity'),
              icon: Icons.numbers_rounded,
              numeric: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const TranslatedText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await http.put(
                Uri.parse(ApiConfig.url('/api/parts/${widget.data['id']}')),
                headers: makeAuthHeaders(widget.token ?? '', json: true),
                body: jsonEncode({
                  'reference': referenceCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'quantity': int.tryParse(quantityCtrl.text) ?? 0,
                }),
              );
              if (!mounted) return;
              if (response.statusCode == 200) {
                setState(() {
                  widget.data['reference'] = referenceCtrl.text.trim();
                  widget.data['location'] = locationCtrl.text.trim();
                  widget.data['quantity'] =
                      int.tryParse(quantityCtrl.text) ?? 0;
                });
                Navigator.pop(dialogContext);
              }
            },
            child: const TranslatedText('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const TranslatedText('Delete Part'),
        content: const TranslatedText(
          'Are you sure you want to delete this part?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const TranslatedText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const TranslatedText('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final response = await http.delete(
      Uri.parse(ApiConfig.url('/api/parts/${widget.data['id']}')),
      headers: makeAuthHeaders(widget.token ?? ''),
    );
    if (!mounted) return;
    if (response.statusCode == 200) Navigator.pop(context);
  }

  void _showTakeDialog() {
    final qtyCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final int available = widget.data['quantity'] ?? 0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const TranslatedText('Withdraw Parts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogField(
              ctrl: nameCtrl,
              label: t('Person name'),
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 10),
            DialogField(
              ctrl: qtyCtrl,
              label: t('Quantity'),
              icon: Icons.remove_circle_outline,
              numeric: true,
              helper: '${t('Available')}: $available',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: STBG.navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final take = int.tryParse(qtyCtrl.text) ?? 0;
              if (take <= 0 || take > available || nameCtrl.text.trim().isEmpty)
                return;
              final newQty = available - take;
              if (widget.token == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not authenticated')),
                );
                return;
              }
              final res = await http.put(
                Uri.parse(ApiConfig.url('/api/parts/${widget.data['id']}')),
                headers: makeAuthHeaders(widget.token!, json: true),
                body: jsonEncode({
                  'reference': widget.data['reference'],
                  'location': widget.data['location'],
                  'quantity': newQty,
                }),
              );
              if (res.statusCode == 200) {
                final now = formatLocalDateTimeForApi(DateTime.now());
                await http.post(
                  Uri.parse(ApiConfig.url('/api/activities')),
                  headers: makeAuthHeaders(widget.token!, json: true),
                  body: jsonEncode({
                    'part_id': widget.data['id'],
                    'reference': widget.data['reference'],
                    'taken_by': nameCtrl.text.trim(),
                    'quantity': take,
                    'date': now,
                  }),
                );
                addToHistory({
                  'reference': widget.data['reference'],
                  'takenBy': nameCtrl.text.trim(),
                  'quantity': take,
                  'date': now,
                });
                saveHistory();
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t('Quantity updated'))));
                setState(() {
                  widget.data['quantity'] = newQty;
                });
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: ${res.statusCode}')),
                );
              }
            },
            child: const TranslatedText('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
